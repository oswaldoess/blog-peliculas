import '../core/api_client.dart';
import '../models/mensaje_model.dart';
import '../models/user_model.dart';

class MensajeService {
  final ApiClient _api = ApiClient.instance;

  Future<List<ConversacionModel>> obtenerConversaciones() async {
    final datos = await _api.get('/mensajes/conversaciones') as List<dynamic>;
    return datos
        .map((j) => ConversacionModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<int> contarNoLeidos() async {
    final datos = await _api.get('/mensajes/no-leidos');
    return (datos as num).toInt();
  }

  /// Mensajes con otro usuario. [despuesDe] trae solo los nuevos.
  Future<List<MensajeModel>> obtenerChat(int otroId, {int despuesDe = 0}) async {
    final datos = await _api.get(
      '/mensajes/$otroId',
      query: {'despues_de': '$despuesDe'},
    ) as List<dynamic>;
    return datos
        .map((j) => MensajeModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<MensajeModel> enviar(int otroId, String texto) async {
    final datos = await _api.post(
      '/mensajes/$otroId',
      body: {'contenido': texto.trim()},
    );
    return MensajeModel.fromJson(datos as Map<String, dynamic>);
  }

  Future<List<UserModel>> directorio() async {
    final datos = await _api.get('/usuarios/directorio') as List<dynamic>;
    return datos
        .map((j) => UserModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }
}
