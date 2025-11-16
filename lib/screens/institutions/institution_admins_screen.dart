import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/institution_provider.dart';
import '../../widgets/components/index.dart';
import '../../theme/theme_extensions.dart';
import '../../models/user.dart';
import '../../services/user_service.dart';
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

    return ClarityManagementPage(
      title: 'Administradores de Institución',
      isLoading: userProvider.isLoading,
      hasError: userProvider.hasError,
      errorMessage: userProvider.errorMessage,
      itemCount: userProvider.users.length,
      itemBuilder: (context, index) {
        if (index >= userProvider.users.length) {
          return userProvider.isLoadingMore
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              : const SizedBox.shrink();
        }

        final user = userProvider.users[index];
        return _buildAdminCard(user, context);
      },
      onRefresh: _loadAdmins,
      scrollController: _scrollController,
      hasMoreData: userProvider.hasMoreData,
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddAdminSheet,
        backgroundColor: context.colors.primary,
        child: Icon(
          Icons.add,
          color: context.colors.getTextColorForBackground(context.colors.primary),
        ),
      ),
      emptyStateWidget: ClarityEmptyState(
        icon: Icons.group_off,
        title: 'No hay administradores',
        subtitle: 'Agrega administradores a esta institución',
      ),
    );
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
              user.inicial,
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
          if (user.telefono != null)
            SizedBox(height: spacing.xs),
          if (user.telefono != null)
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

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<bool> _save() async {
    // ClarityFormDialog validates before calling onSave, keep guard
    if (!_formKey.currentState!.validate()) return false;

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Contraseña de ${widget.user.nombreCompleto} cambiada correctamente')));
        widget.onSaved?.call();
        return true;
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }

    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al cambiar la contraseña')));
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return ClarityFormDialog(
      title: Text('Cambiar contraseña - ${widget.user.nombreCompleto}'),
      formKey: _formKey,
      onSave: _save,
      saveLabel: 'Guardar',
      cancelLabel: 'Cancelar',
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
  final ScrollController _scrollController = ScrollController();

  List<User> _allUsers = [];
  List<User> _filteredUsers = [];
  bool _isLoading = false;
  bool _hasMoreData = true;
  int _currentPage = 1;
  static const int _pageSize = 20;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    _loadInitialUsers();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _scrollController.removeListener(_onScroll);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _searchQuery = query;
      _filterUsers();
    });
  }

  void _filterUsers() {
    if (_searchQuery.isEmpty) {
      _filteredUsers = List.from(_allUsers);
    } else {
      _filteredUsers = _allUsers.where((user) {
        final fullName = user.nombreCompleto.toLowerCase();
        final email = user.email.toLowerCase();
        return fullName.contains(_searchQuery) || email.contains(_searchQuery);
      }).toList();
    }
  }

  Future<void> _loadInitialUsers() async {
    setState(() => _isLoading = true);
    try {
      _currentPage = 1;
      await _loadUsersPage(_currentPage, clearExisting: true);
    } catch (e) {
      debugPrint('Error cargando usuarios iniciales: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar usuarios: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMoreUsers() async {
    if (_isLoading || !_hasMoreData) return;

    setState(() => _isLoading = true);
    try {
      _currentPage++;
      await _loadUsersPage(_currentPage);
    } catch (e) {
      debugPrint('Error cargando más usuarios: $e');
      _currentPage--; // Revertir en caso de error
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadUsersPage(int page, {bool clearExisting = false}) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.accessToken == null) return;

    try {
      // Crear instancia del servicio directamente
      final userService = UserService();
      final response = await userService.getAllUsers(
        authProvider.accessToken!,
        page: page,
        limit: _pageSize,
      );

      if (response != null && response.users.isNotEmpty && mounted) {
        // Filtrar usuarios que son administradores de institución
        final candidates = response.users.where((u) => u.esAdminInstitucion).toList();

        setState(() {
          if (clearExisting) {
            _allUsers = candidates;
          } else {
            _allUsers.addAll(candidates);
          }
          _hasMoreData = candidates.length == _pageSize;
          _filterUsers();
        });
      } else {
        setState(() => _hasMoreData = false);
      }
    } catch (e) {
      debugPrint('Error cargando usuarios: $e');
      setState(() => _hasMoreData = false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreUsers();
    }
  }

  Future<void> _assign(User user) async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      if (authProvider.accessToken == null) {
        throw Exception('No hay sesión activa');
      }

      final success = await userProvider.assignAdminToInstitution(
        authProvider.accessToken!,
        widget.institutionId,
        user.id,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.nombreCompleto} asignado como administrador')),
        );
        widget.onAssigned?.call();
        Navigator.of(context).pop();
      } else {
        throw Exception('No se pudo asignar el administrador');
      }
    } catch (e) {
      debugPrint('Error asignando administrador: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al asignar administrador: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Asignar Administrador de Institución'),
      content: SizedBox(
        width: 500,
        height: 600,
        child: Column(
          children: [
            // Campo de búsqueda
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar administradores...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged();
                        },
                      )
                    : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).cardColor,
                ),
                textInputAction: TextInputAction.search,
              ),
            ),
            const SizedBox(height: 12),

            // Estado de carga inicial
            if (_isLoading && _allUsers.isEmpty)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            // Lista de usuarios
            else
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  // quitar padding horizontal global para que las filas se alineen exactamente
                  padding: EdgeInsets.zero,
                  itemCount: _filteredUsers.length + (_hasMoreData ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Item de carga al final
                    if (index == _filteredUsers.length) {
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: const Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        ),
                      );
                    }

                    final user = _filteredUsers[index];
                    final alreadyAssigned = user.instituciones.any((inst) => inst.id == widget.institutionId);

                    return Card(
                      // mantener sólo margen vertical; el padding lo controlamos en el contenido
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: (_isLoading || alreadyAssigned) ? null : () => _assign(user),
                        child: Padding(
                          // padding horizontal más reducido para evitar columna en blanco
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Avatar eliminado intencionalmente para ajustar layout

                              // Información del usuario
                              Expanded(
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Nombre completo
                                      Text(
                                        user.nombreCompleto,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          height: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 2),

                                      // Email
                                      Text(
                                        user.email,
                                        style: TextStyle(
                                          color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                                          fontSize: 13,
                                          height: 1.2,
                                        ),
                                      ),

                                      // Instituciones asignadas
                                      if (user.instituciones.any((inst) => inst.activo)) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          'En: ${user.instituciones.where((inst) => inst.activo).map((inst) => inst.nombre).join(', ')}',
                                          style: TextStyle(
                                            color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.8),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            height: 1.2,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                              ),

                              const SizedBox(width: 12),

                              // Botón de asignar (deshabilitado si ya está asignado)
                              SizedBox(
                                height: 36,
                                child: ElevatedButton(
                                  onPressed: (_isLoading || alreadyAssigned) ? null : () => _assign(user),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  child: Text(
                                    alreadyAssigned ? 'Ya asignado' : 'Asignar',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Mensaje cuando no hay usuarios
            if (!_isLoading && _allUsers.isEmpty)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 56, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'No hay administradores disponibles',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

            // Mensaje cuando el filtro no encuentra resultados
            if (!_isLoading && _allUsers.isNotEmpty && _filteredUsers.isEmpty && _searchQuery.isNotEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 56, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'No se encontraron resultados',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
