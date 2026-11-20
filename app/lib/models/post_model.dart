import '../config/api_config.dart';

/// Una reseña de película publicada en el blog.
class PostModel {
  final int id;
  final String titulo;
  final String descripcion;
  final String pelicula;
  final int? anio;
  final String? genero;
  final String? img;
  final List<String> tags;
  final DateTime fecha;
  final DateTime? actualizado;
  final int autorId;
  final String autorNombre;
  final double promedio;
  final int totalValoraciones;
  final int totalComentarios;
  final int? miValoracion;
  final bool esMio;

  const PostModel({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.pelicula,
    this.anio,
    this.genero,
    this.img,
    this.tags = const [],
    required this.fecha,
    this.actualizado,
    required this.autorId,
    required this.autorNombre,
    this.promedio = 0,
    this.totalValoraciones = 0,
    this.totalComentarios = 0,
    this.miValoracion,
    this.esMio = false,
  });

  /// URL completa de la portada (o null si no tiene).
  String? get imagenUrl => ApiConfig.resolverImagen(img);

  /// Minutos aproximados de lectura (200 palabras por minuto).
  int get minutosLectura {
    final palabras = descripcion
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .length;
    final minutos = (palabras / 200).ceil();
    return minutos < 1 ? 1 : minutos;
  }

  String get peliculaConAnio => anio == null ? pelicula : '$pelicula ($anio)';

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final autor = json['autor'] as Map<String, dynamic>;
    final tagsTexto = json['tags'] as String? ?? '';
    return PostModel(
      id: (json['id_blog'] as num).toInt(),
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String? ?? '',
      pelicula: json['pelicula'] as String? ?? '',
      anio: (json['anio'] as num?)?.toInt(),
      genero: json['genero'] as String?,
      img: json['img'] as String?,
      tags: tagsTexto
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
      fecha: DateTime.parse(json['fecha'] as String).toLocal(),
      actualizado: json['actualizado'] == null
          ? null
          : DateTime.parse(json['actualizado'] as String).toLocal(),
      autorId: (autor['id_usr'] as num).toInt(),
      autorNombre: autor['nom_usr'] as String,
      promedio: (json['promedio'] as num? ?? 0).toDouble(),
      totalValoraciones: (json['total_valoraciones'] as num? ?? 0).toInt(),
      totalComentarios: (json['total_comentarios'] as num? ?? 0).toInt(),
      miValoracion: (json['mi_valoracion'] as num?)?.toInt(),
      esMio: json['es_mio'] as bool? ?? false,
    );
  }

  /// Cuerpo que se envía a la API al crear o editar.
  static Map<String, dynamic> cuerpo({
    required String titulo,
    required String descripcion,
    required String pelicula,
    int? anio,
    String? genero,
    String? img,
    String? tags,
  }) {
    return {
      'titulo': titulo.trim(),
      'descripcion': descripcion.trim(),
      'pelicula': pelicula.trim(),
      'anio': anio,
      'genero': genero,
      'img': img,
      'tags': (tags == null || tags.trim().isEmpty) ? null : tags.trim(),
    };
  }

  PostModel copyWith({
    double? promedio,
    int? totalValoraciones,
    int? totalComentarios,
    int? miValoracion,
  }) {
    return PostModel(
      id: id,
      titulo: titulo,
      descripcion: descripcion,
      pelicula: pelicula,
      anio: anio,
      genero: genero,
      img: img,
      tags: tags,
      fecha: fecha,
      actualizado: actualizado,
      autorId: autorId,
      autorNombre: autorNombre,
      promedio: promedio ?? this.promedio,
      totalValoraciones: totalValoraciones ?? this.totalValoraciones,
      totalComentarios: totalComentarios ?? this.totalComentarios,
      miValoracion: miValoracion ?? this.miValoracion,
      esMio: esMio,
    );
  }
}
