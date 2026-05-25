import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _editing = false;
  bool _loading = false;
  String? _error;
  String? _success;
  User? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await UserService.getProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _fullNameCtrl.text = profile.fullName;
          _usernameCtrl.text = profile.username;
          _emailCtrl.text = profile.email;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; _success = null; });
    try {
      final updated = await UserService.updateProfile(
        fullName: _fullNameCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.isEmpty ? null : _passwordCtrl.text,
      );
      if (!mounted) return;
      context.read<AuthProvider>().updateUser(updated);
      if (mounted) {
        setState(() {
          _profile = updated;
          _editing = false;
          _success = 'Perfil actualizado correctamente';
          _passwordCtrl.clear();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        actions: [
          if (!_editing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() { _editing = true; _success = null; }),
              tooltip: 'Editar perfil',
            )
          else
            TextButton(
              onPressed: () {
                setState(() {
                  _editing = false;
                  _error = null;
                  if (_profile != null) {
                    _fullNameCtrl.text = _profile!.fullName;
                    _usernameCtrl.text = _profile!.username;
                    _emailCtrl.text = _profile!.email;
                    _passwordCtrl.clear();
                  }
                });
              },
              child: const Text('Cancelar'),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppTheme.primary.withOpacity(0.15),
                  child: Text(
                    auth.user?.fullName.isNotEmpty == true
                        ? auth.user!.fullName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  auth.user?.fullName ?? '',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: auth.user?.isAdmin == true
                        ? AppTheme.primary.withOpacity(0.15)
                        : AppTheme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: auth.user?.isAdmin == true
                          ? AppTheme.primary.withOpacity(0.4)
                          : AppTheme.accent.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    auth.user?.role ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: auth.user?.isAdmin == true
                          ? AppTheme.primary
                          : AppTheme.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_profile?.createdAt != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Miembro desde ${formatDate(_profile!.createdAt!)}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 28),
                if (_success != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.success.withOpacity(0.4)),
                    ),
                    child: Text(
                      _success!,
                      style: const TextStyle(color: AppTheme.success, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (_error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.error.withOpacity(0.4)),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppTheme.error, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 16),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _fullNameCtrl,
                        enabled: _editing,
                        decoration: const InputDecoration(
                          labelText: 'Nombre completo',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: (v) => v!.trim().isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _usernameCtrl,
                        enabled: _editing,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.alternate_email),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Requerido';
                          if (v.trim().length < 3) return 'Mínimo 3 caracteres';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailCtrl,
                        enabled: _editing,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Requerido';
                          if (!v.contains('@')) return 'Email inválido';
                          return null;
                        },
                      ),
                      if (_editing) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: 'Nueva contraseña (opcional)',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            hintText: 'Dejar vacío para no cambiar',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              ),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) {
                            if (v != null && v.isNotEmpty && v.length < 6) {
                              return 'Mínimo 6 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loading ? null : _save,
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Guardar cambios'),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    await context.read<AuthProvider>().logout();
                    if (context.mounted) context.go('/login');
                  },
                  icon: const Icon(Icons.logout, color: AppTheme.error),
                  label: const Text('Cerrar sesión', style: TextStyle(color: AppTheme.error)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.error),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
