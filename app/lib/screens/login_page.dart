import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/auth_background.dart';
import '../widgets/auth_card.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController usuarioController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService authService = AuthService();

  bool ocultarPassword = true;
  bool cargando = false;
  String? error;

  @override
  void dispose() {
    usuarioController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> iniciarSesion() async {
    setState(() => error = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => cargando = true);
    try {
      await authService.login(usuarioController.text, passwordController.text);
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: AuthCard(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock, size: 65, color: AppColors.dorado),
                    const SizedBox(height: 15),
                    const Text(
                      'INICIAR SESIÓN',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                        color: AppColors.marino,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Blog de reseñas de películas',
                      style: TextStyle(color: AppColors.textoSuave),
                    ),
                    const SizedBox(height: 25),
                    CustomTextField(
                      controller: usuarioController,
                      label: 'Correo electrónico',
                      prefixIcon: Icons.person,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: AuthService.validarCorreo,
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      controller: passwordController,
                      label: 'Contraseña',
                      prefixIcon: Icons.lock_outline,
                      obscureText: ocultarPassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => cargando ? null : iniciarSesion(),
                      validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu contraseña' : null,
                      suffixIcon: IconButton(
                        icon: Icon(
                          ocultarPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        ),
                        onPressed: () => setState(() => ocultarPassword = !ocultarPassword),
                      ),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.rojo, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(error!, style: const TextStyle(color: AppColors.rojo)),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 25),
                    PrimaryButton(
                      text: 'INGRESAR',
                      cargando: cargando,
                      onPressed: iniciarSesion,
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('¿No tienes cuenta?'),
                        TextButton(
                          onPressed: cargando
                              ? null
                              : () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(builder: (_) => const RegisterPage()),
                                  ),
                          child: const Text('Registrarse'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
