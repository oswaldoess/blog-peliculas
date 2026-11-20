import 'user_model.dart';

class MensajeModel {
  final int id;
  final int emisorId;
  final int receptorId;
  final String contenido;
  final DateTime fecha;
  final bool leido;

  const MensajeModel({
    required this.id,
    required this.emisorId,
    required this.receptorId,
    required this.contenido,
    required this.fecha,
    required this.leido,
  });

  factory MensajeModel.fromJson(Map<String, dynamic> json) {
    return MensajeModel(
      id: (json['id_msg'] as num).toInt(),
      emisorId: (json['emisor_id'] as num).toInt(),
      receptorId: (json['receptor_id'] as num).toInt(),
      contenido: json['contenido'] as String,
      fecha: DateTime.parse(json['fecha'] as String).toLocal(),
      leido: json['leido'] as bool? ?? false,
    );
  }
}

class ConversacionModel {
  final UserModel usuario;
  final String ultimoMensaje;
  final bool ultimoEsMio;
  final DateTime fecha;
  final int noLeidos;

  const ConversacionModel({
    required this.usuario,
    required this.ultimoMensaje,
    required this.ultimoEsMio,
    required this.fecha,
    required this.noLeidos,
  });

  factory ConversacionModel.fromJson(Map<String, dynamic> json) {
    return ConversacionModel(
      usuario: UserModel.fromJson(json['usuario'] as Map<String, dynamic>),
      ultimoMensaje: json['ultimo_mensaje'] as String,
      ultimoEsMio: json['ultimo_es_mio'] as bool? ?? false,
      fecha: DateTime.parse(json['fecha'] as String).toLocal(),
      noLeidos: (json['no_leidos'] as num? ?? 0).toInt(),
    );
  }
}
