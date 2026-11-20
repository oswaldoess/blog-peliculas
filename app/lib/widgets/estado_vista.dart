import 'package:flutter/material.dart';

import '../config/app_theme.dart';

/// Pantalla para listas vacías o errores, con botón opcional.
class EstadoVista extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String? detalle;
  final String? textoBoton;
  final VoidCallback? alPresionar;

  const EstadoVista({
    super.key,
    required this.icono,
    required this.titulo,
    this.detalle,
    this.textoBoton,
    this.alPresionar,
  });

  factory EstadoVista.error(Object error, VoidCallback reintentar) {
    return EstadoVista(
      icono: Icons.cloud_off_rounded,
      titulo: 'Algo salió mal',
      detalle: error.toString(),
      textoBoton: 'Reintentar',
      alPresionar: reintentar,
    );
  }

  @override
  Widget build(BuildContext context) {
    // ListView para que funcione el "jalar para refrescar".
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(32, 80, 32, 32),
      children: [
        Icon(icono, size: 64, color: AppColors.textoSuave),
        const SizedBox(height: 16),
        Text(
          titulo,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        if (detalle != null) ...[
          const SizedBox(height: 8),
          Text(
            detalle!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textoSuave),
          ),
        ],
        if (textoBoton != null && alPresionar != null) ...[
          const SizedBox(height: 20),
          Center(
            child: FilledButton.tonal(
              onPressed: alPresionar,
              child: Text(textoBoton!),
            ),
          ),
        ],
      ],
    );
  }
}
