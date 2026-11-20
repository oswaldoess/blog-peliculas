"""Mensajería interna: chat privado entre usuarios registrados."""

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import and_, case, func, or_, select, update
from sqlalchemy.orm import Session

from ..database import obtener_sesion
from ..deps import usuario_actual
from ..models import Mensaje, Usuario
from ..schemas import ConversacionRespuesta, MensajeCrear, MensajeRespuesta, UsuarioPublico

router = APIRouter(prefix="/mensajes", tags=["Mensajes"])


def _entre(a: int, b: int):
    return or_(
        and_(Mensaje.emisor_id == a, Mensaje.receptor_id == b),
        and_(Mensaje.emisor_id == b, Mensaje.receptor_id == a),
    )


@router.get("/conversaciones", response_model=list[ConversacionRespuesta])
def conversaciones(usuario: Usuario = Depends(usuario_actual), db: Session = Depends(obtener_sesion)):
    yo = usuario.id_usr
    # Último mensaje de cada conversación en la que participo.
    otro = case((Mensaje.emisor_id == yo, Mensaje.receptor_id), else_=Mensaje.emisor_id)

    ultimos = (
        select(otro.label("otro_id"), func.max(Mensaje.id_msg).label("ultimo_id"))
        .where(or_(Mensaje.emisor_id == yo, Mensaje.receptor_id == yo))
        .group_by("otro_id")
        .subquery()
    )
    filas = db.execute(
        select(Mensaje, Usuario)
        .join(ultimos, Mensaje.id_msg == ultimos.c.ultimo_id)
        .join(Usuario, Usuario.id_usr == ultimos.c.otro_id)
        .order_by(Mensaje.id_msg.desc())
    ).all()

    no_leidos = dict(
        db.execute(
            select(Mensaje.emisor_id, func.count())
            .where(Mensaje.receptor_id == yo, Mensaje.leido.is_(False))
            .group_by(Mensaje.emisor_id)
        ).all()
    )

    return [
        ConversacionRespuesta(
            usuario=UsuarioPublico.model_validate(otro_usuario),
            ultimo_mensaje=mensaje.contenido,
            ultimo_es_mio=mensaje.emisor_id == yo,
            fecha=mensaje.fecha,
            no_leidos=int(no_leidos.get(otro_usuario.id_usr, 0)),
        )
        for mensaje, otro_usuario in filas
    ]


@router.get("/no-leidos", response_model=int)
def total_no_leidos(usuario: Usuario = Depends(usuario_actual), db: Session = Depends(obtener_sesion)):
    return db.scalar(
        select(func.count()).select_from(Mensaje).where(
            Mensaje.receptor_id == usuario.id_usr, Mensaje.leido.is_(False)
        )
    ) or 0


@router.get("/{otro_id}", response_model=list[MensajeRespuesta])
def chat(
    otro_id: int,
    despues_de: int = Query(default=0, ge=0, description="Solo mensajes con id mayor (para refrescar)"),
    usuario: Usuario = Depends(usuario_actual),
    db: Session = Depends(obtener_sesion),
):
    if db.get(Usuario, otro_id) is None:
        raise HTTPException(404, "Usuario no encontrado")
    mensajes = db.scalars(
        select(Mensaje)
        .where(_entre(usuario.id_usr, otro_id), Mensaje.id_msg > despues_de)
        .order_by(Mensaje.id_msg)
    ).all()
    # Al abrir el chat, lo que me mandaron queda como leído.
    db.execute(
        update(Mensaje)
        .where(Mensaje.emisor_id == otro_id, Mensaje.receptor_id == usuario.id_usr, Mensaje.leido.is_(False))
        .values(leido=True)
    )
    db.commit()
    return mensajes


@router.post("/{otro_id}", response_model=MensajeRespuesta, status_code=201)
def enviar(
    otro_id: int,
    datos: MensajeCrear,
    usuario: Usuario = Depends(usuario_actual),
    db: Session = Depends(obtener_sesion),
):
    if otro_id == usuario.id_usr:
        raise HTTPException(400, "No puedes enviarte mensajes a ti mismo")
    destino = db.get(Usuario, otro_id)
    if destino is None or not destino.activo:
        raise HTTPException(404, "Usuario no encontrado")
    texto = datos.contenido.strip()
    if not texto:
        raise HTTPException(422, "El mensaje no puede estar vacío")

    mensaje = Mensaje(emisor_id=usuario.id_usr, receptor_id=otro_id, contenido=texto)
    db.add(mensaje)
    db.commit()
    db.refresh(mensaje)
    return mensaje
