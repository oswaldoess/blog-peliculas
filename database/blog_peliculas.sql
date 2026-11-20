-- =====================================================================
--  BLOG DE RESEÑAS DE PELÍCULAS · Script de creación de la BD (MySQL 8.0+)
--  Evaluación Unidad 3 – Caso práctico: Diseño de blog
--
--  Ejecutar completo desde MySQL Workbench o con:
--      mysql -u root -p < database/blog_peliculas.sql
--
--  ⚠ El script borra y vuelve a crear la base `blog_peliculas`
--    (no toca ninguna otra base de datos).
--
--  Usuarios de prueba (contraseña de todos: Peliculas2026)
--      admin@cine.test   → Administrador
--      sofia@cine.test   → Autor
--      carlos@cine.test  → Autor
--      andrea@cine.test  → Autor
-- =====================================================================

-- Garantiza que acentos y ñ se guarden bien sin importar el cliente.
SET NAMES utf8mb4;

DROP DATABASE IF EXISTS blog_peliculas;

CREATE DATABASE blog_peliculas
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;

USE blog_peliculas;

-- ---------------------------------------------------------------------
--  Catálogo de roles
-- ---------------------------------------------------------------------
CREATE TABLE tipo_usuario (
    id_tipo     TINYINT      NOT NULL PRIMARY KEY,
    nombre      VARCHAR(30)  NOT NULL UNIQUE,
    descripcion VARCHAR(150) NOT NULL
);

-- ---------------------------------------------------------------------
--  Usuarios
--  · pass guarda SOLO el hash Argon2id (nunca la contraseña en claro)
--  · intentos_fallidos / bloqueado_hasta → protección contra fuerza bruta
-- ---------------------------------------------------------------------
CREATE TABLE usuario (
    id_usr            INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nom_usr           VARCHAR(100) NOT NULL,
    mail              VARCHAR(150) NOT NULL,
    pass              VARCHAR(255) NOT NULL,
    dir_usr           VARCHAR(200) NULL,
    bio               VARCHAR(280) NULL,
    tip_usu           TINYINT      NOT NULL DEFAULT 2,
    activo            TINYINT(1)   NOT NULL DEFAULT 1,
    intentos_fallidos INT          NOT NULL DEFAULT 0,
    bloqueado_hasta   DATETIME     NULL,
    creado_en         DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_usuario_mail UNIQUE (mail),
    CONSTRAINT fk_usuario_tipo FOREIGN KEY (tip_usu)
        REFERENCES tipo_usuario (id_tipo)
);

-- ---------------------------------------------------------------------
--  Sesiones (cada JWT emitido tiene un registro; logout = revocada)
-- ---------------------------------------------------------------------
CREATE TABLE sesion (
    id_sesion INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    jti       CHAR(36)     NOT NULL,
    usr_id    INT          NOT NULL,
    creada    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expira    DATETIME     NOT NULL,
    revocada  TINYINT(1)   NOT NULL DEFAULT 0,
    agente    VARCHAR(255) NULL,

    CONSTRAINT uq_sesion_jti UNIQUE (jti),
    CONSTRAINT fk_sesion_usuario FOREIGN KEY (usr_id)
        REFERENCES usuario (id_usr) ON DELETE CASCADE,
    INDEX ix_sesion_usuario (usr_id)
);

-- ---------------------------------------------------------------------
--  Publicaciones del blog (cada una es la reseña de una película)
-- ---------------------------------------------------------------------
CREATE TABLE blog (
    id_blog     INT          NOT NULL AUTO_INCREMENT PRIMARY KEY,
    titulo      VARCHAR(150) NOT NULL,
    descripcion TEXT         NOT NULL,
    img         VARCHAR(500) NULL,
    tags        VARCHAR(255) NULL,
    pelicula    VARCHAR(150) NOT NULL,         -- película reseñada
    anio        SMALLINT     NULL,             -- año de estreno
    genero      VARCHAR(40)  NULL,
    usr_id      INT          NOT NULL,
    fecha       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado DATETIME     NULL,

    CONSTRAINT ck_blog_anio CHECK (anio IS NULL OR anio BETWEEN 1888 AND 2100),
    CONSTRAINT fk_blog_usuario FOREIGN KEY (usr_id)
        REFERENCES usuario (id_usr) ON DELETE CASCADE,
    INDEX ix_blog_usuario (usr_id),
    INDEX ix_blog_fecha (fecha),
    INDEX ix_blog_genero (genero)
);

