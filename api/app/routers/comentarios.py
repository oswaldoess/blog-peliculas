"""Comentarios de las reseñas y reacciones con emoji."""

from collections import defaultdict

from fastapi import APIRouter, Depends, HTTPException, Response
from sqlalchemy import select
from sqlalchemy.orm import Session, joinedload

from ..database import obtener_sesion
from ..deps import usuario_actual
from ..models import TIPOS_REACCION, Blog, Comentario, Reaccion, Usuario
from ..schemas import (
    AutorMini,
    ComentarioCrear,
    ComentarioRespuesta,
    ReaccionRequest,
    ReaccionResumen,
)

router = APIRouter(tags=["Comentarios"])


def _resumen_reacciones(db: Session, ids: list[int], usr_id: int) -> dict[int, list[ReaccionResumen]]:
    conteo: dict[int, dict[str, int]] = defaultdict(lambda: defaultdict(int))
    mias: set[tuple[int, str]] = set()
    if ids:
        for com_id, tipo, autor in db.execute(
            select(Reaccion.com_id, Reaccion.tipo, Reaccion.usr_id).where(Reaccion.com_id.in_(ids))
        ):
            conteo[com_id][tipo] += 1
            if autor == usr_id:
                mias.add((com_id, tipo))
    return {
        com_id: [
            ReaccionResumen(tipo=t, total=conteo[com_id][t], mia=(com_id, t) in mias)
            for t in TIPOS_REACCION  # orden fijo para que la app no "salte"
            if conteo[com_id].get(t)
        ]
        for com_id in ids
    }


def _serializar(db: Session, comentarios: list[Comentario], usuario: Usuario) -> list[ComentarioRespuesta]:
    reacciones = _resumen_reacciones(db, [c.id_com for c in comentarios], usuario.id_usr)
    return [
        ComentarioRespuesta(
            id_com=c.id_com,
            comentario=c.comentario,
            fecha=c.fecha,
            blog_id=c.blog_id,
            autor=AutorMini.model_validate(c.autor),
            reacciones=reacciones.get(c.id_com, []),
            # Puede borrar: quien lo escribió, el autor de la reseña o un admin.
            puede_borrar=(
                c.usr_id == usuario.id_usr
                or c.publicacion.usr_id == usuario.id_usr
                or usuario.es_admin
            ),
        )
        for c in comentarios
    ]


def _comentario_o_404(db: Session, com_id: int) -> Comentario:
    comentario = db.get(
        Comentario,
        com_id,
        options=[joinedload(Comentario.autor), joinedload(Comentario.publicacion)],
    )
    if comentario is None or comentario.estatus != 1:
        raise HTTPException(404, "Comentario no encontrado")
    return comentario


@router.get("/posts/{blog_id}/comentarios", response_model=list[ComentarioRespuesta])
def listar(blog_id: int, usuario: Usuario = Depends(usuario_actual), db: Session = Depends(obtener_sesion)):
    if db.get(Blog, blog_id) is None:
        raise HTTPException(404, "Reseña no encontrada")
    comentarios = db.scalars(
        select(Comentario)
        .options(joinedload(Comentario.autor), joinedload(Comentario.publicacion))
        .where(Comentario.blog_id == blog_id, Comentario.estatus == 1)
        .order_by(Comentario.fecha, Comentario.id_com)
    ).all()
    return _serializar(db, list(comentarios), usuario)


@router.post("/posts/{blog_id}/comentarios", response_model=ComentarioRespuesta, status_code=201)
def crear(
    blog_id: int,
    datos: ComentarioCrear,
    usuario: Usuario = Depends(usuario_actual),
    db: Session = Depends(obtener_sesion),
):
    texto = datos.comentario.strip()
    if not texto:
        raise HTTPException(422, "El comentario no puede estar vacío")
    if db.get(Blog, blog_id) is None:
        raise HTTPException(404, "Reseña no encontrada")

    nuevo = Comentario(comentario=texto, usr_id=usuario.id_usr, blog_id=blog_id, estatus=1)
    db.add(nuevo)
    db.commit()
    return _serializar(db, [_comentario_o_404(db, nuevo.id_com)], usuario)[0]


@router.delete("/comentarios/{com_id}", status_code=204)
def eliminar(com_id: int, usuario: Usuario = Depends(usuario_actual), db: Session = Depends(obtener_sesion)):
    comentario = _comentario_o_404(db, com_id)
    permitido = (
        comentario.usr_id == usuario.id_usr
        or comentario.publicacion.usr_id == usuario.id_usr
        or usuario.es_admin
    )
    if not permitido:
        raise HTTPException(403, "No puedes borrar este comentario")
    db.delete(comentario)
    db.commit()
    return Response(status_code=204)


@router.post("/comentarios/{com_id}/reacciones", response_model=list[ReaccionResumen])
def reaccionar(
    com_id: int,
    datos: ReaccionRequest,
    usuario: Usuario = Depends(usuario_actual),
    db: Session = Depends(obtener_sesion),
):
    """Alterna (pone / quita) la reacción del usuario en el comentario."""
    _comentario_o_404(db, com_id)
    existente = db.scalar(
        select(Reaccion).where(
            Reaccion.com_id == com_id,
            Reaccion.usr_id == usuario.id_usr,
            Reaccion.tipo == datos.tipo,
        )
    )
    if existente is None:
        db.add(Reaccion(com_id=com_id, usr_id=usuario.id_usr, tipo=datos.tipo))
    else:
        db.delete(existente)
    db.commit()
    return _resumen_reacciones(db, [com_id], usuario.id_usr)[com_id]
