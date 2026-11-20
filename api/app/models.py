"""Modelos ORM. Reflejan exactamente las tablas de database/blog_peliculas.sql."""

from datetime import datetime, timezone
from decimal import Decimal

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    DateTime,
    ForeignKey,
    Integer,
    Numeric,
    SmallInteger,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .database import Base


def ahora_utc() -> datetime:
    """Fecha/hora actual en UTC sin zona (así se guarda en MySQL)."""
    return datetime.now(timezone.utc).replace(tzinfo=None)


ADMIN = 1
AUTOR = 2
TIPOS_REACCION = ("like", "love", "haha", "wow", "fire", "clap")


class TipoUsuario(Base):
    __tablename__ = "tipo_usuario"

    id_tipo: Mapped[int] = mapped_column(SmallInteger, primary_key=True)
    nombre: Mapped[str] = mapped_column(String(30), unique=True)
    descripcion: Mapped[str] = mapped_column(String(150))


class Usuario(Base):
    __tablename__ = "usuario"

    id_usr: Mapped[int] = mapped_column(Integer, primary_key=True)
    nom_usr: Mapped[str] = mapped_column(String(100))
    mail: Mapped[str] = mapped_column(String(150), unique=True)
    pass_hash: Mapped[str] = mapped_column("pass", String(255))
    dir_usr: Mapped[str | None] = mapped_column(String(200))
    bio: Mapped[str | None] = mapped_column(String(280))
    tip_usu: Mapped[int] = mapped_column(
        SmallInteger, ForeignKey("tipo_usuario.id_tipo"), default=AUTOR
    )
    activo: Mapped[bool] = mapped_column(Boolean, default=True)
    intentos_fallidos: Mapped[int] = mapped_column(Integer, default=0)
    bloqueado_hasta: Mapped[datetime | None] = mapped_column(DateTime)
    creado_en: Mapped[datetime] = mapped_column(DateTime, default=ahora_utc)

    publicaciones: Mapped[list["Blog"]] = relationship(
        back_populates="autor", cascade="all, delete-orphan", passive_deletes=True
    )

    @property
    def es_admin(self) -> bool:
        return self.tip_usu == ADMIN


class Sesion(Base):
    __tablename__ = "sesion"

    id_sesion: Mapped[int] = mapped_column(Integer, primary_key=True)
    jti: Mapped[str] = mapped_column(String(36), unique=True)
    usr_id: Mapped[int] = mapped_column(
        ForeignKey("usuario.id_usr", ondelete="CASCADE"), index=True
    )
    creada: Mapped[datetime] = mapped_column(DateTime, default=ahora_utc)
    expira: Mapped[datetime] = mapped_column(DateTime)
    revocada: Mapped[bool] = mapped_column(Boolean, default=False)
    agente: Mapped[str | None] = mapped_column(String(255))


class Blog(Base):
    __tablename__ = "blog"

    id_blog: Mapped[int] = mapped_column(Integer, primary_key=True)
    titulo: Mapped[str] = mapped_column(String(150))
    descripcion: Mapped[str] = mapped_column(Text)
    img: Mapped[str | None] = mapped_column(String(500))
    tags: Mapped[str | None] = mapped_column(String(255))
    pelicula: Mapped[str] = mapped_column(String(150))
    anio: Mapped[int | None] = mapped_column(SmallInteger)
    genero: Mapped[str | None] = mapped_column(String(40), index=True)
    usr_id: Mapped[int] = mapped_column(
        ForeignKey("usuario.id_usr", ondelete="CASCADE"), index=True
    )
    fecha: Mapped[datetime] = mapped_column(DateTime, default=ahora_utc, index=True)
    actualizado: Mapped[datetime | None] = mapped_column(DateTime)

    autor: Mapped[Usuario] = relationship(back_populates="publicaciones")
    comentarios: Mapped[list["Comentario"]] = relationship(
        back_populates="publicacion", cascade="all, delete-orphan", passive_deletes=True
    )
    valoraciones: Mapped[list["Valoracion"]] = relationship(
        cascade="all, delete-orphan", passive_deletes=True
    )


class Comentario(Base):
    __tablename__ = "comentarios"

    id_com: Mapped[int] = mapped_column(Integer, primary_key=True)
    comentario: Mapped[str] = mapped_column(Text)
    fecha: Mapped[datetime] = mapped_column(DateTime, default=ahora_utc)
    estatus: Mapped[int] = mapped_column(SmallInteger, default=1)
    usr_id: Mapped[int] = mapped_column(ForeignKey("usuario.id_usr", ondelete="CASCADE"))
    blog_id: Mapped[int] = mapped_column(
        ForeignKey("blog.id_blog", ondelete="CASCADE"), index=True
    )

    autor: Mapped[Usuario] = relationship()
    publicacion: Mapped[Blog] = relationship(back_populates="comentarios")
    reacciones: Mapped[list["Reaccion"]] = relationship(
        cascade="all, delete-orphan", passive_deletes=True
    )


