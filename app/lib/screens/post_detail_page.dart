import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../core/navegacion.dart';
import '../core/session_manager.dart';
import '../models/comentario_model.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../services/comentario_service.dart';
import '../services/post_service.dart';
import '../utils/formatos.dart';
import '../widgets/avatar.dart';
import '../widgets/estrellas.dart';
import '../widgets/portada_pelicula.dart';
import 'chat_page.dart';
import 'post_form_page.dart';

class PostDetailPage extends StatefulWidget {
  final PostModel post;

  const PostDetailPage({super.key, required this.post});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final _posts = PostService();
  final _comentariosSrv = ComentarioService();
  final _texto = TextEditingController();

  late PostModel _post;
  List<ComentarioModel> _comentarios = [];
  bool _cargandoComentarios = true;
  String? _errorComentarios;
  bool _enviando = false;

  bool get _puedeEditar => _post.esMio || SessionManager.instance.esAdmin;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _cargar();
  }

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargandoComentarios = true;
      _errorComentarios = null;
    });
    try {
      final resultados = await Future.wait([
        _posts.obtenerPost(_post.id),
        _comentariosSrv.obtenerComentarios(_post.id),
      ]);
      if (!mounted) return;
      setState(() {
        _post = resultados[0] as PostModel;
        _comentarios = resultados[1] as List<ComentarioModel>;
      });
    } catch (e) {
      if (mounted) setState(() => _errorComentarios = e.toString());
    } finally {
      if (mounted) setState(() => _cargandoComentarios = false);
    }
  }

  // ------------------------------------------------------------------
  // Acciones
  // ------------------------------------------------------------------
  Future<void> _calificar(int estrellas) async {
    try {
      final r = await _posts.valorar(_post.id, estrellas);
      if (!mounted) return;
      setState(() {
        _post = _post.copyWith(promedio: r.promedio, totalValoraciones: r.total, miValoracion: r.mia);
      });
      mostrarMensaje('Calificaste con $estrellas ${estrellas == 1 ? 'estrella' : 'estrellas'}');
    } catch (e) {
      mostrarMensaje(e.toString(), error: true);
    }
  }

  Future<void> _comentar() async {
    final texto = _texto.text.trim();
    if (texto.isEmpty || _enviando) return;
    setState(() => _enviando = true);
    try {
      final nuevo = await _comentariosSrv.agregarComentario(_post.id, texto);
      if (!mounted) return;
      _texto.clear();
      FocusScope.of(context).unfocus();
      setState(() {
        _comentarios = [..._comentarios, nuevo];
        _post = _post.copyWith(totalComentarios: _comentarios.length);
      });
    } catch (e) {
      mostrarMensaje(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _borrarComentario(ComentarioModel c) async {
    final ok = await _confirmar('¿Borrar comentario?', 'Esta acción no se puede deshacer.');
    if (!ok) return;
    try {
      await _comentariosSrv.eliminarComentario(c.id);
      if (!mounted) return;
      setState(() {
        _comentarios = _comentarios.where((x) => x.id != c.id).toList();
        _post = _post.copyWith(totalComentarios: _comentarios.length);
      });
    } catch (e) {
      mostrarMensaje(e.toString(), error: true);
    }
  }

  Future<void> _reaccionar(ComentarioModel c, String tipo) async {
    try {
      final resumen = await _comentariosSrv.reaccionar(c.id, tipo);
      if (!mounted) return;
      setState(() {
        _comentarios = _comentarios
            .map((x) => x.id == c.id ? x.conReacciones(resumen) : x)
            .toList();
      });
    } catch (e) {
      mostrarMensaje(e.toString(), error: true);
    }
  }

  Future<void> _elegirReaccion(ComentarioModel c) async {
    final tipo = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.superficie,
      builder: (contexto) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Reacciona al comentario', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: Reacciones.emojis.entries.map((e) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(40),
                    onTap: () => Navigator.of(contexto).pop(e.key),
                    child: Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.superficieAlta,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Text(e.value, style: const TextStyle(fontSize: 28)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
    if (tipo != null) await _reaccionar(c, tipo);
  }

  Future<void> _editar() async {
    final editado = await Navigator.of(context).push<PostModel>(
      MaterialPageRoute<PostModel>(builder: (_) => PostFormPage(post: _post)),
    );
    if (editado != null && mounted) setState(() => _post = editado);
  }

  Future<void> _eliminar() async {
    final ok = await _confirmar('¿Eliminar reseña?', 'También se borrarán sus comentarios y calificaciones.');
    if (!ok) return;
    try {
      await _posts.eliminarPost(_post.id);
      if (!mounted) return;
      mostrarMensaje('Reseña eliminada');
      Navigator.of(context).pop();
    } catch (e) {
      mostrarMensaje(e.toString(), error: true);
    }
  }

  void _escribirAlAutor() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatPage(
          usuario: UserModel(id: _post.autorId, nombre: _post.autorNombre),
        ),
      ),
    );
  }

  Future<bool> _confirmar(String titulo, String detalle) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: Text(titulo),
        content: Text(detalle),
        actions: [
          TextButton(onPressed: () => Navigator.of(contexto).pop(false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.rojo, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(contexto).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    return r ?? false;
  }

  // ------------------------------------------------------------------
  // UI
  // ------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de reseña'),
        actions: [
          if (_puedeEditar)
            PopupMenuButton<String>(
              onSelected: (v) => v == 'editar' ? _editar() : _eliminar(),
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'editar',
                  child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Editar')),
                ),
                PopupMenuItem(
                  value: 'eliminar',
                  child: ListTile(
                    leading: Icon(Icons.delete_outline, color: AppColors.rojo),
                    title: Text('Eliminar'),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _cargar,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  PortadaPelicula(
                    pelicula: _post.pelicula,
                    anio: _post.anio,
                    genero: _post.genero,
                    imagenUrl: _post.imagenUrl,
                    alto: 230,
                  ),
                  _contenido(),
                  ..._seccionComentarios(),
                ],
              ),
            ),
          ),
          _barraComentario(),
        ],
      ),
    );
  }

  Widget _contenido() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [
              _post.peliculaConAnio,
              ?_post.genero,
            ].join('  ·  '),
            style: const TextStyle(color: AppColors.azul, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _post.titulo,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.marino),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Avatar(nombre: _post.autorNombre, radio: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_post.autorNombre, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(
                      '${Formatos.fecha(_post.fecha)} · ${_post.minutosLectura} min de lectura'
                      '${_post.actualizado != null ? ' · editada' : ''}',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textoSuave),
                    ),
                  ],
                ),
              ),
              if (!_post.esMio)
                IconButton.filledTonal(
                  tooltip: 'Enviar mensaje a ${_post.autorNombre}',
                  onPressed: _escribirAlAutor,
                  icon: const Icon(Icons.send_rounded, size: 20),
                ),
            ],
          ),
          if (_post.tags.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _post.tags
                  .map((t) => Chip(
                        label: Text('#$t'),
                        visualDensity: VisualDensity.compact,
                        side: const BorderSide(color: AppColors.borde),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 18),
          _tarjetaCalificacion(),
          const SizedBox(height: 20),
          Text(_post.descripcion, style: const TextStyle(fontSize: 16.5, height: 1.65)),
          const SizedBox(height: 28),
          Row(
            children: [
              Text('Comentarios', style: AppTheme.titulo(size: 22)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.superficieAlta,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${_comentarios.length}'),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _tarjetaCalificacion() {
    final mia = _post.miValoracion;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borde),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                _post.totalValoraciones == 0 ? '—' : _post.promedio.toStringAsFixed(1),
                style: AppTheme.titulo(size: 36),
              ),
              Text(
                '${_post.totalValoraciones} ${_post.totalValoraciones == 1 ? 'voto' : 'votos'}',
                style: const TextStyle(fontSize: 12, color: AppColors.textoSuave),
              ),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_post.esMio) ...[
                  const Text('Así calificaron tu reseña', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Estrellas(valor: _post.promedio, tamano: 26),
                ] else ...[
                  Text(
                    mia == null ? '¿Qué tan buena es esta reseña?' : 'Tu calificación: $mia/5',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Estrellas(
                    valor: (mia ?? 0).toDouble(),
                    tamano: 30,
                    alCalificar: _calificar,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _seccionComentarios() {
    if (_cargandoComentarios && _comentarios.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (_errorComentarios != null) {
      return [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text(_errorComentarios!, style: const TextStyle(color: AppColors.rojo)),
        ),
      ];
    }
    if (_comentarios.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Text(
            'Nadie ha comentado todavía. ¡Sé la primera persona!',
            style: TextStyle(color: AppColors.textoSuave),
          ),
        ),
      ];
    }
    return _comentarios
        .map((c) => _ComentarioTile(
              comentario: c,
              alReaccionar: (tipo) => _reaccionar(c, tipo),
              alAgregarReaccion: () => _elegirReaccion(c),
              alBorrar: () => _borrarComentario(c),
            ))
        .toList();
  }

  Widget _barraComentario() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.superficie,
        border: Border(top: BorderSide(color: AppColors.borde)),
      ),
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
                decoration: InputDecoration(
                  hintText: 'Escribe un comentario…',
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
              tooltip: 'Publicar comentario',
              onPressed: _enviando ? null : _comentar,
              icon: _enviando
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComentarioTile extends StatelessWidget {
  final ComentarioModel comentario;
  final ValueChanged<String> alReaccionar;
  final VoidCallback alAgregarReaccion;
  final VoidCallback alBorrar;

  const _ComentarioTile({
    required this.comentario,
    required this.alReaccionar,
    required this.alAgregarReaccion,
    required this.alBorrar,
  });

  @override
  Widget build(BuildContext context) {
    final c = comentario;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Avatar(nombre: c.autorNombre, radio: 17),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                  decoration: BoxDecoration(
                    color: AppColors.superficie,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                      topLeft: Radius.circular(4),
                    ),
                    border: Border.all(color: AppColors.borde),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              c.autorNombre,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                            ),
                          ),
                          Text(
                            Formatos.relativo(c.fecha),
                            style: const TextStyle(fontSize: 11.5, color: AppColors.textoSuave),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(c.comentario, style: const TextStyle(height: 1.4)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ...c.reacciones.map(
                      (r) => _ChipReaccion(reaccion: r, onTap: () => alReaccionar(r.tipo)),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: alAgregarReaccion,
                      child: const Padding(
                        padding: EdgeInsets.all(5),
                        child: Icon(Icons.add_reaction_outlined, size: 19, color: AppColors.textoSuave),
                      ),
                    ),
                    if (c.puedeBorrar)
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: alBorrar,
                        child: const Padding(
                          padding: EdgeInsets.all(5),
                          child: Icon(Icons.delete_outline_rounded, size: 19, color: AppColors.textoSuave),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipReaccion extends StatelessWidget {
  final ReaccionResumen reaccion;
  final VoidCallback onTap;

  const _ChipReaccion({required this.reaccion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final mia = reaccion.mia;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: mia ? AppColors.azul.withValues(alpha: 0.15) : AppColors.superficieAlta,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: mia ? AppColors.azul : AppColors.borde),
        ),
        child: Text(
          '${Reacciones.emoji(reaccion.tipo)} ${reaccion.total}',
          style: TextStyle(fontWeight: mia ? FontWeight.w700 : FontWeight.w500),
        ),
      ),
    );
  }
}
