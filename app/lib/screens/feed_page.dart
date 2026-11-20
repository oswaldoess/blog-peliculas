import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../core/session_manager.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../widgets/category_chip.dart';
import '../widgets/estado_vista.dart';
import '../widgets/post_card.dart';
import 'post_detail_page.dart';
import 'post_form_page.dart';

/// Lista de reseñas: todas (propias y de otros usuarios) o solo las mías.
class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final PostService postService = PostService();
  late Future<List<PostModel>> futurePosts;
  List<String> generos = const [];
  bool soloMias = false;
  String? genero;

  @override
  void initState() {
    super.initState();
    futurePosts = _cargar();
    _cargarGeneros();
  }

  Future<List<PostModel>> _cargar() => postService.obtenerPosts(mios: soloMias, genero: genero);

  Future<void> _cargarGeneros() async {
    try {
      final lista = await postService.obtenerGeneros();
      if (mounted) setState(() => generos = lista);
    } catch (_) {}
  }

  void recargarPosts() {
    setState(() {
      futurePosts = _cargar();
    });
  }

  Future<void> _refrescar() async {
    recargarPosts();
    _cargarGeneros();
    try {
      await futurePosts;
    } catch (_) {}
  }

  Future<void> _abrir(PostModel post) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (context) => PostDetailPage(post: post)),
    );
    _refrescar();
  }

  Future<void> _nueva() async {
    final creada = await Navigator.push<PostModel>(
      context,
      MaterialPageRoute<PostModel>(builder: (context) => const PostFormPage()),
    );
    if (creada != null) _refrescar();
  }

  Widget _chip(String texto, bool seleccionado, VoidCallback alTocar) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: CategoryChip(text: texto, selected: seleccionado, onTap: alTocar),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombreUsuario = SessionManager.instance.usuario?.nombre ?? 'Usuario';
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Blog de películas'),
            Text('Bienvenido, $nombreUsuario', style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: _refrescar,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: _nueva,
        icon: const Icon(Icons.add),
        label: const Text('Nueva reseña'),
      ),
      body: RefreshIndicator(
        onRefresh: _refrescar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          children: [
            Text('Bienvenido', style: AppTheme.titulo(size: 28)),
            const SizedBox(height: 5),
            const Text(
              'Descubre qué opinan de las películas',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _chip('Todas', !soloMias, () {
                  soloMias = false;
                  recargarPosts();
                }),
                _chip('Mis reseñas', soloMias, () {
                  soloMias = true;
                  recargarPosts();
                }),
              ],
            ),
            if (generos.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _chip('Todos los géneros', genero == null, () {
                      genero = null;
                      recargarPosts();
                    }),
                    ...generos.map((g) => _chip(g, genero == g, () {
                          genero = g;
                          recargarPosts();
                        })),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            FutureBuilder<List<PostModel>>(
              future: futurePosts,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return SizedBox(height: 360, child: EstadoVista.error(snapshot.error!, recargarPosts));
                }
                final posts = snapshot.data ?? <PostModel>[];
                if (posts.isEmpty) {
                  return SizedBox(
                    height: 360,
                    child: EstadoVista(
                      icono: Icons.movie_outlined,
                      titulo: soloMias ? 'Aún no escribes reseñas' : 'No hay reseñas registradas.',
                      textoBoton: soloMias ? 'Escribir mi primera reseña' : null,
                      alPresionar: soloMias ? _nueva : null,
                    ),
                  );
                }
                return Column(
                  children: posts.map((post) => PostCard(post: post, onTap: () => _abrir(post))).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