-- ---------------------------------------------------------------------
--  Comentarios
-- ---------------------------------------------------------------------
CREATE TABLE comentarios (
    id_com     INT        NOT NULL AUTO_INCREMENT PRIMARY KEY,
    comentario TEXT       NOT NULL,
    fecha      DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estatus    TINYINT    NOT NULL DEFAULT 1,
    usr_id     INT        NOT NULL,
    blog_id    INT        NOT NULL,

    CONSTRAINT fk_comentario_usuario FOREIGN KEY (usr_id)
        REFERENCES usuario (id_usr) ON DELETE CASCADE,
    CONSTRAINT fk_comentario_blog FOREIGN KEY (blog_id)
        REFERENCES blog (id_blog) ON DELETE CASCADE,
    INDEX ix_comentario_blog (blog_id)
);

-- ---------------------------------------------------------------------
--  [Opcional] Sistema de valoración: 1 a 5 estrellas por usuario/post
-- ---------------------------------------------------------------------
CREATE TABLE valoracion (
    id_val    INT       NOT NULL AUTO_INCREMENT PRIMARY KEY,
    usr_id    INT       NOT NULL,
    blog_id   INT       NOT NULL,
    estrellas TINYINT   NOT NULL,
    fecha     DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_valoracion UNIQUE (usr_id, blog_id),
    CONSTRAINT ck_valoracion_rango CHECK (estrellas BETWEEN 1 AND 5),
    CONSTRAINT fk_valoracion_usuario FOREIGN KEY (usr_id)
        REFERENCES usuario (id_usr) ON DELETE CASCADE,
    CONSTRAINT fk_valoracion_blog FOREIGN KEY (blog_id)
        REFERENCES blog (id_blog) ON DELETE CASCADE
);

-- ---------------------------------------------------------------------
--  [Opcional] Comentarios interactivos: reacciones con emoji.
--  Se guarda un código (like, love, haha...) y la app lo pinta como emoji;
--  así no dependemos de la collation para comparar emojis.
-- ---------------------------------------------------------------------
CREATE TABLE reaccion (
    id_reac INT         NOT NULL AUTO_INCREMENT PRIMARY KEY,
    usr_id  INT         NOT NULL,
    com_id  INT         NOT NULL,
    tipo    VARCHAR(10) NOT NULL,
    fecha   DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_reaccion UNIQUE (usr_id, com_id, tipo),
    CONSTRAINT ck_reaccion_tipo
        CHECK (tipo IN ('like', 'love', 'haha', 'wow', 'fire', 'clap')),
    CONSTRAINT fk_reaccion_usuario FOREIGN KEY (usr_id)
        REFERENCES usuario (id_usr) ON DELETE CASCADE,
    CONSTRAINT fk_reaccion_comentario FOREIGN KEY (com_id)
        REFERENCES comentarios (id_com) ON DELETE CASCADE
);

-- ---------------------------------------------------------------------
--  [Opcional] Mensajería interna (chat privado 1 a 1)
-- ---------------------------------------------------------------------
CREATE TABLE mensaje (
    id_msg      INT        NOT NULL AUTO_INCREMENT PRIMARY KEY,
    emisor_id   INT        NOT NULL,
    receptor_id INT        NOT NULL,
    contenido   TEXT       NOT NULL,
    fecha       DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    leido       TINYINT(1) NOT NULL DEFAULT 0,

    CONSTRAINT fk_mensaje_emisor FOREIGN KEY (emisor_id)
        REFERENCES usuario (id_usr) ON DELETE CASCADE,
    CONSTRAINT fk_mensaje_receptor FOREIGN KEY (receptor_id)
        REFERENCES usuario (id_usr) ON DELETE CASCADE,
    INDEX ix_mensaje_conversacion (emisor_id, receptor_id),
    INDEX ix_mensaje_no_leidos (receptor_id, leido)
);

-- ---------------------------------------------------------------------
--  [Opcional] Venta y comercio electrónico: catálogo, carrito y pedidos
-- ---------------------------------------------------------------------
CREATE TABLE producto (
    id_prod     INT           NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nombre      VARCHAR(120)  NOT NULL,
    descripcion VARCHAR(500)  NOT NULL,
    categoria   VARCHAR(40)   NOT NULL,
    precio      DECIMAL(10,2) NOT NULL,
    stock       INT           NOT NULL DEFAULT 0,
    img         VARCHAR(500)  NULL,
    activo      TINYINT(1)    NOT NULL DEFAULT 1,

    CONSTRAINT ck_producto_precio CHECK (precio > 0),
    CONSTRAINT ck_producto_stock CHECK (stock >= 0)
);

