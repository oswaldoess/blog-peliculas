import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../core/navegacion.dart';
import '../core/session_manager.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../widgets/avatar.dart';
import '../widgets/estado_vista.dart';

/// Panel exclusivo del administrador (la API también lo valida con 403).
class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final _servicio = UserService();
  late Future<List<UserModel>> _futuro;

  int get _miId => SessionManager.instance.usuario?.id ?? 0;

  @override
  void initState() {
    super.initState();
    _futuro = _servicio.obtenerUsuarios();
  }

  void _recargar() {
    setState(() {
      _futuro = _servicio.obtenerUsuarios();
    });
  }

  Future<void> _accion(UserModel u, String accion) async {
    try {
      switch (accion) {
        case 'rol':
          await _servicio.actualizarUsuario(u.id, {
            'tip_usu': u.esAdmin ? UserModel.autor : UserModel.admin,
          });
          mostrarMensaje(u.esAdmin ? '${u.nombre} ahora es Autor' : '${u.nombre} ahora es Administrador');
          break;
        case 'estado':
          await _servicio.actualizarUsuario(u.id, {'activo': !u.activo});
          mostrarMensaje(u.activo ? 'Cuenta desactivada' : 'Cuenta activada');
          break;
        case 'eliminar':
          final ok = await showDialog<bool>(
            context: context,
            builder: (c) => AlertDialog(
              title: Text('¿Eliminar a ${u.nombre}?'),
              content: const Text('Se borrarán también sus reseñas, comentarios y mensajes.'),
              actions: [
                TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Cancelar')),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.rojo, foregroundColor: Colors.white),
                  onPressed: () => Navigator.of(c).pop(true),
                  child: const Text('Eliminar'),
                ),
              ],
            ),
          );
          if (ok != true) return;
          await _servicio.eliminarUsuario(u.id);
          mostrarMensaje('Usuario eliminado');
          break;
      }
      _recargar();
    } catch (e) {
      mostrarMensaje(e.toString(), error: true);
    }
  }

  Future<void> _crear() async {
    final creado = await showDialog<UserModel>(
      context: context,
      builder: (_) => const _CrearUsuarioDialog(),
    );
    if (creado != null) {
      mostrarMensaje('Usuario ${creado.nombre} creado');
      _recargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Administración de usuarios')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _crear,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Crear usuario'),
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _futuro,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return EstadoVista.error(snapshot.error!, _recargar);
          final usuarios = snapshot.data ?? const <UserModel>[];
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
            itemCount: usuarios.length,
            itemBuilder: (context, i) {
              final u = usuarios[i];
              final soyYo = u.id == _miId;
              return Card(
                color: AppColors.superficie,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: Avatar(nombre: u.nombre),
                  title: Text(
                    soyYo ? '${u.nombre} (tú)' : u.nombre,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      decoration: u.activo ? null : TextDecoration.lineThrough,
                    ),
                  ),
                  subtitle: Text('${u.correo ?? ''}\n${u.rol}${u.activo ? '' : ' · desactivado'}'),
                  isThreeLine: true,
                  trailing: soyYo
                      ? const Icon(Icons.shield_rounded, color: AppColors.dorado)
                      : PopupMenuButton<String>(
                          onSelected: (a) => _accion(u, a),
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'rol',
                              child: Text(u.esAdmin ? 'Cambiar a Autor' : 'Hacer Administrador'),
                            ),
                            PopupMenuItem(
                              value: 'estado',
                              child: Text(u.activo ? 'Desactivar cuenta' : 'Activar cuenta'),
                            ),
                            const PopupMenuItem(
                              value: 'eliminar',
                              child: Text('Eliminar', style: TextStyle(color: AppColors.rojo)),
                            ),
                          ],
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CrearUsuarioDialog extends StatefulWidget {
  const _CrearUsuarioDialog();

  @override
  State<_CrearUsuarioDialog> createState() => _CrearUsuarioDialogState();
}

class _CrearUsuarioDialogState extends State<_CrearUsuarioDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _password = TextEditingController();
  int _tipo = UserModel.autor;
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final u = await UserService().crearUsuario(
        nombre: _nombre.text,
        correo: _correo.text,
        password: _password.text,
        tipoUsuario: _tipo,
      );
      if (mounted) Navigator.of(context).pop(u);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Crear usuario'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nombre,
                decoration: AppTheme.campo('Nombre', icono: Icons.person_outline_rounded),
                validator: (v) => (v == null || v.trim().length < 2) ? 'Ingresa el nombre' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _correo,
                decoration: AppTheme.campo('Correo', icono: Icons.alternate_email_rounded),
                validator: AuthService.validarCorreo,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: AppTheme.campo('Contraseña temporal', icono: Icons.lock_outline_rounded),
                validator: AuthService.validarPassword,
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Autor'),
                    selected: _tipo == UserModel.autor,
                    onSelected: (_) => setState(() => _tipo = UserModel.autor),
                  ),
                  ChoiceChip(
                    label: const Text('Administrador'),
                    selected: _tipo == UserModel.admin,
                    onSelected: (_) => setState(() => _tipo = UserModel.admin),
                  ),
                ],
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(_error!, style: const TextStyle(color: AppColors.rojo)),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _guardando ? null : _guardar,
          child: Text(_guardando ? 'Creando…' : 'Crear'),
        ),
      ],
    );
  }
}
