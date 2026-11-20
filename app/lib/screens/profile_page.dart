import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../core/navegacion.dart';
import '../core/session_manager.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/post_service.dart';
import '../services/user_service.dart';
import '../utils/formatos.dart';
import '../widgets/avatar.dart';
import 'admin_users_page.dart';
import 'pedidos_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _sesion = SessionManager.instance;
  final _auth = AuthService();
  List<PostModel>? _misPosts;

  @override
  void initState() {
    super.initState();
    _sesion.addListener(_alCambiarSesion);
    _cargarEstadisticas();
  }

  @override
  void dispose() {
    _sesion.removeListener(_alCambiarSesion);
    super.dispose();
  }

  void _alCambiarSesion() {
    if (mounted) setState(() {});
  }

  Future<void> _cargarEstadisticas() async {
    try {
      final posts = await PostService().obtenerPosts(mios: true);
      if (mounted) setState(() => _misPosts = posts);
    } catch (_) {}
  }

  Future<void> _cerrarSesion() async {
    await _auth.logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    mostrarMensaje('Sesión cerrada de forma segura');
  }

  Future<void> _editarPerfil(UserModel u) async {
    final actualizado = await showModalBottomSheet<UserModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.superficie,
      builder: (_) => _EditarPerfilSheet(usuario: u),
    );
    if (actualizado != null) {
      _sesion.actualizarUsuario(actualizado);
      mostrarMensaje('Perfil actualizado');
    }
  }

  Future<void> _cambiarPassword() async {
    final mensaje = await showDialog<String>(
      context: context,
      builder: (_) => const _CambiarPasswordDialog(),
    );
    if (mensaje != null) mostrarMensaje(mensaje);
  }

  @override
  Widget build(BuildContext context) {
    final u = _sesion.usuario;
    if (u == null) return const SizedBox.shrink();

    final posts = _misPosts;
    final calificadas = posts?.where((p) => p.totalValoraciones > 0).toList() ?? const <PostModel>[];
    final promedio = calificadas.isEmpty
        ? 0.0
        : calificadas.map((p) => p.promedio).reduce((a, b) => a + b) / calificadas.length;
    final comentarios = posts?.fold<int>(0, (s, p) => s + p.totalComentarios) ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
      ),
      body: RefreshIndicator(
        onRefresh: _cargarEstadisticas,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Center(child: Avatar(nombre: u.nombre, radio: 46)),
            const SizedBox(height: 14),
            Text(
              u.nombre,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              u.correo ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textoSuave),
            ),
            const SizedBox(height: 10),
            Center(
              child: Chip(
                avatar: Icon(
                  u.esAdmin ? Icons.shield_rounded : Icons.edit_rounded,
                  size: 16,
                  color: AppColors.azul,
                ),
                label: Text(u.rol),
                side: const BorderSide(color: AppColors.azul),
              ),
            ),
            if (u.bio != null && u.bio!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                '“${u.bio!}”',
                textAlign: TextAlign.center,
                style: const TextStyle(fontStyle: FontStyle.italic, color: AppColors.textoSuave),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                _Dato(valor: posts == null ? '…' : '${posts.length}', etiqueta: 'Reseñas'),
                const SizedBox(width: 10),
                _Dato(valor: calificadas.isEmpty ? '—' : promedio.toStringAsFixed(1), etiqueta: 'Promedio ★'),
                const SizedBox(width: 10),
                _Dato(valor: posts == null ? '…' : '$comentarios', etiqueta: 'Comentarios'),
              ],
            ),
            const SizedBox(height: 22),
            _Opcion(
              icono: Icons.place_outlined,
              titulo: u.ciudad ?? 'Sin ciudad',
              subtitulo: u.creadoEn == null ? null : 'Miembro desde ${Formatos.fecha(u.creadoEn!)}',
            ),
            _Opcion(
              icono: Icons.manage_accounts_outlined,
              titulo: 'Editar perfil',
              onTap: () => _editarPerfil(u),
            ),
            _Opcion(
              icono: Icons.password_rounded,
              titulo: 'Cambiar contraseña',
              subtitulo: 'Cierra tu sesión en otros dispositivos',
              onTap: _cambiarPassword,
            ),
            _Opcion(
              icono: Icons.receipt_long_outlined,
              titulo: 'Mis compras',
              subtitulo: 'Historial de pedidos de la tienda',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const PedidosPage()),
              ),
            ),
            if (u.esAdmin)
              _Opcion(
                icono: Icons.admin_panel_settings_outlined,
                titulo: 'Panel de administración',
                subtitulo: 'Usuarios, roles y accesos',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const AdminUsersPage()),
                ),
              ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _cerrarSesion,
              icon: const Icon(Icons.logout_rounded, color: AppColors.rojo),
              label: const Text('Cerrar sesión', style: TextStyle(color: AppColors.rojo)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.rojo),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  final String valor;
  final String etiqueta;

  const _Dato({required this.valor, required this.etiqueta});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.superficie,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borde),
        ),
        child: Column(
          children: [
            Text(valor, style: AppTheme.titulo(size: 24)),
            Text(etiqueta, style: const TextStyle(fontSize: 12, color: AppColors.textoSuave)),
          ],
        ),
      ),
    );
  }
}

