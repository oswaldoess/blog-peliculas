import 'dart:async';

import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/mensaje_model.dart';
import '../models/user_model.dart';
import '../services/mensaje_service.dart';
import '../utils/formatos.dart';
import '../widgets/avatar.dart';
import '../widgets/estado_vista.dart';
import 'chat_page.dart';

/// Bandeja de mensajes privados.
class ConversationsPage extends StatefulWidget {
  final VoidCallback? alCambiarNoLeidos;

  const ConversationsPage({super.key, this.alCambiarNoLeidos});

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  final _servicio = MensajeService();
  List<ConversacionModel> _conversaciones = [];
  bool _cargando = true;
  Object? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _cargar();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _cargar(silencioso: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _cargar({bool silencioso = false}) async {
    if (!silencioso && mounted) setState(() => _cargando = true);
    try {
      final lista = await _servicio.obtenerConversaciones();
      if (!mounted) return;
      setState(() {
        _conversaciones = lista;
        _error = null;
      });
    } catch (e) {
      if (mounted && !silencioso) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _abrirChat(UserModel usuario) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ChatPage(usuario: usuario)),
    );
    await _cargar(silencioso: true);
    widget.alCambiarNoLeidos?.call();
  }

  Future<void> _nuevoChat() async {
    final elegido = await Navigator.of(context).push<UserModel>(
      MaterialPageRoute<UserModel>(builder: (_) => const _DirectorioPage()),
    );
    if (elegido != null) await _abrirChat(elegido);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensajes'),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Nuevo mensaje',
        onPressed: _nuevoChat,
        child: const Icon(Icons.edit_square),
      ),
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: _cuerpo(),
      ),
    );
  }

  Widget _cuerpo() {
    if (_cargando && _conversaciones.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _conversaciones.isEmpty) {
      return EstadoVista.error(_error!, _cargar);
    }
    if (_conversaciones.isEmpty) {
      return EstadoVista(
        icono: Icons.forum_outlined,
        titulo: 'Sin conversaciones',
        detalle: 'Escríbele a otra persona del blog para recomendarle películas.',
        textoBoton: 'Iniciar un chat',
        alPresionar: _nuevoChat,
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 90),
      itemCount: _conversaciones.length,
      separatorBuilder: (context, index) => const Divider(height: 1, indent: 76, color: AppColors.borde),
      itemBuilder: (context, i) {
        final c = _conversaciones[i];
        final sinLeer = c.noLeidos > 0;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Avatar(nombre: c.usuario.nombre, radio: 24),
          title: Text(
            c.usuario.nombre,
            style: TextStyle(fontWeight: sinLeer ? FontWeight.w800 : FontWeight.w600),
          ),
          subtitle: Text(
            '${c.ultimoEsMio ? 'Tú: ' : ''}${c.ultimoMensaje}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: sinLeer ? AppColors.texto : AppColors.textoSuave),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatos.chat(c.fecha),
                style: TextStyle(
                  fontSize: 12,
                  color: sinLeer ? AppColors.azul : AppColors.textoSuave,
                ),
              ),
              const SizedBox(height: 6),
              if (sinLeer)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.azul,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${c.noLeidos}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          onTap: () => _abrirChat(c.usuario),
        );
      },
    );
  }
}

/// Lista de usuarios para iniciar una conversación.
class _DirectorioPage extends StatefulWidget {
  const _DirectorioPage();

  @override
  State<_DirectorioPage> createState() => _DirectorioPageState();
}

class _DirectorioPageState extends State<_DirectorioPage> {
  late final Future<List<UserModel>> _futuro = MensajeService().directorio();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo mensaje')),
      body: FutureBuilder<List<UserModel>>(
        future: _futuro,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          final usuarios = snapshot.data ?? const <UserModel>[];
          if (usuarios.isEmpty) {
            return const Center(child: Text('Todavía no hay otros usuarios.'));
          }
          return ListView.builder(
            itemCount: usuarios.length,
            itemBuilder: (context, i) {
              final u = usuarios[i];
              return ListTile(
                leading: Avatar(nombre: u.nombre),
                title: Text(u.nombre),
                subtitle: Text(
                  u.bio ?? u.ciudad ?? u.rol,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).pop(u),
              );
            },
          );
        },
      ),
    );
  }
}