CREATE TABLE carrito (
    id_car   INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    usr_id   INT NOT NULL,
    id_prod  INT NOT NULL,
    cantidad INT NOT NULL DEFAULT 1,

    CONSTRAINT uq_carrito UNIQUE (usr_id, id_prod),
    CONSTRAINT ck_carrito_cantidad CHECK (cantidad BETWEEN 1 AND 20),
    CONSTRAINT fk_carrito_usuario FOREIGN KEY (usr_id)
        REFERENCES usuario (id_usr) ON DELETE CASCADE,
    CONSTRAINT fk_carrito_producto FOREIGN KEY (id_prod)
        REFERENCES producto (id_prod) ON DELETE CASCADE
);

-- Del pago solo se guardan la marca y los últimos 4 dígitos de la tarjeta
-- (nunca el número completo ni el CVV).
CREATE TABLE pedido (
    id_ped     INT           NOT NULL AUTO_INCREMENT PRIMARY KEY,
    usr_id     INT           NOT NULL,
    total      DECIMAL(10,2) NOT NULL,
    estado     VARCHAR(20)   NOT NULL DEFAULT 'pagado',
    referencia VARCHAR(20)   NOT NULL,
    marca      VARCHAR(20)   NOT NULL,
    ultimos4   CHAR(4)       NOT NULL,
    fecha      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_pedido_referencia UNIQUE (referencia),
    CONSTRAINT fk_pedido_usuario FOREIGN KEY (usr_id)
        REFERENCES usuario (id_usr) ON DELETE CASCADE,
    INDEX ix_pedido_usuario (usr_id)
);

CREATE TABLE pedido_detalle (
    id_det      INT           NOT NULL AUTO_INCREMENT PRIMARY KEY,
    id_ped      INT           NOT NULL,
    id_prod     INT           NOT NULL,
    nombre      VARCHAR(120)  NOT NULL,   -- copia del nombre al momento de la compra
    cantidad    INT           NOT NULL,
    precio_unit DECIMAL(10,2) NOT NULL,   -- copia del precio al momento de la compra

    CONSTRAINT fk_detalle_pedido FOREIGN KEY (id_ped)
        REFERENCES pedido (id_ped) ON DELETE CASCADE,
    CONSTRAINT fk_detalle_producto FOREIGN KEY (id_prod)
        REFERENCES producto (id_prod)
);

-- =====================================================================
--  DATOS DE PRUEBA
--  Las fechas se guardan en UTC (la API también trabaja en UTC).
--  Las reseñas iniciales no traen imagen: la app muestra un recuadro
--  con el color del género. Al publicar se puede poner una URL de imagen.
-- =====================================================================

INSERT INTO tipo_usuario (id_tipo, nombre, descripcion) VALUES
    (1, 'Administrador', 'Gestiona usuarios y puede moderar cualquier reseña'),
    (2, 'Autor',         'Publica reseñas, comenta, valora y envía mensajes');

-- Hashes Argon2id de la contraseña "Peliculas2026"
INSERT INTO usuario (nom_usr, mail, pass, dir_usr, bio, tip_usu, creado_en) VALUES
    ('Administrador', 'admin@cine.test',
     '$argon2id$v=19$m=65536,t=3,p=4$tEIb2p7H9fUPwqO9S9OOqQ$DZ+CFlZuN2p9obORxw9qllJiKb7kFRtED65i8b0ifl0',
     'Ciudad de México', 'Modera las reseñas y mantiene el orden en la sala.', 1,
     UTC_TIMESTAMP() - INTERVAL 30 DAY),
    ('Sofía Navarro', 'sofia@cine.test',
     '$argon2id$v=19$m=65536,t=3,p=4$XBR7tHXWNjvEx9nLrGGk+w$g7KDM189KOV5n2GTN7EClYpkEz1Uy9fYuc938LbaaV4',
     'Puebla, Pue.', 'Drama, animación y todo lo que me haga llorar.', 2,
     UTC_TIMESTAMP() - INTERVAL 20 DAY),
    ('Carlos Herrera', 'carlos@cine.test',
     '$argon2id$v=19$m=65536,t=3,p=4$Aor0zQKQizrvlbhZg0G8jw$fv2iyqZOtwR6DlA7GT1w/rI7G2mmGENP3hcaNC11uCQ',
     'Guadalajara, Jal.', 'Ciencia ficción o nada. Palomitas con chile.', 2,
     UTC_TIMESTAMP() - INTERVAL 15 DAY),
    ('Andrea Ruiz', 'andrea@cine.test',
     '$argon2id$v=19$m=65536,t=3,p=4$v1Z/1Y5HdhtbiEQXMnq7WQ$G/dS64jLzo20EeLIG+Rc5bCUYacuV5cv+2yD7vWuugE',
     'Monterrey, N.L.', 'Terror y suspenso. Veo los créditos hasta el final.', 2,
     UTC_TIMESTAMP() - INTERVAL 10 DAY);

