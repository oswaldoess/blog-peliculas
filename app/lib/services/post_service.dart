import '../core/api_client.dart';
import '../models/post_model.dart';

class ValoracionResultado {
  final double promedio;
  final int total;
  final int? mia;

  const ValoracionResultado(this.promedio, this.total, this.mia);
}

class PostService {
  final ApiClient _api = ApiClient.instance;

  Future<List<PostModel>> obtenerPosts({
    bool mios = false,
    String? genero,
    String? busqueda,
  }) async {
    final query = <String, String>{};
    if (mios) query['mios'] = 'true';
    if (genero != null && genero.isNotEmpty) query['genero'] = genero;
    if (busqueda != null && busqueda.trim().isNotEmpty) {
      query['q'] = busqueda.trim();
    }
    final datos = await _api.get('/posts', query: query) as List<dynamic>;
    return datos
        .map((j) => PostModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<List<String>> obtenerGeneros() async {
    final datos = await _api.get('/posts/generos') as List<dynamic>;
    return datos.map((g) => g.toString()).toList();
  }

  Future<PostModel> obtenerPost(int id) async {
    final datos = await _api.get('/posts/$id');
    return PostModel.fromJson(datos as Map<String, dynamic>);
  }

  Future<PostModel> guardarPost(Map<String, dynamic> cuerpo, {int? id}) async {
    final datos = id == null
        ? await _api.post('/posts', body: cuerpo)
        : await _api.put('/posts/$id', body: cuerpo);
    return PostModel.fromJson(datos as Map<String, dynamic>);
  }

  Future<void> eliminarPost(int id) async {
    await _api.delete('/posts/$id');
  }

  Future<ValoracionResultado> valorar(int id, int estrellas) async {
    final datos = await _api.put(
      '/posts/$id/valoracion',
      body: {'estrellas': estrellas},
    ) as Map<String, dynamic>;
    return ValoracionResultado(
      (datos['promedio'] as num).toDouble(),
      (datos['total_valoraciones'] as num).toInt(),
      (datos['mi_valoracion'] as num?)?.toInt(),
    );
  }
}
