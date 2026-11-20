import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'session_manager.dart';

/// Error con un mensaje listo para mostrarse al usuario.
class ApiException implements Exception {
  final String mensaje;
  final int? codigo;

  const ApiException(this.mensaje, {this.codigo});

  @override
  String toString() => mensaje;
}

/// Cliente HTTP único para toda la app.
///
/// * Agrega el header `Authorization: Bearer <token>` automáticamente.
/// * Decodifica siempre en UTF-8 (acentos y ñ).
/// * Convierte cualquier error en un [ApiException] con mensaje legible.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const Duration _limite = Duration(seconds: 15);
  final http.Client _http = http.Client();

  Future<dynamic> get(String ruta, {Map<String, String>? query}) =>
      _enviar('GET', ruta, query: query);

  Future<dynamic> post(String ruta, {Object? body, bool conToken = true}) =>
      _enviar('POST', ruta, body: body, conToken: conToken);

  Future<dynamic> put(String ruta, {Object? body}) =>
      _enviar('PUT', ruta, body: body);

  Future<dynamic> delete(String ruta) => _enviar('DELETE', ruta);

  Map<String, String> _headers({required bool conToken, bool json = false}) {
    final headers = <String, String>{'Accept': 'application/json'};
    if (json) headers['Content-Type'] = 'application/json; charset=utf-8';
    final token = SessionManager.instance.token;
    if (conToken && token != null) headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  Future<dynamic> _enviar(
    String metodo,
    String ruta, {
    Object? body,
    Map<String, String>? query,
    bool conToken = true,
  }) async {
    final peticion = http.Request(metodo, ApiConfig.uri(ruta, query));
    peticion.headers.addAll(_headers(conToken: conToken, json: body != null));
    if (body != null) peticion.body = jsonEncode(body);

    final http.Response respuesta;
    try {
      final enviada = await _http.send(peticion).timeout(_limite);
      respuesta = await http.Response.fromStream(enviada).timeout(_limite);
    } on TimeoutException {
      throw const ApiException('El servidor tardó demasiado en responder');
    } catch (_) {
      throw ApiException(
        'No se pudo conectar con la API (${ApiConfig.baseUrl}). '
        '¿Está encendido el servidor?',
      );
    }
    return _procesar(respuesta, conToken: conToken);
  }

  dynamic _procesar(http.Response respuesta, {required bool conToken}) {
    dynamic datos;
    if (respuesta.bodyBytes.isNotEmpty) {
      final texto = utf8.decode(respuesta.bodyBytes, allowMalformed: true);
      try {
        datos = jsonDecode(texto);
      } catch (_) {
        datos = texto;
      }
    }

    final codigo = respuesta.statusCode;
    if (codigo >= 200 && codigo < 300) return datos;

    String mensaje = 'Error del servidor ($codigo)';
    if (datos is Map && datos['detail'] != null) {
      mensaje = datos['detail'].toString();
    }

    // Token vencido o revocado → cerrar sesión y volver al login.
    if (codigo == 401 && conToken && SessionManager.instance.token != null) {
      SessionManager.instance.expirar(mensaje);
    }
    throw ApiException(mensaje, codigo: codigo);
  }
}
