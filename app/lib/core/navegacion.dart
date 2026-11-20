import 'package:flutter/material.dart';

/// Llave global del Navigator: permite mandar al login desde cualquier
/// parte (por ejemplo, cuando la API responde 401 porque la sesión expiró).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final GlobalKey<ScaffoldMessengerState> messengerKey =
    GlobalKey<ScaffoldMessengerState>();

void mostrarMensaje(String texto, {bool error = false}) {
  final messenger = messengerKey.currentState;
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(texto),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? const Color(0xFFB3261E) : null,
      ),
    );
}
