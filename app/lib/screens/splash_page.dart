import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../services/auth_service.dart';

/// Revisa si hay un token guardado y si sigue siendo válido en el servidor.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _revisarSesion();
  }

  Future<void> _revisarSesion() async {
    final usuario = await AuthService().restaurarSesion();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(usuario == null ? '/login' : '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.movie_filter_rounded, size: 72, color: AppColors.azul),
            const SizedBox(height: 12),
            Text('Blog de películas', style: AppTheme.titulo(size: 28)),
            const SizedBox(height: 24),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          ],
        ),
      ),
    );
  }
}
