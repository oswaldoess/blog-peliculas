"""Registro, inicio y cierre de sesión."""

from datetime import timedelta

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy import select, update
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from ..config import settings
from ..database import obtener_sesion
from ..deps import obtener_sesion_actual, usuario_actual
from ..models import AUTOR, Sesion, Usuario, ahora_utc
from ..schemas import (
    CambioPassword,
    LoginRequest,
    MensajeSimple,
    RegistroRequest,
    TokenRespuesta,
    UsuarioRespuesta,
)
from ..security import (
    correo_valido,
    crear_token,
    hashear_password,
    password_valido,
    verificar_password,
)

router = APIRouter(prefix="/auth", tags=["Autenticación"])

MSG_PASSWORD = "La contraseña debe tener al menos 8 caracteres, una letra y un número"


def _abrir_sesion(db: Session, usuario: Usuario, request: Request) -> TokenRespuesta:
    """Crea el JWT y registra la sesión en la tabla `sesion`."""
    token, jti, expira = crear_token(usuario.id_usr)
    agente = (request.headers.get("user-agent") or "")[:255] or None
    db.add(Sesion(jti=jti, usr_id=usuario.id_usr, expira=expira, agente=agente))
    db.commit()
    return TokenRespuesta(
        access_token=token,
        expira=expira,
        usuario=UsuarioRespuesta.model_validate(usuario),
    )


@router.post("/registro", response_model=TokenRespuesta, status_code=201)
def registrar(datos: RegistroRequest, request: Request, db: Session = Depends(obtener_sesion)):
    """Registro público desde la app. Siempre crea usuarios con rol Autor."""
    correo = datos.mail.strip().lower()
    if not correo_valido(correo):
        raise HTTPException(422, "Ingresa un correo válido")
    if not password_valido(datos.password):
        raise HTTPException(422, MSG_PASSWORD)

    usuario = Usuario(
        nom_usr=datos.nom_usr.strip(),
        mail=correo,
        pass_hash=hashear_password(datos.password),
        dir_usr=datos.dir_usr,
        bio=datos.bio,
        tip_usu=AUTOR,  # el rol NUNCA lo decide el cliente
    )
    db.add(usuario)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(409, "Ese correo ya está registrado")
    db.refresh(usuario)
    return _abrir_sesion(db, usuario, request)


@router.post("/login", response_model=TokenRespuesta)
def iniciar_sesion(datos: LoginRequest, request: Request, db: Session = Depends(obtener_sesion)):
    correo = datos.mail.strip().lower()
    usuario = db.scalar(select(Usuario).where(Usuario.mail == correo))
    ahora = ahora_utc()

    # 1) Cuenta bloqueada temporalmente por demasiados intentos.
    if usuario is not None and usuario.bloqueado_hasta and usuario.bloqueado_hasta > ahora:
        minutos = max(1, int((usuario.bloqueado_hasta - ahora).total_seconds() // 60) + 1)
        raise HTTPException(
            status.HTTP_429_TOO_MANY_REQUESTS,
            f"Demasiados intentos fallidos. Intenta de nuevo en {minutos} min.",
        )

    # 2) Verificación de credenciales (mismo mensaje si el correo no existe).
    if not verificar_password(datos.password, usuario.pass_hash if usuario else None):
        if usuario is not None:
            usuario.intentos_fallidos += 1
            if usuario.intentos_fallidos >= settings.MAX_INTENTOS_LOGIN:
                usuario.bloqueado_hasta = ahora + timedelta(minutes=settings.MINUTOS_BLOQUEO)
                usuario.intentos_fallidos = 0
            db.commit()
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Correo o contraseña incorrectos")

    if not usuario.activo:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Tu cuenta está desactivada")

    usuario.intentos_fallidos = 0
    usuario.bloqueado_hasta = None
    db.commit()
    return _abrir_sesion(db, usuario, request)


@router.get("/me", response_model=UsuarioRespuesta)
def yo(usuario: Usuario = Depends(usuario_actual)):
    """La app lo usa al abrir para saber si el token guardado sigue vigente."""
    return usuario


@router.post("/logout", response_model=MensajeSimple)
def cerrar_sesion(sesion: Sesion = Depends(obtener_sesion_actual), db: Session = Depends(obtener_sesion)):
    sesion = db.merge(sesion)
    sesion.revocada = True
    db.commit()
    return MensajeSimple(mensaje="Sesión cerrada")


@router.put("/password", response_model=MensajeSimple)
def cambiar_password(
    datos: CambioPassword,
    sesion: Sesion = Depends(obtener_sesion_actual),
    usuario: Usuario = Depends(usuario_actual),
    db: Session = Depends(obtener_sesion),
):
    if not verificar_password(datos.actual, usuario.pass_hash):
        raise HTTPException(400, "La contraseña actual no es correcta")
    if not password_valido(datos.nueva):
        raise HTTPException(422, MSG_PASSWORD)

    usuario = db.merge(usuario)
    usuario.pass_hash = hashear_password(datos.nueva)
    # Cierra todas las demás sesiones abiertas (otros dispositivos).
    db.execute(
        update(Sesion)
        .where(Sesion.usr_id == usuario.id_usr, Sesion.jti != sesion.jti)
        .values(revocada=True)
    )
    db.commit()
    return MensajeSimple(mensaje="Contraseña actualizada. Se cerraron tus otras sesiones.")
