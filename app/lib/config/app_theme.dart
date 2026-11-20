import 'package:flutter/material.dart';

/// Colores del proyecto (los mismos que se usaron en clase).
class AppColors {
  AppColors._();

  static const Color azul = Color(0xFF2196F3); // botones y acentos
  static const Color marino = Color(0xFF08245C); // títulos
  static const Color dorado = Color(0xFFC9A227); // estrellas e íconos
  static const Color rojo = Color(0xFFE53935);

  static const Color fondo = Color(0xFFF5F7FB);
  static const Color superficie = Colors.white;
  static const Color superficieAlta = Color(0xFFF0F2F7);
  static const Color borde = Color(0xFFDDE2EC);
  static const Color texto = Color(0xFF1F2937);
  static const Color textoSuave = Color(0xFF6B7280);
}

/// Color e ícono por género (chips y portadas sin imagen).
class EstiloGenero {
  final List<Color> gradiente;
  final IconData icono;

  const EstiloGenero(this.gradiente, this.icono);

  Color get principal => gradiente.first;

  static const List<String> generos = [
    'Acción',
    'Animación',
    'Ciencia ficción',
    'Comedia',
    'Documental',
    'Drama',
    'Fantasía',
    'Romance',
    'Suspenso',
    'Terror',
  ];

  static const Map<String, EstiloGenero> _estilos = {
    'Acción': EstiloGenero([Color(0xFFE4572E), Color(0xFF9C2A12)], Icons.local_fire_department),
    'Animación': EstiloGenero([Color(0xFF9C5CF0), Color(0xFF4B2390)], Icons.animation),
    'Ciencia ficción': EstiloGenero([Color(0xFF2196F3), Color(0xFF0D3C7A)], Icons.rocket_launch),
    'Comedia': EstiloGenero([Color(0xFFF2B33D), Color(0xFFB0700E)], Icons.sentiment_very_satisfied),
    'Documental': EstiloGenero([Color(0xFF8D6E63), Color(0xFF4E342E)], Icons.videocam),
    'Drama': EstiloGenero([Color(0xFF5C6BC0), Color(0xFF08245C)], Icons.theater_comedy),
    'Fantasía': EstiloGenero([Color(0xFF26A69A), Color(0xFF00574F)], Icons.auto_awesome),
    'Romance': EstiloGenero([Color(0xFFEC407A), Color(0xFF8E1446)], Icons.favorite),
    'Suspenso': EstiloGenero([Color(0xFF607D8B), Color(0xFF263238)], Icons.visibility),
    'Terror': EstiloGenero([Color(0xFFB71C1C), Color(0xFF2B0505)], Icons.nightlight),
  };

  static const EstiloGenero _general =
      EstiloGenero([AppColors.azul, AppColors.marino], Icons.movie_filter);

  static EstiloGenero de(String? genero) => _estilos[genero] ?? _general;
}

class AppTheme {
  AppTheme._();

  /// Títulos de sección (azul marino y en negritas, como en clase).
  static TextStyle titulo({double size = 24, Color color = AppColors.marino}) {
    return TextStyle(fontSize: size, fontWeight: FontWeight.bold, color: color);
  }

  static ThemeData get claro {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.azul,
        primary: AppColors.azul,
        onPrimary: Colors.white,
        error: AppColors.rojo,
      ),
      scaffoldBackgroundColor: AppColors.fondo,
    );
  }

  /// Decoración de los campos de texto (misma que CustomTextField).
  static InputDecoration campo(String etiqueta, {IconData? icono, String? ayuda, Widget? sufijo}) {
    return InputDecoration(
      labelText: etiqueta,
      helperText: ayuda,
      helperMaxLines: 2,
      prefixIcon: icono == null ? null : Icon(icono),
      suffixIcon: sufijo,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
    );
  }
}