class Valoracion(Base):
    __tablename__ = "valoracion"
    __table_args__ = (
        UniqueConstraint("usr_id", "blog_id", name="uq_valoracion"),
        CheckConstraint("estrellas BETWEEN 1 AND 5", name="ck_valoracion_rango"),
    )

    id_val: Mapped[int] = mapped_column(Integer, primary_key=True)
    usr_id: Mapped[int] = mapped_column(ForeignKey("usuario.id_usr", ondelete="CASCADE"))
    blog_id: Mapped[int] = mapped_column(ForeignKey("blog.id_blog", ondelete="CASCADE"))
    estrellas: Mapped[int] = mapped_column(SmallInteger)
    fecha: Mapped[datetime] = mapped_column(DateTime, default=ahora_utc)


class Reaccion(Base):
    __tablename__ = "reaccion"
    __table_args__ = (
        UniqueConstraint("usr_id", "com_id", "tipo", name="uq_reaccion"),
    )

    id_reac: Mapped[int] = mapped_column(Integer, primary_key=True)
    usr_id: Mapped[int] = mapped_column(ForeignKey("usuario.id_usr", ondelete="CASCADE"))
    com_id: Mapped[int] = mapped_column(
        ForeignKey("comentarios.id_com", ondelete="CASCADE")
    )
    tipo: Mapped[str] = mapped_column(String(10))
    fecha: Mapped[datetime] = mapped_column(DateTime, default=ahora_utc)


class Mensaje(Base):
    __tablename__ = "mensaje"

    id_msg: Mapped[int] = mapped_column(Integer, primary_key=True)
    emisor_id: Mapped[int] = mapped_column(
        ForeignKey("usuario.id_usr", ondelete="CASCADE")
    )
    receptor_id: Mapped[int] = mapped_column(
        ForeignKey("usuario.id_usr", ondelete="CASCADE")
    )
    contenido: Mapped[str] = mapped_column(Text)
    fecha: Mapped[datetime] = mapped_column(DateTime, default=ahora_utc)
    leido: Mapped[bool] = mapped_column(Boolean, default=False)


# ----------------------------------------------------------------------
# Venta y comercio electrónico
# ----------------------------------------------------------------------
class Producto(Base):
    __tablename__ = "producto"
    __table_args__ = (
        CheckConstraint("precio > 0", name="ck_producto_precio"),
        CheckConstraint("stock >= 0", name="ck_producto_stock"),
    )

    id_prod: Mapped[int] = mapped_column(Integer, primary_key=True)
    nombre: Mapped[str] = mapped_column(String(120))
    descripcion: Mapped[str] = mapped_column(String(500))
    categoria: Mapped[str] = mapped_column(String(40))
    precio: Mapped[Decimal] = mapped_column(Numeric(10, 2))
    stock: Mapped[int] = mapped_column(Integer, default=0)
    img: Mapped[str | None] = mapped_column(String(500))
    activo: Mapped[bool] = mapped_column(Boolean, default=True)


class CarritoItem(Base):
    __tablename__ = "carrito"
    __table_args__ = (
        UniqueConstraint("usr_id", "id_prod", name="uq_carrito"),
        CheckConstraint("cantidad BETWEEN 1 AND 20", name="ck_carrito_cantidad"),
    )

    id_car: Mapped[int] = mapped_column(Integer, primary_key=True)
    usr_id: Mapped[int] = mapped_column(ForeignKey("usuario.id_usr", ondelete="CASCADE"))
    id_prod: Mapped[int] = mapped_column(ForeignKey("producto.id_prod", ondelete="CASCADE"))
    cantidad: Mapped[int] = mapped_column(Integer, default=1)

    producto: Mapped[Producto] = relationship()


class Pedido(Base):
    __tablename__ = "pedido"

    id_ped: Mapped[int] = mapped_column(Integer, primary_key=True)
    usr_id: Mapped[int] = mapped_column(
        ForeignKey("usuario.id_usr", ondelete="CASCADE"), index=True
    )
    total: Mapped[Decimal] = mapped_column(Numeric(10, 2))
    estado: Mapped[str] = mapped_column(String(20), default="pagado")
    referencia: Mapped[str] = mapped_column(String(20), unique=True)
    marca: Mapped[str] = mapped_column(String(20))
    ultimos4: Mapped[str] = mapped_column(String(4))
    fecha: Mapped[datetime] = mapped_column(DateTime, default=ahora_utc)

    detalles: Mapped[list["PedidoDetalle"]] = relationship(
        cascade="all, delete-orphan", passive_deletes=True
    )


class PedidoDetalle(Base):
    __tablename__ = "pedido_detalle"

    id_det: Mapped[int] = mapped_column(Integer, primary_key=True)
    id_ped: Mapped[int] = mapped_column(ForeignKey("pedido.id_ped", ondelete="CASCADE"))
    id_prod: Mapped[int] = mapped_column(ForeignKey("producto.id_prod"))
    nombre: Mapped[str] = mapped_column(String(120))
    cantidad: Mapped[int] = mapped_column(Integer)
    precio_unit: Mapped[Decimal] = mapped_column(Numeric(10, 2))
