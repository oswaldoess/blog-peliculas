import 'package:flutter/material.dart';

import '../config/app_theme.dart';

/// Imagen de la reseña. Si no tiene URL (o no carga) se muestra un
/// recuadro de color según el género, con el nombre de la película.
class PortadaPelicula extends StatelessWidget {
  final String pelicula;
  final int? anio;
  final String? genero;
  final String? imagenUrl;
  final double alto;

  const PortadaPelicula({
    super.key,
    required this.pelicula,
    this.anio,
    this.genero,
    this.imagenUrl,
    this.alto = 180,
  });

  @override
  Widget build(BuildContext context) {
    final url = imagenUrl;
    if (url == null) return _sinImagen();
    return Image.network(
      url,
      height: alto,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _sinImagen(),
    );
  }

  Widget _sinImagen() {
    final estilo = EstiloGenero.de(genero);
    return Container(
      height: alto,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: estilo.gradiente,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(estilo.icono, size: 44, color: Colors.white70),
          const SizedBox(height: 8),
          Text(
            pelicula,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          if (anio != null) Text('$anio', style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
