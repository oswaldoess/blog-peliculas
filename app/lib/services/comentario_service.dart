import '../core/api_client.dart';
import '../models/comentario_model.dart';

class ComentarioService {
  final ApiClient _api = ApiClient.instance;

  Future<List<ComentarioModel>> obtenerComentarios(int postId) async {
    final datos = await _api.get('/posts/$postId/comentarios') as List<dynamic>;
    return datos
        .map((j) => ComentarioModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<ComentarioModel> agregarComentario(int postId, String texto) async {
    final datos = await _api.post(
      '/posts/$postId/comentarios',
      body: {'comentario': texto.trim()},
    );
    return ComentarioModel.fromJson(datos as Map<String, dynamic>);
  }

  Future<void> eliminarComentario(int comentarioId) async {
    await _api.delete('/comentarios/$comentarioId');
  }

  /// Pone o quita la reacción (la API la alterna) y regresa el resumen.
  Future<List<ReaccionResumen>> reaccionar(int comentarioId, String tipo) async {
    final datos = await _api.post(
      '/comentarios/$comentarioId/reacciones',
      body: {'tipo': tipo},
    ) as List<dynamic>;
    return datos
        .map((j) => ReaccionResumen.fromJson(j as Map<String, dynamic>))
        .toList();
  }
}
