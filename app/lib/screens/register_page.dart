import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/auth_background.dart';
import '../widgets/auth_card.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController correoController = TextEditingController();
  final TextEditingController ciudadController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmarController = TextEditingController();
  final AuthService authService = AuthService();

  bool ocultarPassword = true;
  bool cargando = false;
  String? error;

  @override
  void initState() {
    super.initState();
    // Actualiza la lista de requisitos mientras se escribe.
    passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    nombreController.dispose();
    correoController.dispose();
    ciudadController.dispose();
    passwordController.dispose();
    confirmarController.dispose();
    super.dispose();
  }

  Future<void> registrarUsuario() async {
    setState(() => error = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => cargando = true);
    try {
      await authService.registrar(
        nombre: nombreController.text,
        correo: correoController.text,
        password: passwordController.text,
        ciudad: ciudadController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => cargando = false);
    }
  }

  Widget _requisito(String texto, bool cumple) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(
            cumple ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: cumple ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            texto,
            style: TextStyle(fontSize: 12.5, color: cumple ? Colors.green.shade700 : Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = passwordController.text;
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
                    const Icon(Icons.person_add, size: 65, color: AppColors.azul),
                    const SizedBox(height: 15),
                    const Text(
                      'CREAR CUENTA',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                        color: AppColors.marino,
                      ),
                    ),
                    const SizedBox(height: 25),
                    CustomTextField(
                      controller: nombreController,
                      label: 'Nombre completo',
                      prefixIcon: Icons.person,
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.trim().length < 2) ? 'Ingresa tu nombre' : null,
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      controller: correoController,
                      label: 'Correo electrónico',
                      prefixIcon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: AuthService.validarCorreo,
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      controller: ciudadController,
                      label: 'Ciudad (opcional)',
                      prefixIcon: Icons.place,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      controller: passwordController,
                      label: 'Contraseña',
                      prefixIcon: Icons.lock,
                      obscureText: ocultarPassword,
                      textInputAction: TextInputAction.next,
                      validator: AuthService.validarPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          ocultarPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        ),
                        onPressed: () => setState(() => ocultarPassword = !ocultarPassword),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 6, 0, 0),
                      child: Column(
                        children: [
                          _requisito('Al menos 8 caracteres', AuthService.tieneLongitud(p)),
                          _requisito('Al menos una letra', AuthService.tieneLetra(p)),
                          _requisito('Al menos un número', AuthService.tieneNumero(p)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      controller: confirmarController,
                      label: 'Confirmar contraseña',
                      prefixIcon: Icons.lock_reset,
                      obscureText: ocultarPassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => cargando ? null : registrarUsuario(),
                      validator: (v) => v != passwordController.text ? 'Las contraseñas no coinciden' : null,
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      Text(error!, style: const TextStyle(color: AppColors.rojo)),
                    ],
                    const SizedBox(height: 25),
                    PrimaryButton(
                      text: 'REGISTRARME',
                      cargando: cargando,
                      onPressed: registrarUsuario,
                    ),
                    const SizedBox(height: 15),
                    TextButton(
                      onPressed: cargando ? null : () => Navigator.pop(context),
                      child: const Text('Ya tengo una cuenta'),
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
