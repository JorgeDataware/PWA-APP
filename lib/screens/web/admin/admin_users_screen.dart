import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../core/utils.dart';
import '../../../models/user.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/user_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<User>? _users;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final users = await UserService.getUsers();
      if (mounted) setState(() { _users = users; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _delete(User user) async {
    final currentUserId = context.read<AuthProvider>().user?.id;
    if (user.id == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No puedes eliminar tu propia cuenta desde aquí')),
      );
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text('¿Eliminar a "${user.fullName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await UserService.deleteUser(user.id);
      setState(() => _users?.removeWhere((u) => u.id == user.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario eliminado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  void _openForm([User? user]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _UserForm(
          user: user,
          onSaved: (saved) {
            Navigator.pop(ctx);
            if (user == null) {
              setState(() => _users?.insert(0, saved));
            } else {
              setState(() {
                final idx = _users?.indexWhere((u) => u.id == saved.id) ?? -1;
                if (idx >= 0) _users![idx] = saved;
              });
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de usuarios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () { setState(() { _loading = true; _error = null; }); _load(); },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo usuario'),
        backgroundColor: AppTheme.primary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppTheme.error)))
              : _users == null || _users!.isEmpty
                  ? const Center(
                      child: Text('Sin usuarios', style: TextStyle(color: AppTheme.textSecondary)),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _users!.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final u = _users![i];
                        final isCurrentUser = u.id == context.read<AuthProvider>().user?.id;
                        return Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: u.isAdmin
                                  ? AppTheme.primary.withOpacity(0.15)
                                  : AppTheme.accent.withOpacity(0.1),
                              child: Text(
                                u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : '?',
                                style: TextStyle(
                                  color: u.isAdmin ? AppTheme.primary : AppTheme.accent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  u.fullName,
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                if (isCurrentUser) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accent.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'Tú',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.accent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(u.email, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                Row(
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: u.isAdmin
                                            ? AppTheme.primary.withOpacity(0.15)
                                            : AppTheme.accent.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: u.isAdmin
                                              ? AppTheme.primary.withOpacity(0.4)
                                              : AppTheme.accent.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Text(
                                        u.role,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: u.isAdmin ? AppTheme.primary : AppTheme.accent,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (u.createdAt != null) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        formatDate(u.createdAt!),
                                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: AppTheme.primary, size: 20),
                                  onPressed: () => _openForm(u),
                                  tooltip: 'Editar',
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: isCurrentUser ? AppTheme.textSecondary : AppTheme.error,
                                    size: 20,
                                  ),
                                  onPressed: isCurrentUser ? null : () => _delete(u),
                                  tooltip: 'Eliminar',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

class _UserForm extends StatefulWidget {
  final User? user;
  final void Function(User) onSaved;

  const _UserForm({this.user, required this.onSaved});

  @override
  State<_UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<_UserForm> {
  final _formKey = GlobalKey<FormState>();
  late final _fullNameCtrl = TextEditingController(text: widget.user?.fullName);
  late final _usernameCtrl = TextEditingController(text: widget.user?.username);
  late final _emailCtrl = TextEditingController(text: widget.user?.email);
  final _passwordCtrl = TextEditingController();
  late int _role = widget.user?.isAdmin == true ? 1 : 2;
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      User saved;
      if (widget.user == null) {
        saved = await UserService.createUser(
          fullName: _fullNameCtrl.text.trim(),
          username: _usernameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          role: _role,
        );
      } else {
        saved = await UserService.updateUser(
          widget.user!.id,
          fullName: _fullNameCtrl.text.trim(),
          username: _usernameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text.isEmpty ? null : _passwordCtrl.text,
          role: _role,
        );
      }
      widget.onSaved(saved);
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                widget.user == null ? 'Nuevo usuario' : 'Editar usuario',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.error.withOpacity(0.4)),
              ),
              child: Text(_error!, style: const TextStyle(color: AppTheme.error, fontSize: 13)),
            ),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _fullNameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre completo *'),
                  validator: (v) => v!.trim().isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _usernameCtrl,
                  decoration: const InputDecoration(labelText: 'Username *'),
                  autocorrect: false,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requerido';
                    if (v.trim().length < 3) return 'Mínimo 3 caracteres';
                    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v.trim())) return 'Solo letras, números y _';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email *'),
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requerido';
                    if (!v.contains('@')) return 'Email inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: widget.user == null ? 'Contraseña *' : 'Nueva contraseña (opcional)',
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (widget.user == null && (v == null || v.isEmpty)) return 'Requerido';
                    if (v != null && v.isNotEmpty && v.length < 6) return 'Mínimo 6 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _role,
                  decoration: const InputDecoration(labelText: 'Rol'),
                  dropdownColor: AppTheme.cardBg,
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Admin')),
                    DropdownMenuItem(value: 2, child: Text('User')),
                  ],
                  onChanged: (v) => setState(() => _role = v!),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(widget.user == null ? 'Crear usuario' : 'Guardar cambios'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
