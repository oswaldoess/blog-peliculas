import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user_model.dart';
import 'navegacion.dart';

/// Maneja la sesión del usuario.
///
/// * El token JWT se guarda con flutter_secure_storage (cifrado por el
///   sistema operativo), nunca en texto plano ni en SharedPreferences.
/// * Al abrir la app se valida el token contra /auth/me (ver SplashPage).
/// * Si la API responde 401, la sesión se borra y se regresa al login.
class SessionManager extends ChangeNotifier {
  SessionManager._();
  static final SessionManager instance = SessionManager._();

  static const String _claveToken = 'jwt_token';
  final FlutterSecureStorage _almacen = const FlutterSecureStorage();

  String? _token;
  UserModel? _usuario;
  bool _expirando = false;

  String? get token => _token;
  UserModel? get usuario => _usuario;
  bool get haySesion => _token != null && _usuario != null;
  bool get esAdmin => _usuario?.esAdmin ?? false;

  Future<void> iniciar(String token, UserModel usuario) async {
    _token = token;
    _usuario = usuario;
    _expirando = false;
    try {
      await _almacen.write(key: _claveToken, value: token);
    } catch (_) {
      // Si el almacenamiento seguro falla, la sesión dura solo mientras
      // la app esté abierta (no se guarda el token en un lugar inseguro).
    }
    notifyListeners();
  }

  /// Usado por el splash: carga el token guardado (si existe).
  Future<String?> cargarTokenGuardado() async {
    try {
      _token = await _almacen.read(key: _claveToken);
    } catch (_) {
      _token = null;
    }
    return _token;
  }

  void actualizarUsuario(UserModel usuario) {
    _usuario = usuario;
    notifyListeners();
  }

  Future<void> cerrar() async {
    _token = null;
    _usuario = null;
    try {
      await _almacen.delete(key: _claveToken);
    } catch (_) {}
    notifyListeners();
  }

  /// La API respondió 401 con un token: la sesión expiró o fue revocada.
  Future<void> expirar(String motivo) async {
    if (_expirando) return;
    _expirando = true;
    await cerrar();
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (_) => false);
    mostrarMensaje(motivo, error: true);
  }
}
