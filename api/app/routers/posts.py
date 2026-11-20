"""Reseñas de películas: CRUD, filtros y valoración con estrellas."""

from fastapi import APIRouter, Depends, HTTPException, Query, Response
from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session, joinedload

from ..database import obtener_sesion
from ..deps import usuario_actual
from ..models import Blog, Comentario, Usuario, Valoracion, ahora_utc
from ..schemas import (
    AutorMini,
    PostCrear,
    PostRespuesta,
    ValoracionRequest,
    ValoracionRespuesta,
)

router = APIRouter(prefix="/posts", tags=["Reseñas"])


def _estadisticas(db: Session, ids: list[int], usr_id: int):
    """Promedio, total de valoraciones, total de comentarios y mi valoración."""
    if not ids:
        return {}, {}, {}
    valoraciones = {
        blog_id: (float(promedio or 0), int(total))
        for blog_id, promedio, total in db.execute(
            select(Valoracion.blog_id, func.avg(Valoracion.estrellas), func.count())
            .where(Valoracion.blog_id.in_(ids))
            .group_by(Valoracion.blog_id)
        )
    }
    comentarios = dict(
        db.execute(
            select(Comentario.blog_id, func.count())
            .where(Comentario.blog_id.in_(ids), Comentario.estatus == 1)
            .group_by(Comentario.blog_id)
        ).all()
    )
    mias = dict(
        db.execute(
            select(Valoracion.blog_id, Valoracion.estrellas).where(
                Valoracion.blog_id.in_(ids), Valoracion.usr_id == usr_id
            )
        ).all()
    )
    return valoraciones, comentarios, mias


def _serializar(db: Session, posts: list[Blog], usuario: Usuario) -> list[PostRespuesta]:
    valoraciones, comentarios, mias = _estadisticas(db, [p.id_blog for p in posts], usuario.id_usr)
    resultado = []
    for p in posts:
        promedio, total = valoraciones.get(p.id_blog, (0.0, 0))
        resultado.append(
            PostRespuesta(
                id_blog=p.id_blog,
                titulo=p.titulo,
                descripcion=p.descripcion,
                pelicula=p.pelicula,
                anio=p.anio,
                genero=p.genero,
                img=p.img,
                tags=p.tags,
                fecha=p.fecha,
                actualizado=p.actualizado,
                autor=AutorMini.model_validate(p.autor),
                promedio=round(promedio, 1),
                total_valoraciones=total,
                total_comentarios=int(comentarios.get(p.id_blog, 0)),
                mi_valoracion=mias.get(p.id_blog),
                es_mio=p.usr_id == usuario.id_usr,
            )
        )
    return resultado


def _obtener_o_404(db: Session, blog_id: int) -> Blog:
    post = db.get(Blog, blog_id, options=[joinedload(Blog.autor)])
    if post is None:
        raise HTTPException(404, "Reseña no encontrada")
    return post


def _validar_dueno(post: Blog, usuario: Usuario):
    if post.usr_id != usuario.id_usr and not usuario.es_admin:
        raise HTTPException(403, "Solo el autor o un administrador puede modificar esta reseña")


@router.get("", response_model=list[PostRespuesta])
def listar(
    autor_id: int | None = Query(default=None, description="Filtra por autor"),
    mios: bool = Query(default=False, description="Solo mis reseñas"),
    genero: str | None = Query(default=None, max_length=40),
    q: str | None = Query(default=None, max_length=100, description="Busca en título, película o tags"),
    usuario: Usuario = Depends(usuario_actual),
    db: Session = Depends(obtener_sesion),
):
    consulta = select(Blog).options(joinedload(Blog.autor)).order_by(Blog.fecha.desc(), Blog.id_blog.desc())
    if mios:
        consulta = consulta.where(Blog.usr_id == usuario.id_usr)
    elif autor_id is not None:
        consulta = consulta.where(Blog.usr_id == autor_id)
    if genero:
        consulta = consulta.where(Blog.genero == genero)
    if q and q.strip():
        patron = f"%{q.strip()}%"
        consulta = consulta.where(
            or_(Blog.titulo.ilike(patron), Blog.pelicula.ilike(patron), Blog.tags.ilike(patron))
        )
    posts = db.scalars(consulta).unique().all()
    return _serializar(db, list(posts), usuario)


