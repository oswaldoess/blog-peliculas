"""
API REST del blog de reseñas de películas.

Ejecutar desde la carpeta api/:
    uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

Documentación interactiva: http://127.0.0.1:8000/docs
"""

import logging

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from sqlalchemy.exc import OperationalError

from .config import settings
from .routers import auth, comentarios, mensajes, posts, tienda, usuarios

log = logging.getLogger("api")

app = FastAPI(
    title="API · Blog de reseñas de películas",
    description=(
        "Backend de la app móvil (Flutter). Autenticación con JWT + sesiones en BD, "
        "contraseñas con Argon2id, reseñas, comentarios, valoraciones, reacciones, mensajería y tienda."
    ),
    version="2.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type", "Accept"],
)


@app.middleware("http")
async def cabeceras_seguridad(request: Request, call_next):
    respuesta = await call_next(request)
    respuesta.headers["X-Content-Type-Options"] = "nosniff"
    respuesta.headers["X-Frame-Options"] = "DENY"
    respuesta.headers["Referrer-Policy"] = "no-referrer"
    return respuesta


# ---------------------------------------------------------------------
# Manejo de errores: siempre JSON con {"detail": "mensaje legible"}
# ---------------------------------------------------------------------
_NOMBRES_CAMPO = {
    "nom_usr": "nombre",
    "mail": "correo",
    "password": "contraseña",
    "nueva": "contraseña nueva",
    "titulo": "título",
    "descripcion": "reseña",
    "pelicula": "película",
    "anio": "año",
    "comentario": "comentario",
    "contenido": "mensaje",
    "estrellas": "estrellas",
    "titular": "titular",
    "numero": "número de tarjeta",
    "expiracion": "fecha de expiración (MM/AA)",
    "cvv": "CVV",
    "cantidad": "cantidad",
}


@app.exception_handler(RequestValidationError)
async def error_validacion(_: Request, exc: RequestValidationError):
    primero = exc.errors()[0] if exc.errors() else {}
    campo = str(primero.get("loc", ["", "dato"])[-1])
    nombre = _NOMBRES_CAMPO.get(campo, campo)
    tipo = primero.get("type", "")
    ctx = primero.get("ctx") or {}
    if tipo == "string_too_short":
        mensaje = f"El campo {nombre} debe tener al menos {ctx.get('min_length')} caracteres"
    elif tipo == "string_too_long":
        mensaje = f"El campo {nombre} admite máximo {ctx.get('max_length')} caracteres"
    elif tipo == "string_pattern_mismatch":
        mensaje = f"El formato de {nombre} no es válido"
    elif tipo == "missing":
        mensaje = f"Falta el campo {nombre}"
    elif tipo in ("greater_than_equal", "less_than_equal"):
        mensaje = f"El valor de {nombre} está fuera del rango permitido"
    else:
        mensaje = f"Dato inválido en {nombre}"
    return JSONResponse(status_code=422, content={"detail": mensaje})


@app.exception_handler(OperationalError)
async def error_bd(_: Request, exc: OperationalError):
    log.exception("Error de base de datos", exc_info=exc)
    return JSONResponse(status_code=503, content={"detail": "La base de datos no está disponible"})


@app.exception_handler(Exception)
async def error_general(_: Request, exc: Exception):
    # Nunca se envían trazas internas al cliente.
    log.exception("Error no controlado", exc_info=exc)
    return JSONResponse(status_code=500, content={"detail": "Ocurrió un error inesperado"})


# ---------------------------------------------------------------------
# Rutas
# ---------------------------------------------------------------------
@app.get("/", tags=["Estado"])
def inicio():
    return {"mensaje": "API del blog de películas funcionando", "docs": "/docs"}


app.include_router(auth.router)
app.include_router(usuarios.router)
app.include_router(posts.router)
app.include_router(comentarios.router)
app.include_router(mensajes.router)
app.include_router(tienda.router)
