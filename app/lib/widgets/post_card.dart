import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/post_model.dart';
import '../utils/formatos.dart';
import 'estrellas.dart';
import 'portada_pelicula.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onTap;

  const PostCard({super.key, required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PortadaPelicula(
              pelicula: post.pelicula,
              anio: post.anio,
              genero: post.genero,
              imagenUrl: post.imagenUrl,
              alto: 180,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          [post.peliculaConAnio, ?post.genero].join(' · '),
                          style: const TextStyle(
                            color: AppColors.azul,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (post.esMio)
                        const Chip(
                          label: Text('Mía', style: TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post.titulo,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.marino,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post.descripcion,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Por ${post.autorNombre} · ${Formatos.relativo(post.fecha)}',
                    style: const TextStyle(fontSize: 12.5, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Estrellas(valor: post.promedio, tamano: 18),
                      const SizedBox(width: 6),
                      Text(
                        post.totalValoraciones == 0
                            ? 'Sin calificar'
                            : '${post.promedio.toStringAsFixed(1)} (${post.totalValoraciones})',
                        style: const TextStyle(fontSize: 12.5, color: Colors.black54),
                      ),
                      const Spacer(),
                      const Icon(Icons.comment_outlined, size: 18),
                      const SizedBox(width: 4),
                      Text('${post.totalComentarios}'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
