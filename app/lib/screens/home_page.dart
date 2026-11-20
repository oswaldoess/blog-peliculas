import 'dart:async';

import 'package:flutter/material.dart';

import '../services/mensaje_service.dart';
import 'conversations_page.dart';
import 'feed_page.dart';
import 'profile_page.dart';
import 'tienda_page.dart';

/// Contenedor principal con la barra de navegación inferior.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _mensajes = MensajeService();
  int _indice = 0;
  int _noLeidos = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _contarNoLeidos();
    // Revisa mensajes nuevos cada 15 s para el globito rojo.
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _contarNoLeidos());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _contarNoLeidos() async {
    try {
      final total = await _mensajes.contarNoLeidos();
      if (mounted && total != _noLeidos) setState(() => _noLeidos = total);
    } catch (_) {
      // Silencioso: no interrumpe al usuario por el contador.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _indice,
        children: [
          const FeedPage(),
          const TiendaPage(),
          ConversationsPage(alCambiarNoLeidos: _contarNoLeidos),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (i) {
          setState(() => _indice = i);
          _contarNoLeidos();
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.movie_outlined),
            selectedIcon: Icon(Icons.movie_rounded),
            label: 'Reseñas',
          ),
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Tienda',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _noLeidos > 0,
              label: Text('$_noLeidos'),
              child: const Icon(Icons.chat_bubble_outline_rounded),
            ),
            selectedIcon: Badge(
              isLabelVisible: _noLeidos > 0,
              label: Text('$_noLeidos'),
              child: const Icon(Icons.chat_bubble_rounded),
            ),
            label: 'Mensajes',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
