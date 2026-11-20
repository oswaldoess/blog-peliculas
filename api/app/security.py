"""Seguridad: hash de contraseñas (Argon2id) y tokens JWT con sesión en BD."""

import re
import uuid
from datetime import datetime, timedelta, timezone

import jwt
from pwdlib import PasswordHash

from .config import settings

# PasswordHash.recommended() usa Argon2id: hash lento, con sal aleatoria
# por contraseña y resistente a ataques con GPU.
_hasher = PasswordHash.recommended()

# Hash "señuelo" para gastar el mismo tiempo cuando el correo no existe
# y así no revelar qué correos están registrados (timing attack).
_HASH_SENUELO = _hasher.hash("contraseña-que-nadie-usa-123")

_REGLA_PASSWORD = re.compile(r"^(?=.*[A-Za-zÁÉÍÓÚáéíóúÑñ])(?=.*\d).{8,128}$")
_REGLA_CORREO = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


def hashear_password(password: str) -> str:
    return _hasher.hash(password)


def verificar_password(password: str, hash_guardado: str | None) -> bool:
    if not hash_guardado:
        _hasher.verify(password, _HASH_SENUELO)
        return False
    try:
        return _hasher.verify(password, hash_guardado)
    except Exception:
        # Hash con formato inválido (por ejemplo, datos viejos de prueba).
        return False


def password_valido(password: str) -> bool:
    """Mínimo 8 caracteres, al menos una letra y un número."""
    return bool(_REGLA_PASSWORD.match(password))


def correo_valido(correo: str) -> bool:
    return bool(_REGLA_CORREO.match(correo))


def crear_token(usr_id: int) -> tuple[str, str, datetime]:
    """Genera un JWT firmado. Regresa (token, jti, expiración UTC sin zona)."""
    ahora = datetime.now(timezone.utc)
    expira = ahora + timedelta(minutes=settings.TOKEN_MINUTOS)
    jti = str(uuid.uuid4())
    payload = {
        "sub": str(usr_id),
        "jti": jti,
        "iat": int(ahora.timestamp()),
        "exp": int(expira.timestamp()),
    }
    token = jwt.encode(payload, settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM)
    return token, jti, expira.replace(tzinfo=None)


def decodificar_token(token: str) -> dict:
    """Valida firma y expiración. Lanza jwt.PyJWTError si algo falla."""
    return jwt.decode(
        token,
        settings.JWT_SECRET,
        algorithms=[settings.JWT_ALGORITHM],
        options={"require": ["sub", "jti", "exp"]},
    )
