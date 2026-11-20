/// Reacciones disponibles. La API guarda el código y la app pinta el emoji.
class Reacciones {
  Reacciones._();

  static const Map<String, String> emojis = {
    'like': '👍',
    'love': '❤️',
    'haha': '😂',
    'wow': '😮',
    'fire': '🔥',
    'clap': '👏',
  };

  static String emoji(String tipo) => emojis[tipo] ?? '👍';
}

class ReaccionResumen {
  final String tipo;
  final int total;
  final bool mia;

  const ReaccionResumen({
    required this.tipo,
    required this.total,
    required this.mia,
  });

  factory ReaccionResumen.fromJson(Map<String, dynamic> json) {
    return ReaccionResumen(
      tipo: json['tipo'] as String,
      total: (json['total'] as num).toInt(),
      mia: json['mia'] as bool? ?? false,
    );
  }
}

class ComentarioModel {
  final int id;
  final String comentario;
  final DateTime fecha;
  final int blogId;
  final int autorId;
  final String autorNombre;
  final List<ReaccionResumen> reacciones;
  final bool puedeBorrar;

  const ComentarioModel({
    required this.id,
    required this.comentario,
    required this.fecha,
    required this.blogId,
    required this.autorId,
    required this.autorNombre,
    this.reacciones = const [],
    this.puedeBorrar = false,
  });

  factory ComentarioModel.fromJson(Map<String, dynamic> json) {
    final autor = json['autor'] as Map<String, dynamic>;
    final lista = json['reacciones'] as List<dynamic>? ?? const [];
    return ComentarioModel(
      id: (json['id_com'] as num).toInt(),
      comentario: json['comentario'] as String,
      fecha: DateTime.parse(json['fecha'] as String).toLocal(),
      blogId: (json['blog_id'] as num).toInt(),
      autorId: (autor['id_usr'] as num).toInt(),
      autorNombre: autor['nom_usr'] as String,
      reacciones: lista
          .map((r) => ReaccionResumen.fromJson(r as Map<String, dynamic>))
          .toList(),
      puedeBorrar: json['puede_borrar'] as bool? ?? false,
    );
  }

  ComentarioModel conReacciones(List<ReaccionResumen> nuevas) {
    return ComentarioModel(
      id: id,
      comentario: comentario,
      fecha: fecha,
      blogId: blogId,
      autorId: autorId,
      autorNombre: autorNombre,
      reacciones: nuevas,
      puedeBorrar: puedeBorrar,
    );
  }
}
