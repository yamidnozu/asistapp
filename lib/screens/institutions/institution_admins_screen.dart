import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/institution_provider.dart';
import '../../widgets/components/clarity_components.dart';
import '../../theme/theme_extensions.dart';
import '../../models/user.dart';
import 'create_institution_admin_screen.dart';


class InstitutionAdminsScreen extends StatefulWidget {
  final String institutionId;

  const InstitutionAdminsScreen({super.key, required this.institutionId});

  @override
  State<InstitutionAdminsScreen> createState() => _InstitutionAdminsScreenState();
}

class _InstitutionAdminsScreenState extends State<InstitutionAdminsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAdmins();
    });
  }

  Future<void> _loadAdmins() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (authProvider.accessToken != null) {
      await userProvider.loadAdminsByInstitution(authProvider.accessToken!, widget.institutionId);
    }
  }

  Future<void> _removeAdmin(User user) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Administrador'),
        content: Text('¿Deseas remover el rol de administrador a ${user.nombreCompleto}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Remover')),
        ],
      ),
    );

    if (confirmed != true) return;

    if (authProvider.accessToken != null) {
      final success = await userProvider.removeAdminFromInstitution(authProvider.accessToken!, widget.institutionId, user.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Administrador removido correctamente')));
        await _loadAdmins();
      }
    }
  }

  void _openAddAdminSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final colors = context.colors;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.person_add, color: colors.primary),
                title: const Text('Crear Nuevo Administrador'),
                onTap: () {
                  Navigator.of(context).pop();
                  // Obtener institución para pasar al formulario
                  final institutionProvider = Provider.of<InstitutionProvider>(context, listen: false);
                  final institution = institutionProvider.institutions.firstWhere((i) => i.id == widget.institutionId);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CreateInstitutionAdminScreen(institution: institution)),
                  ).then((_) => _loadAdmins());
                },
              ),
              ListTile(
                leading: Icon(Icons.person_search, color: colors.primary),
                title: const Text('Asignar Usuario Existente'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showAssignExistingUserDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAssignExistingUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AssignExistingUserDialog(institutionId: widget.institutionId, onAssigned: () async {
        await _loadAdmins();
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        title: Text(
          'Administradores de Institución',
          style: context.textStyles.headlineMedium,
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _loadAdmins,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Lista de administradores
            if (userProvider.isLoading && userProvider.users.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (userProvider.hasError)
              SliverFillRemaining(
                child: ClarityEmptyState(
                  icon: Icons.error_outline,
                  title: 'Error al cargar administradores',
                  subtitle: userProvider.errorMessage ?? 'Error desconocido',
                  action: ElevatedButton.icon(
                    onPressed: _loadAdmins,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ),
              )
            else if (userProvider.users.isEmpty)
              SliverFillRemaining(
                child: ClarityEmptyState(
                  icon: Icons.group_off,
                  title: 'No hay administradores',
                  subtitle: 'Agrega administradores a esta institución',
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.all(context.spacing.screenPadding),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= userProvider.users.length) {
                        if (userProvider.hasMoreData && !userProvider.isLoadingMore) {
                          // Trigger load more when reaching the end
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            if (authProvider.accessToken != null && userProvider.hasMoreData && !userProvider.isLoadingMore) {
                              userProvider.loadUsersByInstitution(authProvider.accessToken!, widget.institutionId);
                            }
                          });
                        }
                        return userProvider.isLoadingMore
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : const SizedBox.shrink();
                      }

                      final user = userProvider.users[index];
                      return Padding(
                        padding: EdgeInsets.only(bottom: context.spacing.md),
                        child: _buildAdminCard(user, context),
                      );
                    },
                    childCount: userProvider.users.length + (userProvider.hasMoreData ? 1 : 0),
                  ),
                ),
              ),
          ],
        ),
      ),

      // Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddAdminSheet,
        backgroundColor: context.colors.primary,
        child: Icon(
          Icons.add,
          color: context.colors.getTextColorForBackground(context.colors.primary),
        ),
      ),
    );
  }

  Widget _buildAdminCard(User user, BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final textStyles = context.textStyles;

    return ClarityCard(
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: colors.primary.withValues(alpha: 0.1),
            child: Text(
              user.nombres.isNotEmpty ? user.nombres[0].toUpperCase() : '?',
              style: textStyles.bodyMedium.withColor(colors.primary),
            ),
          ),
          SizedBox(width: spacing.sm),
          Expanded(
            child: Text(
              user.nombreCompleto,
              style: textStyles.titleMedium.bold,
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.email, size: 16, color: colors.textSecondary),
              SizedBox(width: spacing.xs),
              Expanded(
                child: Text(
                  user.email,
                  style: textStyles.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (user.telefono != null) ...[
            SizedBox(height: spacing.xs),
            Row(
              children: [
                Icon(Icons.phone, size: 16, color: colors.textSecondary),
                SizedBox(width: spacing.xs),
                Expanded(
                  child: Text(
                    user.telefono!,
                    style: textStyles.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClarityActionButton(
            icon: Icons.key,
            tooltip: 'Cambiar contraseña',
            color: colors.primary,
            onPressed: () => _showChangePasswordDialog(context, user),
          ),
          SizedBox(width: spacing.sm),
          ClarityActionButton(
            icon: Icons.remove_circle,
            tooltip: 'Remover administrador',
            color: colors.error,
            onPressed: () => _removeAdmin(user),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, User user) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ChangePasswordDialog(user: user, onSaved: () async {
        // Recargar lista después de cambio de contraseña
        await _loadAdmins();
      }),
    );
  }

}

class _ChangePasswordDialog extends StatefulWidget {
  final User user;
  final VoidCallback? onSaved;

  const _ChangePasswordDialog({required this.user, this.onSaved});

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      if (authProvider.accessToken == null) throw Exception('No hay sesión activa');

      final success = await userProvider.changeUserPassword(
        authProvider.accessToken!,
        widget.user.id,
        _newPasswordController.text.trim(),
      );

      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Contraseña de ${widget.user.nombreCompleto} cambiada correctamente')));
        widget.onSaved?.call();
      } else {
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al cambiar la contraseña')));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return AlertDialog(
      title: Text('Cambiar contraseña - ${widget.user.nombreCompleto}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Nueva contraseña'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'La contraseña es requerida';
                if (value.trim().length < 8) return 'La contraseña debe tener al menos 8 caracteres';
                return null;
              },
            ),
            SizedBox(height: spacing.md),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirmar contraseña'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'La confirmación es requerida';
                if (value.trim() != _newPasswordController.text.trim()) return 'Las contraseñas no coinciden';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _isSaving ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2,)) : const Text('Guardar'),
        ),
      ],
    );
  }
}


