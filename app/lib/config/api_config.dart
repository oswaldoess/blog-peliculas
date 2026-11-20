import 'package:flutter/foundation.dart';

/// Dirección de la API de FastAPI.
///
/// * Web / Windows / iOS simulador → http://127.0.0.1:8000
/// * Emulador de Android           → http://10.0.2.2:8000 (es el "localhost" de la PC)
/// * Celular físico                → flutter run --dart-define=API_URL=http://IP_DE_TU_PC:8000
class ApiConfig {
  ApiConfig._();

  static const String _urlDefinida = String.fromEnvironment('API_URL');

  static String get baseUrl {
    if (_urlDefinida.isNotEmpty) return _urlDefinida;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  static Uri uri(String ruta, [Map<String, String>? query]) {
    final base = Uri.parse('$baseUrl$ruta');
    if (query == null || query.isEmpty) return base;
    return base.replace(queryParameters: query);
  }

  /// Las imágenes subidas se guardan como ruta relativa (/static/...);
  /// aquí se convierten en URL completa.
  static String? resolverImagen(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return '$baseUrl$url';
  }
}