class _Opcion extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String? subtitulo;
  final VoidCallback? onTap;

  const _Opcion({required this.icono, required this.titulo, this.subtitulo, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.superficie,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: Icon(icono, color: AppColors.azul),
          title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: subtitulo == null ? null : Text(subtitulo!),
          trailing: onTap == null ? null : const Icon(Icons.chevron_right_rounded),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _EditarPerfilSheet extends StatefulWidget {
  final UserModel usuario;

  const _EditarPerfilSheet({required this.usuario});

  @override
  State<_EditarPerfilSheet> createState() => _EditarPerfilSheetState();
}

class _EditarPerfilSheetState extends State<_EditarPerfilSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.usuario.nombre);
  late final _correo = TextEditingController(text: widget.usuario.correo ?? '');
  late final _ciudad = TextEditingController(text: widget.usuario.ciudad ?? '');
  late final _bio = TextEditingController(text: widget.usuario.bio ?? '');
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _ciudad.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final actualizado = await UserService().actualizarUsuario(widget.usuario.id, {
        'nom_usr': _nombre.text.trim(),
        'mail': _correo.text.trim().toLowerCase(),
        'dir_usr': _ciudad.text.trim(),
        'bio': _bio.text.trim(),
      });
      if (!mounted) return;
      Navigator.of(context).pop(actualizado);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final teclado = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + teclado),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Editar perfil', style: AppTheme.titulo(size: 22)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombre,
                decoration: AppTheme.campo('Nombre', icono: Icons.person_outline_rounded),
                validator: (v) => (v == null || v.trim().length < 2) ? 'Ingresa tu nombre' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _correo,
                keyboardType: TextInputType.emailAddress,
                decoration: AppTheme.campo('Correo', icono: Icons.alternate_email_rounded),
                validator: AuthService.validarCorreo,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ciudad,
                decoration: AppTheme.campo('Ciudad', icono: Icons.place_outlined),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bio,
                maxLength: 280,
                maxLines: 3,
                decoration: AppTheme.campo('Bio', icono: Icons.short_text_rounded, ayuda: '¿Qué tipo de cine te gusta?'),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_error!, style: const TextStyle(color: AppColors.rojo)),
                ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _guardando ? null : _guardar,
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                child: Text(_guardando ? 'Guardando…' : 'Guardar cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CambiarPasswordDialog extends StatefulWidget {
  const _CambiarPasswordDialog();

  @override
  State<_CambiarPasswordDialog> createState() => _CambiarPasswordDialogState();
}

class _CambiarPasswordDialogState extends State<_CambiarPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _actual = TextEditingController();
  final _nueva = TextEditingController();
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _actual.dispose();
    _nueva.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final mensaje = await AuthService().cambiarPassword(_actual.text, _nueva.text);
      if (!mounted) return;
      Navigator.of(context).pop(mensaje);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cambiar contraseña'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _actual,
              obscureText: true,
              decoration: AppTheme.campo('Contraseña actual', icono: Icons.lock_outline_rounded),
              validator: (v) => (v == null || v.isEmpty) ? 'Requerida' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nueva,
              obscureText: true,
              decoration: AppTheme.campo('Contraseña nueva', icono: Icons.lock_reset_rounded),
              validator: AuthService.validarPassword,
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(_error!, style: const TextStyle(color: AppColors.rojo)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _guardando ? null : _guardar,
          child: Text(_guardando ? 'Guardando…' : 'Guardar'),
        ),
      ],
    );
  }
}
