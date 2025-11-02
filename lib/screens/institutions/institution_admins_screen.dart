import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/institution_provider.dart';
import '../../widgets/common/management_scaffold.dart';
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

    return ManagementScaffold(
      title: 'Administradores',
      isLoading: userProvider.isLoading && userProvider.users.isEmpty,
      hasError: userProvider.hasError,
      errorMessage: userProvider.errorMessage ?? 'Error desconocido',
      itemCount: userProvider.users.length,
      itemBuilder: (context, index) {
        final user = userProvider.users[index];
        return Card(
          margin: EdgeInsets.only(bottom: context.spacing.xs),
          child: ListTile(
            leading: CircleAvatar(child: Text(user.nombres.isNotEmpty ? user.nombres[0] : '?')),
            title: Text(user.nombreCompleto),
            subtitle: Text(user.email),
            trailing: IconButton(
              icon: Icon(Icons.remove_circle, color: context.colors.error),
              onPressed: () => _removeAdmin(user),
            ),
          ),
        );
      },
      hasMoreData: userProvider.hasMoreData,
      onRefresh: _loadAdmins,
      scrollController: _scrollController,
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddAdminSheet,
        backgroundColor: context.colors.primary,
        child: Icon(Icons.add, color: context.colors.getTextColorForBackground(context.colors.primary)),
      ),
      onPageChange: (page) async {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.accessToken != null) {
          await userProvider.loadUsersByInstitution(authProvider.accessToken!, widget.institutionId, page: page);
        }
      },
      emptyStateTitle: 'No hay administradores',
      emptyStateMessage: 'Agrega administradores a esta institución',
      emptyStateIcon: Icons.group_off,
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
