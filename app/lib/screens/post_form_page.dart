import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../core/navegacion.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../widgets/category_chip.dart';
import '../widgets/portada_pelicula.dart';

/// Crear o editar una reseña (basado en la pantalla "Agregar blog").
class PostFormPage extends StatefulWidget {
  final PostModel? post; // null = nueva reseña

  const PostFormPage({super.key, this.post});

  @override
  State<PostFormPage> createState() => _PostFormPageState();
}

class _PostFormPageState extends State<PostFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _servicio = PostService();

  late final _pelicula = TextEditingController(text: widget.post?.pelicula ?? '');
  late final _anio = TextEditingController(text: widget.post?.anio?.toString() ?? '');
  late final _titulo = TextEditingController(text: widget.post?.titulo ?? '');
  late final _descripcion = TextEditingController(text: widget.post?.descripcion ?? '');
  late final _imagen = TextEditingController(text: widget.post?.img ?? '');
  late final _tags = TextEditingController(text: widget.post?.tags.join(', ') ?? '');
  late String? _genero = widget.post?.genero;
  bool _guardando = false;

  bool get _esEdicion => widget.post != null;

  @override
  void initState() {
    super.initState();
    // Actualiza la vista previa mientras se escribe.
    _pelicula.addListener(_refrescar);
    _anio.addListener(_refrescar);
    _imagen.addListener(_refrescar);
  }

  void _refrescar() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pelicula.dispose();
    _anio.dispose();
    _titulo.dispose();
    _descripcion.dispose();
    _imagen.dispose();
    _tags.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    try {
      final imagen = _imagen.text.trim();
      final cuerpo = PostModel.cuerpo(
        titulo: _titulo.text,
        descripcion: _descripcion.text,
        pelicula: _pelicula.text,
        anio: int.tryParse(_anio.text.trim()),
        genero: _genero,
        img: imagen.isEmpty ? null : imagen,
        tags: _tags.text,
      );
      final guardado = await _servicio.guardarPost(cuerpo, id: widget.post?.id);
      if (!mounted) return;
      mostrarMensaje(_esEdicion ? 'Reseña actualizada correctamente' : 'Reseña publicada correctamente');
      Navigator.of(context).pop(guardado);
    } catch (e) {
      mostrarMensaje('No se pudo guardar: $e', error: true);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  String? _validarUrl(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return null;
    final uri = Uri.tryParse(t);
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https') || uri.host.isEmpty) {
      return 'Escribe una URL que empiece con http:// o https://';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final urlPrevia = _validarUrl(_imagen.text) == null && _imagen.text.trim().isNotEmpty
        ? _imagen.text.trim()
        : null;
    return Scaffold(
      appBar: AppBar(title: Text(_esEdicion ? 'Editar reseña' : 'Nueva reseña')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _esEdicion ? 'Editar reseña' : 'Nueva reseña',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: PortadaPelicula(
                          pelicula: _pelicula.text.trim().isEmpty ? 'Tu película' : _pelicula.text.trim(),
                          anio: int.tryParse(_anio.text.trim()),
                          genero: _genero,
                          imagenUrl: urlPrevia,
                          alto: 160,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _pelicula,
                        decoration: AppTheme.campo('Película', icono: Icons.movie_outlined),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe el nombre de la película' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _anio,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        decoration: AppTheme.campo('Año de estreno (opcional)', icono: Icons.calendar_today)
                            .copyWith(counterText: ''),
                        validator: (v) {
                          final t = (v ?? '').trim();
                          if (t.isEmpty) return null;
                          final n = int.tryParse(t);
                          if (n == null || n < 1888 || n > DateTime.now().year + 2) return 'Año no válido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      const Text('Género'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: EstiloGenero.generos
                            .map((g) => CategoryChip(
                                  text: g,
                                  selected: _genero == g,
                                  onTap: () => setState(() => _genero = _genero == g ? null : g),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _titulo,
                        maxLength: 150,
                        decoration: AppTheme.campo('Título de la reseña', icono: Icons.title),
                        validator: (v) => (v == null || v.trim().length < 3) ? 'Ingresa el título' : null,
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _descripcion,
                        maxLines: 8,
                        decoration: AppTheme.campo('Reseña', ayuda: 'Evita spoilers o avísalos al inicio.')
                            .copyWith(alignLabelWithHint: true),
                        validator: (v) =>
                            (v == null || v.trim().length < 10) ? 'Escribe al menos 10 caracteres' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _imagen,
                        keyboardType: TextInputType.url,
                        decoration: AppTheme.campo('URL de imagen (opcional)', icono: Icons.image_outlined),
                        validator: _validarUrl,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _tags,
                        decoration: AppTheme.campo(
                          'Etiquetas (opcional)',
                          icono: Icons.sell_outlined,
                          ayuda: 'Separadas por coma: clásico, cine mexicano',
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _guardando ? null : _guardar,
                        icon: _guardando
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.save),
                        label: Text(_guardando ? 'Guardando...' : 'Guardar reseña'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
