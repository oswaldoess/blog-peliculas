"""Pruebas automáticas de la API. Ejecutar desde api/:  python -m pytest -v"""

from decimal import Decimal

from sqlalchemy import select

from app.database import SessionLocal
from app.models import Producto, Usuario

from .conftest import login, registrar

RESENA = {
    "titulo": "Una gran película",
    "descripcion": "Texto de la reseña con suficiente contenido.",
    "pelicula": "Coco",
    "anio": 2017,
    "genero": "Animación",
}


# --- Seguridad -------------------------------------------------------
def test_password_se_guarda_con_hash_argon2(cliente):
    registrar(cliente)
    with SessionLocal() as db:
        u = db.scalar(select(Usuario).where(Usuario.mail == "ana@test.com"))
    assert u.pass_hash.startswith("$argon2id$")
    assert "Secreta123" not in u.pass_hash


def test_registro_no_permite_elegir_rol(cliente):
    r = cliente.post("/auth/registro", json={
        "nom_usr": "Hacker", "mail": "h@test.com", "password": "Secreta123", "tip_usu": 1})
    assert r.status_code == 201
    assert r.json()["usuario"]["tip_usu"] == 2


def test_password_debil_rechazada(cliente):
    r = cliente.post("/auth/registro", json={"nom_usr": "Ana", "mail": "a@test.com", "password": "soloLetras"})
    assert r.status_code == 422


def test_login_incorrecto_y_bloqueo(cliente):
    registrar(cliente)
    for _ in range(5):
        assert cliente.post("/auth/login", json={"mail": "ana@test.com", "password": "mala"}).status_code == 401
    r = cliente.post("/auth/login", json={"mail": "ana@test.com", "password": "Secreta123"})
    assert r.status_code == 429


def test_rutas_protegidas_sin_token(cliente):
    assert cliente.get("/posts").status_code == 401
    assert cliente.get("/auth/me", headers={"Authorization": "Bearer basura"}).status_code == 401


def test_logout_revoca_el_token(cliente):
    h, _ = registrar(cliente)
    assert cliente.get("/auth/me", headers=h).status_code == 200
    assert cliente.post("/auth/logout", headers=h).status_code == 200
    assert cliente.get("/auth/me", headers=h).status_code == 401


def test_solo_admin_lista_y_borra_usuarios(cliente):
    h, ana = registrar(cliente)
    assert cliente.get("/usuarios", headers=h).status_code == 403
    admin = login(cliente, "admin@test.com", "Admin1234")
    assert cliente.get("/usuarios", headers=admin).status_code == 200
    assert cliente.delete(f"/usuarios/{ana['id_usr']}", headers=admin).status_code == 204


# --- Reseñas ---------------------------------------------------------
def test_crear_y_ver_resenas_propias_y_ajenas(cliente):
    h_ana, _ = registrar(cliente)
    h_beto, _ = registrar(cliente, "Beto", "beto@test.com")
    assert cliente.post("/posts", json=RESENA, headers=h_ana).status_code == 201
    assert cliente.post("/posts", json={**RESENA, "pelicula": "Roma"}, headers=h_beto).status_code == 201

    todas = cliente.get("/posts", headers=h_ana).json()
    mias = cliente.get("/posts?mios=true", headers=h_ana).json()
    assert len(todas) == 2 and len(mias) == 1
    assert mias[0]["es_mio"] is True and mias[0]["autor"]["nom_usr"] == "Ana"


def test_no_se_puede_borrar_resena_ajena(cliente):
    h_ana, _ = registrar(cliente)
    h_beto, _ = registrar(cliente, "Beto", "beto@test.com")
    pid = cliente.post("/posts", json=RESENA, headers=h_ana).json()["id_blog"]
    assert cliente.delete(f"/posts/{pid}", headers=h_beto).status_code == 403
    assert cliente.delete(f"/posts/{pid}", headers=h_ana).status_code == 204


def test_valoracion_con_estrellas(cliente):
    h_ana, _ = registrar(cliente)
    h_beto, _ = registrar(cliente, "Beto", "beto@test.com")
    pid = cliente.post("/posts", json=RESENA, headers=h_ana).json()["id_blog"]
    assert cliente.put(f"/posts/{pid}/valoracion", json={"estrellas": 5}, headers=h_ana).status_code == 400
    r = cliente.put(f"/posts/{pid}/valoracion", json={"estrellas": 4}, headers=h_beto)
    assert r.json() == {"promedio": 4.0, "total_valoraciones": 1, "mi_valoracion": 4}
    assert cliente.put(f"/posts/{pid}/valoracion", json={"estrellas": 9}, headers=h_beto).status_code == 422