INSERT INTO blog (titulo, descripcion, img, tags, pelicula, anio, genero, usr_id, fecha) VALUES
    ('Un viaje al Día de Muertos que no esperaba que me pegara tanto',
     'Fui pensando que era "otra de Pixar" y salí con los ojos rojos. La película convierte una tradición que conocemos de toda la vida en una aventura llena de color, y lo hace con muchísimo respeto: los altares, el cempasúchil y la música se sienten auténticos.\n\nLo mejor: el tema de la memoria. La idea de que alguien desaparece cuando ya nadie lo recuerda está contada de forma sencilla para niños, pero a los adultos nos llega directo.\n\nLo que menos me gustó: el villano se ve venir desde lejos. Aun así, es de esas que puedes ver en familia cada noviembre.',
     NULL, 'Familia,Música,México', 'Coco', 2017, 'Animación', 2, UTC_TIMESTAMP() - INTERVAL 9 DAY),
    ('Interestelar: ciencia dura con corazón',
     'Pocas películas de ciencia ficción se toman tan en serio la física y al mismo tiempo te hacen sentir tanto. La escena del planeta del agua, donde cada hora equivale a años en la Tierra, es de lo más tenso que he visto en una sala.\n\nLa música de órgano es protagonista: verla en pantalla grande con buen sonido es otra experiencia.\n\nEl tercer acto se vuelve muy abstracto y entiendo a quien se pierde ahí, pero para mí cierra perfecto la historia de un padre y una hija separados por el tiempo.',
     NULL, 'Espacio,Clásico moderno', 'Interestelar', 2014, 'Ciencia ficción', 3, UTC_TIMESTAMP() - INTERVAL 7 DAY),
    ('El laberinto del fauno sigue siendo una joya',
     'La volví a ver casi veinte años después y sigue funcionando igual o mejor. Mezcla un cuento de hadas oscuro con la posguerra española, y lo increíble es que las dos historias se alimentan una a la otra.\n\nEl diseño de las criaturas es hecho a mano, con maquillaje y prótesis, y por eso no ha envejecido nada. La escena del Hombre Pálido todavía da escalofríos.\n\nAviso: no es para niños aunque tenga un fauno. Es violenta y triste, pero preciosa.',
     NULL, 'Fantasía oscura,Cine mexicano', 'El laberinto del fauno', 2006, 'Fantasía', 4, UTC_TIMESTAMP() - INTERVAL 5 DAY),
    ('Parásitos: la casa como campo de batalla',
     'Empieza como comedia de enredos, se vuelve thriller y termina en tragedia, y todos los cambios de tono se sienten naturales. Cada escalera y cada ventana de la casa significan algo: arriba los que tienen, abajo los que no.\n\nNo cuento más porque la gracia es verla sin saber nada. Si no la has visto, apágale al celular y dale.',
     NULL, 'Thriller,Crítica social', 'Parásitos', 2019, 'Suspenso', 1, UTC_TIMESTAMP() - INTERVAL 3 DAY),
    ('Roma: la película que hay que ver con calma',
     'No es una película de ritmo rápido y no pretende serlo. Es un retrato de una familia de la Ciudad de México a inicios de los setenta contado desde los ojos de la trabajadora del hogar, y el blanco y negro le da un aire de recuerdo.\n\nLa escena en la playa es de las más intensas del cine mexicano reciente. Recomendación: véanla sin distracciones y con buen audio, el sonido de la ciudad es otro personaje.',
     NULL, 'Cine mexicano,Drama', 'Roma', 2018, 'Drama', 2, UTC_TIMESTAMP() - INTERVAL 1 DAY),
    ('Mi primera reseña de terror: El conjuro',
     'Le tengo miedo a todo y aun así la terminé. Lo que la hace funcionar no son los sustos fáciles sino que te importa la familia. Los ruidos en la casa y el juego de las palmadas me tuvieron con la cobija hasta la nariz.\n\n¿Me recomiendan otra para seguir practicando?',
     NULL, 'Terror,Casas embrujadas', 'El conjuro', 2013, 'Terror', 4, UTC_TIMESTAMP() - INTERVAL 8 HOUR);

