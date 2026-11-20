import 'package:flutter/material.dart';

import '../config/app_theme.dart';

/// Muestra de 0 a 5 estrellas (con medias).
/// Si se pasa [alCalificar], las estrellas se pueden tocar.
class Estrellas extends StatelessWidget {
  final double valor;
  final double tamano;
  final ValueChanged<int>? alCalificar;

  const Estrellas({
    super.key,
    required this.valor,
    this.tamano = 18,
    this.alCalificar,
  });

  IconData _icono(int posicion) {
    if (valor >= posicion) return Icons.star_rounded;
    if (valor >= posicion - 0.5) return Icons.star_half_rounded;
    return Icons.star_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final callback = alCalificar;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final posicion = i + 1;
        final icono = Icon(
          _icono(posicion),
          size: tamano,
          color: AppColors.dorado,
        );
        if (callback == null) return icono;
        return InkResponse(
          radius: tamano,
          onTap: () => callback(posicion),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: icono,
          ),
        );
      }),
    );
  }
}
