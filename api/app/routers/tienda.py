"""Módulo de venta: catálogo de productos, carrito de compras y pago en línea.

El pago es una SIMULACIÓN de pasarela (no se cobra nada real): se validan
los datos de la tarjeta (algoritmo de Luhn, fecha y CVV) y se registra el
pedido. Solo se guardan la marca y los últimos 4 dígitos.
"""

import uuid
from datetime import datetime
from decimal import Decimal

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import delete, select
from sqlalchemy.orm import Session, joinedload

from ..database import obtener_sesion
from ..deps import usuario_actual
from ..models import CarritoItem, Pedido, PedidoDetalle, Producto, Usuario
from ..schemas import (
    CarritoCantidad,
    CarritoItemRespuesta,
    CarritoRespuesta,
    PagoRequest,
    PedidoRespuesta,
    ProductoRespuesta,
)

router = APIRouter(tags=["Tienda"])

# Tarjeta de prueba que la pasarela simulada siempre rechaza (para la demo).
TARJETA_RECHAZADA = "4000000000000002"


# ----------------------------------------------------------------------
# Catálogo
# ----------------------------------------------------------------------
@router.get("/productos", response_model=list[ProductoRespuesta])
def catalogo(_: Usuario = Depends(usuario_actual), db: Session = Depends(obtener_sesion)):
    return db.scalars(
        select(Producto).where(Producto.activo.is_(True)).order_by(Producto.categoria, Producto.nombre)
    ).all()


# ----------------------------------------------------------------------
# Carrito
# ----------------------------------------------------------------------
def _carrito(db: Session, usr_id: int) -> CarritoRespuesta:
    items = db.scalars(
        select(CarritoItem)
        .options(joinedload(CarritoItem.producto))
        .where(CarritoItem.usr_id == usr_id)
        .order_by(CarritoItem.id_car)
    ).all()
    respuesta = [
        CarritoItemRespuesta(
            producto=ProductoRespuesta.model_validate(i.producto),
            cantidad=i.cantidad,
            subtotal=i.producto.precio * i.cantidad,
        )
        for i in items
    ]
    return CarritoRespuesta(
        items=respuesta,
        total_piezas=sum(i.cantidad for i in items),
        total=sum((r.subtotal for r in respuesta), Decimal("0")),
    )


@router.get("/carrito", response_model=CarritoRespuesta)
def ver_carrito(usuario: Usuario = Depends(usuario_actual), db: Session = Depends(obtener_sesion)):
    return _carrito(db, usuario.id_usr)


@router.put("/carrito/{id_prod}", response_model=CarritoRespuesta)
def poner_en_carrito(
    id_prod: int,
    datos: CarritoCantidad,
    usuario: Usuario = Depends(usuario_actual),
    db: Session = Depends(obtener_sesion),
):
    """Agrega el producto o cambia su cantidad."""
    producto = db.get(Producto, id_prod)
    if producto is None or not producto.activo:
        raise HTTPException(404, "Producto no encontrado")
    if datos.cantidad > producto.stock:
        raise HTTPException(409, f"Solo hay {producto.stock} piezas disponibles")

    item = db.scalar(
        select(CarritoItem).where(CarritoItem.usr_id == usuario.id_usr, CarritoItem.id_prod == id_prod)
    )
    if item is None:
        db.add(CarritoItem(usr_id=usuario.id_usr, id_prod=id_prod, cantidad=datos.cantidad))
    else:
        item.cantidad = datos.cantidad
    db.commit()
    return _carrito(db, usuario.id_usr)


@router.delete("/carrito/{id_prod}", response_model=CarritoRespuesta)
def quitar_del_carrito(
    id_prod: int,
    usuario: Usuario = Depends(usuario_actual),
    db: Session = Depends(obtener_sesion),
):
    db.execute(
        delete(CarritoItem).where(CarritoItem.usr_id == usuario.id_usr, CarritoItem.id_prod == id_prod)
    )
    db.commit()
    return _carrito(db, usuario.id_usr)


