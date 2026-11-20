import 'dart:async';

import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../core/navegacion.dart';
import '../core/session_manager.dart';
import '../models/mensaje_model.dart';
import '../models/user_model.dart';
import '../services/mensaje_service.dart';
import '../utils/formatos.dart';
import '../widgets/avatar.dart';

/// Chat privado 1 a 1. Se actualiza solo cada 4 segundos.
class ChatPage extends StatefulWidget {
  final UserModel usuario;

  const ChatPage({super.key, required this.usuario});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _servicio = MensajeService();
  final _texto = TextEditingController();
  final List<MensajeModel> _mensajes = [];

  Timer? _timer;
  bool _cargando = true;
  bool _enviando = false;
  bool _consultando = false;
  String? _error;

  int get _miId => SessionManager.instance.usuario?.id ?? 0;

  @override
  void initState() {
    super.initState();
    _cargarInicial();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _traerNuevos());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _texto.dispose();
    super.dispose();
  }

  Future<void> _cargarInicial() async {
    try {
      final lista = await _servicio.obtenerChat(widget.usuario.id);
      if (!mounted) return;
      setState(() {
        _mensajes
          ..clear()
          ..addAll(lista);
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _traerNuevos() async {
    if (_consultando || _cargando) return;
    _consultando = true;
    try {
      // Se pide la conversación completa para refrescar también las
      // palomitas de "leído" de mis mensajes.
      final lista = await _servicio.obtenerChat(widget.usuario.id);
      if (!mounted) return;
      final cambio = lista.length != _mensajes.length ||
          (lista.isNotEmpty && lista.last.leido != _mensajes.last.leido);
      if (!cambio) return;
      setState(() {
        _mensajes
          ..clear()
          ..addAll(lista);
      });
    } catch (_) {
      // Se reintenta en el siguiente ciclo.
    } finally {
      _consultando = false;
    }
  }

  void _agregar(List<MensajeModel> nuevos) {
    final ids = _mensajes.map((m) => m.id).toSet();
    _mensajes.addAll(nuevos.where((m) => !ids.contains(m.id)));
    _mensajes.sort((a, b) => a.id.compareTo(b.id));
  }

  Future<void> _enviar() async {
    final texto = _texto.text.trim();
    if (texto.isEmpty || _enviando) return;
    setState(() => _enviando = true);
    try {
      final mensaje = await _servicio.enviar(widget.usuario.id, texto);
      if (!mounted) return;
      _texto.clear();
      setState(() => _agregar([mensaje]));
    } catch (e) {
      mostrarMensaje(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.superficie,
        titleSpacing: 0,
        title: Row(
          children: [
            Avatar(nombre: widget.usuario.nombre, radio: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.usuario.nombre, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const Text('Mensaje privado', style: TextStyle(fontSize: 12, color: AppColors.textoSuave)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _lista()),
          _barraEnvio(),
        ],
      ),
    );
  }

  Widget _lista() {
    if (_cargando) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.rojo)),
        ),
      );
    }
    if (_mensajes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Saluda a ${widget.usuario.nombre.split(' ').first} y recomiéndale una película 🍿',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textoSuave),
          ),
        ),
      );
    }
    // reverse: true → el mensaje más reciente siempre queda abajo.
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      itemCount: _mensajes.length,
      itemBuilder: (context, i) {
        final m = _mensajes[_mensajes.length - 1 - i];
        return _Burbuja(mensaje: m, esMio: m.emisorId == _miId);
      },
    );
  }

  Widget _barraEnvio() {
    return Container(
      color: AppColors.superficie,
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _texto,
                minLines: 1,
                maxLines: 4,
                maxLength: 2000,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _enviar(),
                decoration: InputDecoration(
                  hintText: 'Escribe un mensaje…',
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.superficieAlta,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton.filled(
              tooltip: 'Enviar',
              onPressed: _enviando ? null : _enviar,
              icon: const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _Burbuja extends StatelessWidget {
  final MensajeModel mensaje;
  final bool esMio;

  const _Burbuja({required this.mensaje, required this.esMio});

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.of(context).size.width * 0.75;
    return Align(
      alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: ancho),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.fromLTRB(14, 9, 14, 7),
        decoration: BoxDecoration(
          color: esMio ? AppColors.azul : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(esMio ? 18 : 4),
            bottomRight: Radius.circular(esMio ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              mensaje.contenido,
              style: TextStyle(
                color: esMio ? Colors.white : AppColors.texto,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  Formatos.hora(mensaje.fecha),
                  style: TextStyle(
                    fontSize: 10.5,
                    color: esMio ? Colors.white70 : AppColors.textoSuave,
                  ),
                ),
                if (esMio) ...[
                  const SizedBox(width: 4),
                  Icon(
                    mensaje.leido ? Icons.done_all_rounded : Icons.done_rounded,
                    size: 14,
                    color: Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
