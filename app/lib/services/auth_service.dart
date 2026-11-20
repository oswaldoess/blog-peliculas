import '../core/api_client.dart';
import '../core/session_manager.dart';
import '../models/user_model.dart';

class AuthService {
  final ApiClient _api = ApiClient.instance;
  final SessionManager _sesion = SessionManager.instance;

  // ---------------- Validaciones del lado de la app ----------------
  static final RegExp _regexCorreo = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? validarCorreo(String? valor) {
    final v = (valor ?? '').trim();
    if (v.isEmpty) return 'Ingresa tu correo';
    if (!_regexCorreo.hasMatch(v)) return 'Ingresa un correo válido';
    return null;
  }

  static bool tieneLongitud(String p) => p.length >= 8;
  static bool tieneLetra(String p) => RegExp(r'[A-Za-zÁÉÍÓÚáéíóúÑñ]').hasMatch(p);
  static bool tieneNumero(String p) => RegExp(r'\d').hasMatch(p);

  static String? validarPassword(String? valor) {
    final p = valor ?? '';
    if (p.isEmpty) return 'Ingresa una contraseña';
    if (!tieneLongitud(p) || !tieneLetra(p) || !tieneNumero(p)) {
      return 'Mínimo 8 caracteres, con letras y números';
    }
    return null;
  }

  // ---------------- Llamadas a la API ----------------
  Future<UserModel> login(String correo, String password) async {
    final datos = await _api.post(
      '/auth/login',
      body: {'mail': correo.trim().toLowerCase(), 'password': password},
      conToken: false,
    );
    return _guardarSesion(datos as Map<String, dynamic>);
  }

  Future<UserModel> registrar({
    required String nombre,
    required String correo,
    required String password,
    String? ciudad,
  }) async {
    final datos = await _api.post(
      '/auth/registro',
      body: {
        'nom_usr': nombre.trim(),
        'mail': correo.trim().toLowerCase(),
        'password': password,
        'dir_usr': (ciudad == null || ciudad.trim().isEmpty) ? null : ciudad.trim(),
      },
      conToken: false,
    );
    return _guardarSesion(datos as Map<String, dynamic>);
  }

  /// Valida el token guardado al abrir la app.
  Future<UserModel?> restaurarSesion() async {
    final token = await _sesion.cargarTokenGuardado();
    if (token == null) return null;
    try {
      final datos = await _api.get('/auth/me');
      final usuario = UserModel.fromJson(datos as Map<String, dynamic>);
      await _sesion.iniciar(token, usuario);
      return usuario;
    } catch (_) {
      await _sesion.cerrar();
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout'); // revoca el token en el servidor
    } catch (_) {
      // Aunque falle la red, se borra la sesión local.
    } finally {
      await _sesion.cerrar();
    }
  }

  Future<String> cambiarPassword(String actual, String nueva) async {
    final datos = await _api.put(
      '/auth/password',
      body: {'actual': actual, 'nueva': nueva},
    );
    return (datos as Map<String, dynamic>)['mensaje'] as String;
  }

  Future<UserModel> _guardarSesion(Map<String, dynamic> datos) async {
    final usuario = UserModel.fromJson(datos['usuario'] as Map<String, dynamic>);
    await _sesion.iniciar(datos['access_token'] as String, usuario);
    return usuario;
  }
}