# --- Comentarios y reacciones ---------------------------------------
def test_comentarios_y_reacciones(cliente):
    h_ana, _ = registrar(cliente)
    h_beto, _ = registrar(cliente, "Beto", "beto@test.com")
    pid = cliente.post("/posts", json=RESENA, headers=h_ana).json()["id_blog"]
    cid = cliente.post(f"/posts/{pid}/comentarios", json={"comentario": "¡Buenísima!"}, headers=h_beto).json()["id_com"]

    comentarios = cliente.get(f"/posts/{pid}/comentarios", headers=h_ana).json()
    assert comentarios[0]["comentario"] == "¡Buenísima!"
    assert comentarios[0]["puede_borrar"] is True  # Ana es autora de la reseña

    r = cliente.post(f"/comentarios/{cid}/reacciones", json={"tipo": "love"}, headers=h_ana)
    assert r.json() == [{"tipo": "love", "total": 1, "mia": True}]
    r = cliente.post(f"/comentarios/{cid}/reacciones", json={"tipo": "love"}, headers=h_ana)
    assert r.json() == []  # segunda vez la quita


# --- Mensajería ------------------------------------------------------
def test_chat_privado(cliente):
    h_ana, ana = registrar(cliente)
    h_beto, beto = registrar(cliente, "Beto", "beto@test.com")
    assert cliente.post(f"/mensajes/{beto['id_usr']}", json={"contenido": "Hola"}, headers=h_ana).status_code == 201
    assert cliente.get("/mensajes/no-leidos", headers=h_beto).json() == 1

    conv = cliente.get("/mensajes/conversaciones", headers=h_beto).json()
    assert conv[0]["usuario"]["nom_usr"] == "Ana" and conv[0]["no_leidos"] == 1

    chat = cliente.get(f"/mensajes/{ana['id_usr']}", headers=h_beto).json()
    assert chat[0]["contenido"] == "Hola"
    assert cliente.get("/mensajes/no-leidos", headers=h_beto).json() == 0


# --- Tienda ----------------------------------------------------------
def _producto(precio="150.00", stock=5):
    with SessionLocal() as db:
        p = Producto(nombre="Taza", descripcion="Taza de cine", categoria="Accesorios",
                     precio=Decimal(precio), stock=stock)
        db.add(p)
        db.commit()
        return p.id_prod


TARJETA_OK = {"titular": "Ana López", "numero": "4242 4242 4242 4242", "expiracion": "12/30", "cvv": "123"}


def test_catalogo_y_carrito(cliente):
    h, _ = registrar(cliente)
    pid = _producto()
    assert cliente.get("/productos", headers=h).json()[0]["precio"] == 150.0
    r = cliente.put(f"/carrito/{pid}", json={"cantidad": 2}, headers=h).json()
    assert r["total"] == 300.0 and r["total_piezas"] == 2
    assert cliente.put(f"/carrito/{pid}", json={"cantidad": 9}, headers=h).status_code == 409  # sin stock
    assert cliente.delete(f"/carrito/{pid}", headers=h).json()["items"] == []


def test_pago_crea_pedido_descuenta_stock_y_vacia_carrito(cliente):
    h, _ = registrar(cliente)
    pid = _producto(stock=5)
    cliente.put(f"/carrito/{pid}", json={"cantidad": 2}, headers=h)

    r = cliente.post("/pedidos/pagar", json=TARJETA_OK, headers=h)
    assert r.status_code == 201, r.text
    pedido = r.json()
    assert pedido["total"] == 300.0 and pedido["marca"] == "Visa" and pedido["ultimos4"] == "4242"
    assert "numero" not in pedido and "cvv" not in pedido

    with SessionLocal() as db:
        assert db.get(Producto, pid).stock == 3
    assert cliente.get("/carrito", headers=h).json()["items"] == []
    assert len(cliente.get("/pedidos", headers=h).json()) == 1


def test_pago_rechaza_tarjetas_invalidas(cliente):
    h, _ = registrar(cliente)
    pid = _producto()
    assert cliente.post("/pedidos/pagar", json=TARJETA_OK, headers=h).status_code == 400  # carrito vacío
    cliente.put(f"/carrito/{pid}", json={"cantidad": 1}, headers=h)
    malas = [
        {**TARJETA_OK, "numero": "4242 4242 4242 4241"},  # falla Luhn
        {**TARJETA_OK, "expiracion": "01/20"},             # vencida
        {**TARJETA_OK, "cvv": "12"},                       # CVV corto
    ]
    for tarjeta in malas:
        assert cliente.post("/pedidos/pagar", json=tarjeta, headers=h).status_code == 422
    rechazada = {**TARJETA_OK, "numero": "4000 0000 0000 0002"}
    assert cliente.post("/pedidos/pagar", json=rechazada, headers=h).status_code == 402
    assert len(cliente.get("/carrito", headers=h).json()["items"]) == 1  # el carrito sigue intacto