# ----------------------------------------------------------------------
# Pago
# ----------------------------------------------------------------------
def _luhn_valido(numero: str) -> bool:
    """Algoritmo de Luhn: detecta números de tarjeta mal escritos."""
    total = 0
    for i, digito in enumerate(reversed(numero)):
        n = int(digito)
        if i % 2 == 1:
            n *= 2
            if n > 9:
                n -= 9
        total += n
    return total % 10 == 0


def _marca(numero: str) -> str:
    if numero.startswith("4"):
        return "Visa"
    if numero[:2] in {"51", "52", "53", "54", "55"} or 2221 <= int(numero[:4]) <= 2720:
        return "Mastercard"
    if numero[:2] in {"34", "37"}:
        return "American Express"
    return "Tarjeta"


def _validar_tarjeta(datos: PagoRequest) -> str:
    numero = "".join(c for c in datos.numero if c.isdigit())
    if not 13 <= len(numero) <= 19 or not _luhn_valido(numero):
        raise HTTPException(422, "El número de tarjeta no es válido")

    mes, anio = (int(x) for x in datos.expiracion.split("/"))
    if not 1 <= mes <= 12:
        raise HTTPException(422, "El mes de expiración no es válido")
    hoy = datetime.now()
    if (2000 + anio, mes) < (hoy.year, hoy.month):
        raise HTTPException(422, "La tarjeta está vencida")

    if numero == TARJETA_RECHAZADA:
        raise HTTPException(402, "Pago rechazado por el banco. Intenta con otra tarjeta")
    return numero


@router.post("/pedidos/pagar", response_model=PedidoRespuesta, status_code=201)
def pagar(
    datos: PagoRequest,
    usuario: Usuario = Depends(usuario_actual),
    db: Session = Depends(obtener_sesion),
):
    items = db.scalars(
        select(CarritoItem).where(CarritoItem.usr_id == usuario.id_usr).order_by(CarritoItem.id_car)
    ).all()
    if not items:
        raise HTTPException(400, "Tu carrito está vacío")

    numero = _validar_tarjeta(datos)

    # Bloquea los productos mientras se descuenta el stock (evita vender de más).
    ids = [i.id_prod for i in items]
    productos = {
        p.id_prod: p
        for p in db.scalars(select(Producto).where(Producto.id_prod.in_(ids)).with_for_update())
    }

    total = Decimal("0")
    detalles = []
    for item in items:
        producto = productos[item.id_prod]
        if item.cantidad > producto.stock:
            db.rollback()
            raise HTTPException(409, f"Ya no hay suficiente stock de {producto.nombre}")
        producto.stock -= item.cantidad
        total += producto.precio * item.cantidad
        detalles.append(
            PedidoDetalle(
                id_prod=producto.id_prod,
                nombre=producto.nombre,
                cantidad=item.cantidad,
                precio_unit=producto.precio,
            )
        )

    pedido = Pedido(
        usr_id=usuario.id_usr,
        total=total,
        estado="pagado",
        referencia="PAG-" + uuid.uuid4().hex[:8].upper(),
        marca=_marca(numero),
        ultimos4=numero[-4:],
        detalles=detalles,
    )
    db.add(pedido)
    for item in items:
        db.delete(item)
    db.commit()  # todo o nada: pedido, detalle, stock y carrito en una transacción
    db.refresh(pedido)
    return pedido


@router.get("/pedidos", response_model=list[PedidoRespuesta])
def mis_pedidos(usuario: Usuario = Depends(usuario_actual), db: Session = Depends(obtener_sesion)):
    return db.scalars(
        select(Pedido)
        .options(joinedload(Pedido.detalles))
        .where(Pedido.usr_id == usuario.id_usr)
        .order_by(Pedido.fecha.desc(), Pedido.id_ped.desc())
    ).unique().all()
