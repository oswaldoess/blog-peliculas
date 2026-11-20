import '../core/api_client.dart';
import '../models/user_model.dart';

class UserService {
  final ApiClient _api = ApiClient.instance;

  /// Solo administradores.
  Future<List<UserModel>> obtenerUsuarios() async {
    final datos = await _api.get('/usuarios') as List<dynamic>;
    return datos
        .map((j) => UserModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Solo administradores: crea un usuario eligiendo su rol.
  Future<UserModel> crearUsuario({
    required String nombre,
    required String correo,
    required String password,
    required int tipoUsuario,
  }) async {
    final datos = await _api.post('/usuarios', body: {
      'nom_usr': nombre.trim(),
      'mail': correo.trim().toLowerCase(),
      'password': password,
      'tip_usu': tipoUsuario,
    });
    return UserModel.fromJson(datos as Map<String, dynamic>);
  }

  /// Envía solo los campos indicados.
  Future<UserModel> actualizarUsuario(int id, Map<String, dynamic> cambios) async {
    final datos = await _api.put('/usuarios/$id', body: cambios);
    return UserModel.fromJson(datos as Map<String, dynamic>);
  }

  Future<void> eliminarUsuario(int id) async {
    await _api.delete('/usuarios/$id');
  }
}
