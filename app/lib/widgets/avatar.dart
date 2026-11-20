import 'package:flutter/material.dart';

/// Avatar con iniciales; el color sale del nombre para que cada
/// usuario tenga siempre el mismo.
class Avatar extends StatelessWidget {
  final String nombre;
  final double radio;

  const Avatar({super.key, required this.nombre, this.radio = 20});

  static const List<Color> _colores = [
    Color(0xFFE8B33A),
    Color(0xFF6C7BF0),
    Color(0xFF3CC7A0),
    Color(0xFFF06A9B),
    Color(0xFF2EC4E4),
    Color(0xFFE4572E),
    Color(0xFFB45CF0),
  ];

  String get _iniciales {
    final partes = nombre
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (partes.isEmpty) return '?';
    if (partes.length == 1) return partes.first[0].toUpperCase();
    return (partes[0][0] + partes[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final suma = nombre.codeUnits.fold<int>(0, (a, b) => a + b);
    final color = _colores[suma % _colores.length];
    return CircleAvatar(
      radius: radio,
      backgroundColor: color.withValues(alpha: 0.22),
      child: Text(
        _iniciales,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: radio * 0.75,
        ),
      ),
    );
  }
}
