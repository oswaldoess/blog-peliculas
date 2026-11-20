"""Conexión a MySQL con SQLAlchemy 2.0."""

from sqlalchemy import create_engine
from sqlalchemy.engine import URL
from sqlalchemy.orm import DeclarativeBase, sessionmaker

from .config import settings

if settings.DATABASE_URL:
    url = settings.DATABASE_URL
else:
    url = URL.create(
        drivername="mysql+pymysql",
        username=settings.DB_USER,
        password=settings.DB_PASSWORD,
        host=settings.DB_HOST,
        port=settings.DB_PORT,
        database=settings.DB_NAME,
        query={"charset": "utf8mb4"},
    )

_connect_args = {"check_same_thread": False} if str(url).startswith("sqlite") else {}

engine = create_engine(url, pool_pre_ping=True, connect_args=_connect_args)

SessionLocal = sessionmaker(bind=engine, autocommit=False, autoflush=False)


class Base(DeclarativeBase):
    pass


def obtener_sesion():
    """Dependencia de FastAPI: abre una sesión por petición y la cierra al final."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