class AssignExistingUserDialog extends StatefulWidget {
  final String institutionId;
  final VoidCallback? onAssigned;

  const AssignExistingUserDialog({super.key, required this.institutionId, this.onAssigned});

  @override
  State<AssignExistingUserDialog> createState() => _AssignExistingUserDialogState();
}

class _AssignExistingUserDialogState extends State<AssignExistingUserDialog> {
  final _searchController = TextEditingController();
  List<User> _results = [];
  bool _isSearching = false;

  Future<void> _search(String query) async {
    setState(() => _isSearching = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      // Usar el provider para búsqueda remota (evita acceder a propiedades privadas)
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final users = await userProvider.searchUsersRemote(authProvider.accessToken!, search: query, limit: 10);
      final response = users;
      if (response != null) {
        // Filtrar usuarios que no son admins activos en ninguna institución
        final candidates = response.where((u) => u.instituciones.every((inst) => !inst.activo || inst.rolEnInstitucion != 'admin')).toList();
        setState(() => _results = candidates);
      }
    } catch (e) {
      debugPrint('Error buscando usuarios: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _assign(User user) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (authProvider.accessToken != null) {
      final success = await userProvider.assignAdminToInstitution(authProvider.accessToken!, widget.institutionId, user.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Administrador asignado correctamente')));
        widget.onAssigned?.call();
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Asignar Usuario Existente'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(hintText: 'Buscar por nombre o email'),
            onSubmitted: _search,
          ),
          const SizedBox(height: 12),
          if (_isSearching) const CircularProgressIndicator(),
          if (!_isSearching && _results.isNotEmpty)
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final user = _results[index];
                  return ListTile(
                    title: Text(user.nombreCompleto),
                    subtitle: Text(user.email),
                    trailing: TextButton(onPressed: () => _assign(user), child: const Text('Asignar')),
                  );
                },
              ),
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
      ],
    );
  }
}
