# Guion del video de demostración (6–7 min)

Antes de grabar: corre otra vez el script SQL para tener los datos limpios, levanta la API y abre la app. Graba la pantalla **con la app y, a un lado, MySQL Workbench**, para que se vea que los datos sí llegan a la base.

| # | Tiempo | Qué mostrar | Qué decir (idea) |
|---|---|---|---|
| 1 | 0:00 | Repositorio en GitHub (modo incógnito) con `database/`, `api/`, `app/` | "Este es el repositorio público con la BD, la API y la app." |
| 2 | 0:20 | Terminal con `uvicorn` y `http://127.0.0.1:8000/docs` | "La API está en FastAPI; aquí están todos los endpoints." |
| 3 | 0:40 | **Registro** con una contraseña débil (requisitos en gris) y luego una válida | "La contraseña se valida en la app y en la API." |
| 4 | 1:05 | Workbench: `SELECT id_usr, mail, pass FROM usuario;` | "La contraseña se guarda como hash Argon2id, nunca en texto." |
| 5 | 1:25 | Cerrar sesión e intentar entrar 5 veces con contraseña mala | "Después de 5 intentos la cuenta se bloquea 5 minutos." |
| 6 | 1:45 | Entrar con `sofia@cine.test` / `Peliculas2026` | |
| 7 | 1:55 | Reseñas: chips **Todas** / **Mis reseñas** y filtro por género | "Se ven las reseñas propias y las de otros usuarios." |
| 8 | 2:20 | **Nueva reseña** (con URL de imagen) → guardar | |
| 9 | 2:40 | Workbench: `SELECT * FROM blog ORDER BY id_blog DESC LIMIT 1;` | "Aquí está la reseña con su autor." |
| 10 | 2:55 | Abrir la reseña de otra persona → calificar con **estrellas** | "Módulo de valoración: cambia el promedio y los votos." |
| 11 | 3:15 | Escribir un **comentario** y ponerle **reacciones** 🔥😂 | "Comentarios interactivos con emoji." |
| 12 | 3:40 | **Tienda**: filtrar categoría, agregar productos (se ve el globito del carrito) | "Módulo de comercio electrónico: catálogo y carrito." |
| 13 | 4:05 | **Carrito**: subir/bajar cantidades → **Proceder al pago** | |
| 14 | 4:20 | Pago con `4000 0000 0000 0002` → rechazado; luego `4242 4242 4242 4242`, `12/30`, `123` → aprobado con folio | "La pasarela es simulada: valida la tarjeta y solo guarda los últimos 4 dígitos." |
| 15 | 4:50 | Workbench: `SELECT * FROM pedido;` y `SELECT nombre, stock FROM producto;` | "Se creó el pedido y bajó el stock." |
| 16 | 5:10 | Botón de mensaje al autor → **chat**. Ideal: otra ventana de Chrome en incógnito con `carlos@cine.test` para que se vea llegar el mensaje | "Mensajería interna entre usuarios registrados." |
| 17 | 5:50 | Entrar como `admin@cine.test` → Perfil → **Panel de administración** | "Solo el administrador ve esto; la API responde 403 a cualquier otro." |
| 18 | 6:15 | Cerrar sesión y en Workbench: `SELECT id_sesion, usr_id, revocada FROM sesion;` | "Al cerrar sesión el token queda revocado en la base." |
| 19 | 6:35 | Cierre | "Flutter + FastAPI + MySQL con sesiones seguras y los cuatro módulos opcionales." |

Tip: graba en resolución alta y haz zoom en Workbench para que se lean los datos.
