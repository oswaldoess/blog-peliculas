"""Configura una BD SQLite temporal para probar la API sin tocar MySQL."""

import os
import tempfile

import pytest

_tmp = tempfile.mkdtemp()
os.environ["DATABASE_URL"] = f"sqlite:///{_tmp}/pruebas.db"
os.environ["JWT_SECRET"] = "secreto-solo-para-pruebas-automaticas-1234567890"

from fastapi.testclient import TestClient  # noqa: E402
from sqlalchemy import event  # noqa: E402

from app.database import Base, SessionLocal, engine  # noqa: E402
from app.main import app  # noqa: E402
from app.models import TipoUsuario, Usuario  # noqa: E402
from app.security import hashear_password  # noqa: E402


@event.listens_for(engine, "connect")
def _activar_fk(conexion, _):
    conexion.execute("PRAGMA foreign_keys=ON")


@pytest.fixture(autouse=True)
def bd_limpia():
    Base.metadata.drop_all(engine)
    Base.metadata.create_all(engine)
    with SessionLocal() as db:
        db.add_all([
            TipoUsuario(id_tipo=1, nombre="Administrador", descripcion="admin"),
            TipoUsuario(id_tipo=2, nombre="Autor", descripcion="autor"),
        ])
        db.add(Usuario(nom_usr="Admin", mail="admin@test.com",
                       pass_hash=hashear_password("Admin1234"), tip_usu=1))
        db.commit()
    yield


@pytest.fixture
def cliente():
    return TestClient(app)


def registrar(cliente, nombre="Ana", correo="ana@test.com", password="Secreta123"):
    r = cliente.post("/auth/registro", json={"nom_usr": nombre, "mail": correo, "password": password})
    assert r.status_code == 201, r.text
    return {"Authorization": f"Bearer {r.json()['access_token']}"}, r.json()["usuario"]


def login(cliente, correo, password):
    r = cliente.post("/auth/login", json={"mail": correo, "password": password})
    assert r.status_code == 200, r.text
    return {"Authorization": f"Bearer {r.json()['access_token']}"}