@router.get("/generos", response_model=list[str])
def generos(_: Usuario = Depends(usuario_actual), db: Session = Depends(obtener_sesion)):
    """Géneros que ya tienen reseñas (para los filtros de la app)."""
    filas = db.scalars(
        select(Blog.genero).where(Blog.genero.is_not(None)).distinct().order_by(Blog.genero)
    ).all()
    return [g for g in filas if g]


@router.get("/{blog_id}", response_model=PostRespuesta)
def detalle(blog_id: int, usuario: Usuario = Depends(usuario_actual), db: Session = Depends(obtener_sesion)):
    return _serializar(db, [_obtener_o_404(db, blog_id)], usuario)[0]


@router.post("", response_model=PostRespuesta, status_code=201)
def crear(datos: PostCrear, usuario: Usuario = Depends(usuario_actual), db: Session = Depends(obtener_sesion)):
    post = Blog(
        titulo=datos.titulo.strip(),
        descripcion=datos.descripcion.strip(),
        pelicula=datos.pelicula.strip(),
        anio=datos.anio,
        genero=datos.genero,
        img=datos.img,
        tags=datos.tags,
        usr_id=usuario.id_usr,  # el autor sale del token, no del JSON
    )
    db.add(post)
    db.commit()
    return _serializar(db, [_obtener_o_404(db, post.id_blog)], usuario)[0]


@router.put("/{blog_id}", response_model=PostRespuesta)
def editar(
    blog_id: int,
    datos: PostCrear,
    usuario: Usuario = Depends(usuario_actual),
    db: Session = Depends(obtener_sesion),
):
    post = _obtener_o_404(db, blog_id)
    _validar_dueno(post, usuario)
    post.titulo = datos.titulo.strip()
    post.descripcion = datos.descripcion.strip()
    post.pelicula = datos.pelicula.strip()
    post.anio = datos.anio
    post.genero = datos.genero
    post.img = datos.img
    post.tags = datos.tags
    post.actualizado = ahora_utc()
    db.commit()
    return _serializar(db, [_obtener_o_404(db, blog_id)], usuario)[0]


@router.delete("/{blog_id}", status_code=204)
def eliminar(blog_id: int, usuario: Usuario = Depends(usuario_actual), db: Session = Depends(obtener_sesion)):
    post = _obtener_o_404(db, blog_id)
    _validar_dueno(post, usuario)
    db.delete(post)
    db.commit()
    return Response(status_code=204)


@router.put("/{blog_id}/valoracion", response_model=ValoracionRespuesta)
def valorar(
    blog_id: int,
    datos: ValoracionRequest,
    usuario: Usuario = Depends(usuario_actual),
    db: Session = Depends(obtener_sesion),
):
    """Crea o actualiza la valoración (1–5 estrellas) del usuario."""
    post = _obtener_o_404(db, blog_id)
    if post.usr_id == usuario.id_usr:
        raise HTTPException(400, "No puedes calificar tu propia reseña")

    valoracion = db.scalar(
        select(Valoracion).where(Valoracion.blog_id == blog_id, Valoracion.usr_id == usuario.id_usr)
    )
    if valoracion is None:
        db.add(Valoracion(blog_id=blog_id, usr_id=usuario.id_usr, estrellas=datos.estrellas))
    else:
        valoracion.estrellas = datos.estrellas
        valoracion.fecha = ahora_utc()
    db.commit()

    valoraciones, _, mias = _estadisticas(db, [blog_id], usuario.id_usr)
    promedio, total = valoraciones.get(blog_id, (0.0, 0))
    return ValoracionRespuesta(
        promedio=round(promedio, 1), total_valoraciones=total, mi_valoracion=mias.get(blog_id)
    )
