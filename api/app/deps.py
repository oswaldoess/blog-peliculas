"""Dependencias de FastAPI para autenticación y control de acceso."""

import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import select
from sqlalchemy.orm import Session

from .database import obtener_sesion
from .models import Sesion, Usuario, ahora_utc
from .security import decodificar_token

_bearer = HTTPBearer(auto_error=False)


def _no_autorizado(mensaje: str) -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail=mensaje,
        headers={"WWW-Authenticate": "Bearer"},
    )


def obtener_sesion_actual(
    credenciales: HTTPAuthorizationCredentials | None = Depends(_bearer),
    db: Session = Depends(obtener_sesion),
) -> Sesion:
    """Valida el token Bearer y que su sesión siga vigente en la BD."""
    if credenciales is None:
        raise _no_autorizado("Debes iniciar sesión")

    try:
        payload = decodificar_token(credenciales.credentials)
    except jwt.ExpiredSignatureError:
        raise _no_autorizado("Tu sesión expiró, vuelve a iniciar sesión")
    except jwt.PyJWTError:
        raise _no_autorizado("Token inválido")

    sesion = db.scalar(select(Sesion).where(Sesion.jti == payload["jti"]))
    if sesion is None or sesion.revocada or sesion.expira < ahora_utc():
        raise _no_autorizado("La sesión ya no es válida, vuelve a iniciar sesión")
    if str(sesion.usr_id) != payload["sub"]:
        raise _no_autorizado("Token inválido")
    return sesion


def usuario_actual(
    sesion: Sesion = Depends(obtener_sesion_actual),
    db: Session = Depends(obtener_sesion),
) -> Usuario:
    usuario = db.get(Usuario, sesion.usr_id)
    if usuario is None or not usuario.activo:
        raise _no_autorizado("Usuario inactivo o eliminado")
    return usuario


def solo_admin(usuario: Usuario = Depends(usuario_actual)) -> Usuario:
    if not usuario.es_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Solo un administrador puede hacer esto",
        )
    return usuario
