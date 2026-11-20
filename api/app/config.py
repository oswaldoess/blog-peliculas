"""Configuración de la API leída desde variables de entorno (.env)."""

import os
from pathlib import Path

from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent.parent
load_dotenv(BASE_DIR / ".env")


def _lista(valor: str) -> list[str]:
    return [v.strip() for v in valor.split(",") if v.strip()]


class Settings:
    # --- Base de datos -------------------------------------------------
    DB_HOST: str = os.getenv("DB_HOST", "127.0.0.1")
    DB_PORT: int = int(os.getenv("DB_PORT", "3306"))
    DB_USER: str = os.getenv("DB_USER", "root")
    DB_PASSWORD: str = os.getenv("DB_PASSWORD", "")
    DB_NAME: str = os.getenv("DB_NAME", "blog_peliculas")
    # Si se define, tiene prioridad (se usa en las pruebas con SQLite).
    DATABASE_URL: str | None = os.getenv("DATABASE_URL")

    # --- Seguridad -----------------------------------------------------
    JWT_SECRET: str = os.getenv("JWT_SECRET", "")
    JWT_ALGORITHM: str = "HS256"
    TOKEN_MINUTOS: int = int(os.getenv("TOKEN_MINUTOS", "720"))  # 12 h
    MAX_INTENTOS_LOGIN: int = int(os.getenv("MAX_INTENTOS_LOGIN", "5"))
    MINUTOS_BLOQUEO: int = int(os.getenv("MINUTOS_BLOQUEO", "5"))

    # --- CORS ----------------------------------------------------------
    CORS_ORIGINS: list[str] = _lista(os.getenv("CORS_ORIGINS", "*"))


settings = Settings()

if not settings.JWT_SECRET or len(settings.JWT_SECRET) < 32:
    raise RuntimeError(
        "JWT_SECRET no está configurado o es muy corto (mínimo 32 caracteres). "
        "Copia .env.example a .env y genera uno con: "
        "python -c \"import secrets; print(secrets.token_urlsafe(48))\""
    )
