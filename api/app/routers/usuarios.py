"""Gestión de usuarios (directorio público y administración)."""

from fastapi import APIRouter, Depends, HTTPException, Response
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from ..database import obtener_sesion
from ..deps import solo_admin, usuario_actual
from ..models import Usuario
from ..schemas import UsuarioActualizar, UsuarioAdminCrear, UsuarioPublico, UsuarioRespuesta
from ..security import correo_valido, hashear_password, password_valido
from .auth import MSG_PASSWORD

router = APIRouter(prefix="/usuarios", tags=["Usuarios"])


@router.get("/directorio", response_model=list[UsuarioPublico])
def directorio(
    usuario: Usuario = Depends(usuario_actual),
    db: Session = Depends(obtener_sesion),
):
    """Lista de usuarios activos (sin correos) para iniciar un chat."""
    return db.scalars(
        select(Usuario)
        .where(Usuario.activo.is_(True), Usuario.id_usr != usuario.id_usr)
        .order_by(Usuario.nom_usr)
    ).all()


@router.get("", response_model=list[UsuarioRespuesta])
def listar(_: Usuario = Depends(solo_admin), db: Session = Depends(obtener_sesion)):
    return db.scalars(select(Usuario).order_by(Usuario.id_usr)).all()


@router.get("/{usuario_id}", response_model=UsuarioPublico)
def ver_perfil(
    usuario_id: int,
    _: Usuario = Depends(usuario_actual),
    db: Session = Depends(obtener_sesion),
):
    usuario = db.get(Usuario, usuario_id)
    if usuario is None:
        raise HTTPException(404, "Usuario no encontrado")
    return usuario


@router.post("", response_model=UsuarioRespuesta, status_code=201)
def crear(datos: UsuarioAdminCrear, _: Usuario = Depends(solo_admin), db: Session = Depends(obtener_sesion)):
    """El administrador puede crear usuarios y elegir su rol."""
    correo = datos.mail.strip().lower()
    if not correo_valido(correo):
        raise HTTPException(422, "Ingresa un correo válido")
    if not password_valido(datos.password):
        raise HTTPException(422, MSG_PASSWORD)

    nuevo = Usuario(
        nom_usr=datos.nom_usr.strip(),
        mail=correo,
        pass_hash=hashear_password(datos.password),
        dir_usr=datos.dir_usr,
        bio=datos.bio,
        tip_usu=datos.tip_usu,
    )
    db.add(nuevo)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(409, "Ese correo ya está registrado")
    db.refresh(nuevo)
    return nuevo


@router.put("/{usuario_id}", response_model=UsuarioRespuesta)
def actualizar(
    usuario_id: int,
    datos: UsuarioActualizar,
    actual: Usuario = Depends(usuario_actual),
    db: Session = Depends(obtener_sesion),
):
    """Cada quien edita su perfil; el admin puede editar a cualquiera."""
    if actual.id_usr != usuario_id and not actual.es_admin:
        raise HTTPException(403, "No puedes editar el perfil de otra persona")

    usuario = db.get(Usuario, usuario_id)
    if usuario is None:
        raise HTTPException(404, "Usuario no encontrado")

    cambios = datos.model_dump(exclude_unset=True)

    if ("tip_usu" in cambios or "activo" in cambios) and not actual.es_admin:
        raise HTTPException(403, "Solo un administrador puede cambiar roles o estado")
    if actual.id_usr == usuario_id and (
        cambios.get("activo") is False or cambios.get("tip_usu") == 2
    ):
        raise HTTPException(400, "No puedes quitarte tu propio acceso de administrador")

    if "mail" in cambios and cambios["mail"] is not None:
        correo = cambios["mail"].strip().lower()
        if not correo_valido(correo):
            raise HTTPException(422, "Ingresa un correo válido")
        cambios["mail"] = correo
    if "nom_usr" in cambios and cambios["nom_usr"] is not None:
        cambios["nom_usr"] = cambios["nom_usr"].strip()

    for campo, valor in cambios.items():
        if campo in ("nom_usr", "mail", "tip_usu", "activo") and valor is None:
            continue  # estos campos no admiten nulo
        if isinstance(valor, str):
            valor = valor.strip() or None
        setattr(usuario, campo, valor)

    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(409, "Ese correo ya está registrado")
    db.refresh(usuario)
    return usuario


@router.delete("/{usuario_id}", status_code=204)
def eliminar(usuario_id: int, admin: Usuario = Depends(solo_admin), db: Session = Depends(obtener_sesion)):
    if admin.id_usr == usuario_id:
        raise HTTPException(400, "No puedes eliminar tu propia cuenta")
    usuario = db.get(Usuario, usuario_id)
    if usuario is None:
        raise HTTPException(404, "Usuario no encontrado")
    db.delete(usuario)
    db.commit()
    return Response(status_code=204)
