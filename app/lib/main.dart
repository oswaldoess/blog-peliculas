import 'package:flutter/material.dart';

import 'config/app_theme.dart';
import 'core/navegacion.dart';
import 'screens/home_page.dart';
import 'screens/login_page.dart';
import 'screens/splash_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BlogPeliculasApp());
}

class BlogPeliculasApp extends StatelessWidget {
  const BlogPeliculasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blog de Películas',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.claro,
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: messengerKey,
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashPage(),
        '/login': (_) => const LoginPage(),
        '/home': (_) => const HomePage(),
      },
    );
  }
}
