"""Esquemas Pydantic: definen el JSON que entra y sale de la API."""

from datetime import datetime, timezone
from decimal import Decimal
from typing import Annotated, Literal

from pydantic import BaseModel, ConfigDict, Field, PlainSerializer, field_validator


def _a_iso_utc(valor: datetime) -> str:
    """Las fechas se guardan en UTC sin zona; se envían con '+00:00'."""
    if valor.tzinfo is None:
        valor = valor.replace(tzinfo=timezone.utc)
    return valor.isoformat()


FechaUTC = Annotated[datetime, PlainSerializer(_a_iso_utc, return_type=str)]

TipoReaccion = Literal["like", "love", "haha", "wow", "fire", "clap"]


def _limpiar(valor: str | None) -> str | None:
    if valor is None:
        return None
    valor = valor.strip()
    return valor or None


# ----------------------------------------------------------------------
# Usuarios y autenticación
# ----------------------------------------------------------------------
class UsuarioPublico(BaseModel):
    """Datos que cualquier usuario autenticado puede ver de otro."""

    model_config = ConfigDict(from_attributes=True)

    id_usr: int
    nom_usr: str
    tip_usu: int
    dir_usr: str | None = None
    bio: str | None = None
    creado_en: FechaUTC


class UsuarioRespuesta(UsuarioPublico):
    """Datos completos: solo para el propio usuario o un administrador."""

    mail: str
    activo: bool


class AutorMini(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id_usr: int
    nom_usr: str


class RegistroRequest(BaseModel):
    nom_usr: str = Field(min_length=2, max_length=100)
    mail: str = Field(min_length=5, max_length=150)
    password: str = Field(min_length=8, max_length=128)
    dir_usr: str | None = Field(default=None, max_length=200)
    bio: str | None = Field(default=None, max_length=280)

    @field_validator("dir_usr", "bio")
    @classmethod
    def limpiar_opcionales(cls, valor: str | None) -> str | None:
        return _limpiar(valor)


class UsuarioAdminCrear(RegistroRequest):
    tip_usu: Literal[1, 2] = 2


class LoginRequest(BaseModel):
    mail: str = Field(min_length=3, max_length=150)
    password: str = Field(min_length=1, max_length=128)


class TokenRespuesta(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expira: FechaUTC
    usuario: UsuarioRespuesta


class UsuarioActualizar(BaseModel):
    """Todos los campos son opcionales; solo se cambian los que se envían."""

    nom_usr: str | None = Field(default=None, min_length=2, max_length=100)
    mail: str | None = Field(default=None, min_length=5, max_length=150)
    dir_usr: str | None = Field(default=None, max_length=200)
    bio: str | None = Field(default=None, max_length=280)
    # Solo los aplica un administrador:
    tip_usu: Literal[1, 2] | None = None
    activo: bool | None = None


class CambioPassword(BaseModel):
    actual: str = Field(min_length=1, max_length=128)
    nueva: str = Field(min_length=8, max_length=128)


# ----------------------------------------------------------------------
# Reseñas (posts)
# ----------------------------------------------------------------------
class PostCrear(BaseModel):
    titulo: str = Field(min_length=3, max_length=150)
    descripcion: str = Field(min_length=10, max_length=20000)
    pelicula: str = Field(min_length=1, max_length=150)
    anio: int | None = Field(default=None, ge=1888, le=2100)
    genero: str | None = Field(default=None, max_length=40)
    img: str | None = Field(default=None, max_length=500)
    tags: str | None = Field(default=None, max_length=255)

    @field_validator("genero", "img", "tags")
    @classmethod
    def limpiar_opcionales(cls, valor: str | None) -> str | None:
        return _limpiar(valor)


class PostRespuesta(BaseModel):
    id_blog: int
    titulo: str
    descripcion: str
    pelicula: str
    anio: int | None
    genero: str | None
    img: str | None
    tags: str | None
    fecha: FechaUTC
    actualizado: FechaUTC | None
    autor: AutorMini
    promedio: float
    total_valoraciones: int
    total_comentarios: int
    mi_valoracion: int | None
    es_mio: bool


class ValoracionRequest(BaseModel):
    estrellas: int = Field(ge=1, le=5)


class ValoracionRespuesta(BaseModel):
    promedio: float
    total_valoraciones: int
    mi_valoracion: int | None


# ----------------------------------------------------------------------
# Comentarios y reacciones
# ----------------------------------------------------------------------
class ComentarioCrear(BaseModel):
    comentario: str = Field(min_length=1, max_length=2000)


class ReaccionRequest(BaseModel):
    tipo: TipoReaccion


class ReaccionResumen(BaseModel):
    tipo: str
    total: int
    mia: bool


class ComentarioRespuesta(BaseModel):
    id_com: int
    comentario: str
    fecha: FechaUTC
    blog_id: int
    autor: AutorMini
    reacciones: list[ReaccionResumen]
    puede_borrar: bool


# ----------------------------------------------------------------------
# Mensajería interna
# ----------------------------------------------------------------------
class MensajeCrear(BaseModel):
    contenido: str = Field(min_length=1, max_length=2000)


class MensajeRespuesta(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id_msg: int
    emisor_id: int
    receptor_id: int
    contenido: str
    fecha: FechaUTC
    leido: bool


class ConversacionRespuesta(BaseModel):
    usuario: UsuarioPublico
    ultimo_mensaje: str
    ultimo_es_mio: bool
    fecha: FechaUTC
    no_leidos: int


# ----------------------------------------------------------------------
# Archivos
# ----------------------------------------------------------------------
class ImagenRespuesta(BaseModel):
    url: str


class MensajeSimple(BaseModel):
    mensaje: str


# ----------------------------------------------------------------------
# Tienda
# ----------------------------------------------------------------------
Dinero = Annotated[Decimal, PlainSerializer(lambda v: float(v), return_type=float)]


class ProductoRespuesta(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id_prod: int
    nombre: str
    descripcion: str
    categoria: str
    precio: Dinero
    stock: int
    img: str | None


class CarritoCantidad(BaseModel):
    cantidad: int = Field(ge=1, le=20)


class CarritoItemRespuesta(BaseModel):
    producto: ProductoRespuesta
    cantidad: int
    subtotal: Dinero


class CarritoRespuesta(BaseModel):
    items: list[CarritoItemRespuesta]
    total_piezas: int
    total: Dinero


class PagoRequest(BaseModel):
    """Datos de la tarjeta. Solo se usan para validar; nunca se guardan completos."""

    titular: str = Field(min_length=3, max_length=100)
    numero: str = Field(min_length=12, max_length=23)
    expiracion: str = Field(pattern=r"^\d{2}/\d{2}$", description="MM/AA")
    cvv: str = Field(pattern=r"^\d{3,4}$")


class PedidoDetalleRespuesta(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id_prod: int
    nombre: str
    cantidad: int
    precio_unit: Dinero


class PedidoRespuesta(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id_ped: int
    total: Dinero
    estado: str
    referencia: str
    marca: str
    ultimos4: str
    fecha: FechaUTC
    detalles: list[PedidoDetalleRespuesta]