INSERT INTO comentarios (comentario, usr_id, blog_id, fecha) VALUES
    ('Yo también lloré con la escena final, no hay forma de evitarlo.', 4, 1, UTC_TIMESTAMP() - INTERVAL 8 DAY),
    ('¿Ya viste la versión doblada? Las canciones en español quedan muy bien.', 3, 1, UTC_TIMESTAMP() - INTERVAL 8 DAY),
    ('El planeta del agua me dejó sin aire, coincido totalmente.', 2, 2, UTC_TIMESTAMP() - INTERVAL 6 DAY),
    ('Para mí el final sí fue demasiado, pero el resto es perfecto.', 1, 2, UTC_TIMESTAMP() - INTERVAL 6 DAY),
    ('El Hombre Pálido me sigue dando pesadillas jaja', 3, 3, UTC_TIMESTAMP() - INTERVAL 4 DAY),
    ('Completamente de acuerdo, hay que verla sin spoilers.', 4, 4, UTC_TIMESTAMP() - INTERVAL 2 DAY),
    ('Te recomiendo Un lugar en silencio, la vas a sufrir bonito.', 3, 6, UTC_TIMESTAMP() - INTERVAL 5 HOUR);

INSERT INTO valoracion (usr_id, blog_id, estrellas) VALUES
    (3, 1, 5), (4, 1, 5), (1, 1, 4),
    (2, 2, 5), (1, 2, 4),
    (2, 3, 5), (3, 3, 5),
    (4, 4, 5), (3, 4, 4),
    (3, 5, 4), (4, 5, 3),
    (2, 6, 4);

INSERT INTO reaccion (usr_id, com_id, tipo) VALUES
    (2, 1, 'love'), (3, 1, 'like'),
    (2, 2, 'like'),
    (3, 3, 'fire'), (4, 3, 'wow'),
    (2, 5, 'haha'), (4, 5, 'haha'),
    (1, 6, 'clap'),
    (4, 7, 'like');

INSERT INTO mensaje (emisor_id, receptor_id, contenido, fecha, leido) VALUES
    (3, 2, '¡Hola Sofía! Vi tu reseña de Coco, ¿qué otra animada me recomiendas?', UTC_TIMESTAMP() - INTERVAL 3 HOUR, 1),
    (2, 3, 'Si no has visto El viaje de Chihiro, esa. Te va a encantar.',          UTC_TIMESTAMP() - INTERVAL 2 HOUR, 1),
    (3, 2, 'Va, la veo este fin. ¡Gracias!',                                        UTC_TIMESTAMP() - INTERVAL 30 MINUTE, 0),
    (4, 2, '¿Hacemos maratón de terror el viernes?',                               UTC_TIMESTAMP() - INTERVAL 10 MINUTE, 0);

INSERT INTO producto (nombre, descripcion, categoria, precio, stock) VALUES
    ('Taza claqueta',            'Taza de cerámica de 350 ml con diseño de claqueta de cine.',            'Accesorios', 189.00, 25),
    ('Playera "Fan del cine"',    'Playera de algodón unisex, estampado de rollo de película.',            'Ropa',       349.00, 15),
    ('Cubeta de palomitas',      'Cubeta reutilizable para tus maratones en casa (2 litros).',            'Accesorios', 149.00, 30),
    ('Tarjeta de regalo $200',   'Tarjeta digital para regalar boletos o dulcería.',                       'Regalos',    200.00, 100),
    ('Lámpara de claqueta',      'Lámpara LED de escritorio con forma de claqueta.',                      'Decoración', 459.00, 8),
    ('Llavero rollo de película','Llavero metálico con forma de rollo de película de 35 mm.',             'Accesorios',  79.00, 50),
    ('Cuaderno de reseñas',      'Libreta para anotar las películas que ves y calificarlas.',             'Papelería',  129.00, 20),
    ('Sudadera "Modo maratón"',   'Sudadera con capucha para ver películas toda la noche.',                'Ropa',       599.00, 0);

INSERT INTO pedido (usr_id, total, estado, referencia, marca, ultimos4, fecha) VALUES
    (3, 338.00, 'pagado', 'PAG-7F3A91C2', 'Visa', '4242', UTC_TIMESTAMP() - INTERVAL 2 DAY);

INSERT INTO pedido_detalle (id_ped, id_prod, nombre, cantidad, precio_unit) VALUES
    (1, 1, 'Taza claqueta', 1, 189.00),
    (1, 3, 'Cubeta de palomitas', 1, 149.00);

INSERT INTO carrito (usr_id, id_prod, cantidad) VALUES
    (2, 2, 1), (2, 6, 2);
