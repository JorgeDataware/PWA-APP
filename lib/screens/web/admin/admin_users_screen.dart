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
      if (mounted) setState(() => _users = users);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeStatus(User user) async {
    final currentUserId = context.read<AuthProvider>().user?.id;
    if (user.id == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes deshabilitar tu propia cuenta desde aquí'),
        ),
      );
      return;
    }

    final action = user.isActive ? 'deshabilitar' : 'habilitar';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${user.isActive ? 'Deshabilitar' : 'Habilitar'} usuario'),
        content: Text(
          user.isActive
              ? '¿Deshabilitar a "${user.fullName}"? Se conservará su información, pero no podrá iniciar sesión.'
              : '¿Habilitar a "${user.fullName}"? Podrá iniciar sesión nuevamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              user.isActive ? 'Deshabilitar' : 'Habilitar',
              style: TextStyle(
                color: user.isActive ? AppTheme.error : AppTheme.accent,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final updated = await UserService.setUserStatus(user.id, !user.isActive);
      setState(() {
        final index = _users?.indexWhere((item) => item.id == user.id) ?? -1;
        if (index >= 0) _users![index] = updated;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Usuario ${action}do')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
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
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: _UserForm(
          user: user,
          onSaved: (saved) {
            Navigator.pop(sheetContext);
            setState(() {
              if (user == null) {
                _users?.insert(0, saved);
              } else {
                final index =
                    _users?.indexWhere((item) => item.id == saved.id) ?? -1;
                if (index >= 0) _users![index] = saved;
              }
            });
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
            tooltip: 'Actualizar',
            onPressed: () {
              setState(() {
                _loading = true;
                _error = null;
              });
              _load();
            },
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
          ? Center(
              child: Text(
                _error!,
                style: const TextStyle(color: AppTheme.error),
              ),
            )
          : (_users?.isEmpty ?? true)
          ? const Center(
              child: Text(
                'Sin usuarios',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _users!.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, index) {
                final user = _users![index];
                final isCurrentUser =
                    user.id == context.read<AuthProvider>().user?.id;
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor:
                          (user.isAdmin ? AppTheme.primary : AppTheme.accent)
                              .withValues(alpha: 0.15),
                      child: Text(
                        user.fullName.isEmpty
                            ? '?'
                            : user.fullName[0].toUpperCase(),
                      ),
                    ),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.fullName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (isCurrentUser)
                          const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Text(
                              'Tú',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.accent,
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: _StatusChip(active: user.isActive),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${user.username} · ${user.email}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 3),
                        Wrap(
                          spacing: 8,
                          runSpacing: 3,
                          children: [
                            _InfoChip(
                              label: user.role,
                              color: user.isAdmin
                                  ? AppTheme.primary
                                  : AppTheme.accent,
                            ),
                            if (user.createdAt != null)
                              Text(
                                'Creado: ${formatDate(user.createdAt!)}',
                                style: const TextStyle(fontSize: 11),
                              ),
                            Text(
                              user.lastLoginAt == null
                                  ? 'Sin inicio de sesión'
                                  : 'Último inicio: ${formatDate(user.lastLoginAt!)}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            if (user.mustChangePassword)
                              const _InfoChip(
                                label: 'Cambio de contraseña pendiente',
                                color: AppTheme.error,
                              ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: AppTheme.primary,
                            size: 20,
                          ),
                          onPressed: () => _openForm(user),
                          tooltip: 'Editar',
                        ),
                        IconButton(
                          icon: Icon(
                            user.isActive
                                ? Icons.block_outlined
                                : Icons.check_circle_outline,
                            color: isCurrentUser
                                ? AppTheme.textSecondary
                                : (user.isActive
                                      ? AppTheme.error
                                      : AppTheme.accent),
                            size: 20,
                          ),
                          onPressed: isCurrentUser
                              ? null
                              : () => _changeStatus(user),
                          tooltip: user.isActive ? 'Deshabilitar' : 'Habilitar',
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

class _StatusChip extends StatelessWidget {
  final bool active;
  const _StatusChip({required this.active});

  @override
  Widget build(BuildContext context) => _InfoChip(
    label: active ? 'Activo' : 'Inactivo',
    color: active ? AppTheme.accent : AppTheme.error,
  );
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;
  const _InfoChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
    ),
  );
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
  late int _role = switch (widget.user?.role) {
    'Admin' => 1,
    'Guest' => 3,
    _ => 2,
  };
  late bool _mustChangePassword = widget.user?.mustChangePassword ?? false;
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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final saved = widget.user == null
          ? await UserService.createUser(
              fullName: _fullNameCtrl.text.trim(),
              username: _usernameCtrl.text.trim(),
              email: _emailCtrl.text.trim(),
              password: _passwordCtrl.text,
              role: _role,
              mustChangePassword: _mustChangePassword,
            )
          : await UserService.updateUser(
              widget.user!.id,
              fullName: _fullNameCtrl.text.trim(),
              username: _usernameCtrl.text.trim(),
              email: _emailCtrl.text.trim(),
              password: _passwordCtrl.text.isEmpty ? null : _passwordCtrl.text,
              role: _role,
              mustChangePassword: _mustChangePassword,
            );
      widget.onSaved(saved);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  widget.user == null ? 'Nuevo usuario' : 'Editar usuario',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
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
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppTheme.error),
                ),
              ),
            TextFormField(
              controller: _fullNameCtrl,
              decoration: const InputDecoration(labelText: 'Nombre completo *'),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _usernameCtrl,
              decoration: const InputDecoration(labelText: 'Usuario *'),
              autocorrect: false,
              validator: (value) {
                if (value == null || value.trim().length < 3) {
                  return 'Mínimo 3 caracteres';
                }
                return RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())
                    ? null
                    : 'Solo letras, números y _';
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email *'),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              validator: (value) => value == null || !value.contains('@')
                  ? 'Email inválido'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: widget.user == null
                    ? 'Contraseña *'
                    : 'Nueva contraseña (opcional)',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (value) {
                if (widget.user == null && (value == null || value.isEmpty)) {
                  return 'Requerido';
                }
                return value != null && value.isNotEmpty && value.length < 6
                    ? 'Mínimo 6 caracteres'
                    : null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'Grupo / rol'),
              dropdownColor: AppTheme.cardBg,
              items: const [
                DropdownMenuItem(value: 1, child: Text('Admin')),
                DropdownMenuItem(value: 2, child: Text('User')),
                DropdownMenuItem(value: 3, child: Text('Guest')),
              ],
              onChanged: (value) => setState(() => _role = value!),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _mustChangePassword,
              onChanged: (value) =>
                  setState(() => _mustChangePassword = value ?? false),
              title: const Text('Requiere cambio de contraseña'),
              subtitle: const Text(
                'Estado administrativo registrado para la práctica.',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      widget.user == null ? 'Crear usuario' : 'Guardar cambios',
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}
