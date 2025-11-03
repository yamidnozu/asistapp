import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/theme_extensions.dart';
import '../../widgets/components/index.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounceTimer;
  
  // Estado centralizado de filtros
  String _searchQuery = '';
  String _selectedRoleFilter = '';
  bool? _statusFilter = true; // true = activos, false = inactivos, null = todos
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // Configurar filtro automático para admin_institucion
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userRole = authProvider.user?['rol'] as String?;
      if (userRole == 'admin_institucion') {
        // Para admin_institucion, no filtrar automáticamente por rol
        // Permitir que elija manualmente si quiere filtrar
        setState(() {
          _selectedRoleFilter = ''; // Sin filtro automático
        });
      }
      _loadUsers();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_isSearching) return; // No cargar más durante búsqueda
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
      final userRole = authProvider.user?['rol'] as String?;
      _loadMoreUsers(userProvider, authProvider.accessToken, userRole);
    }
  }

  Future<void> _loadUsers() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userRole = authProvider.user?['rol'] as String?;

    if (authProvider.accessToken == null) {
      debugPrint('Error: No hay token de acceso para cargar usuarios.');
      return;
    }

    // Lógica diferenciada por rol
    if (userRole == 'super_admin') {
      // El super_admin solo ve admin_institucion y super_admin
      debugPrint('Cargando usuarios (admin_institucion y super_admin) como super_admin...');
      // Determinar roles según el filtro de UI: si no hay filtro, enviar ambos roles
      final roles = (_selectedRoleFilter.isEmpty)
          ? ['super_admin', 'admin_institucion']
          : [_selectedRoleFilter];

      await userProvider.loadUsers(
        authProvider.accessToken!,
        page: 1,
        limit: 15,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        activo: _statusFilter,
        roles: roles,
      );
    } else if (userRole == 'admin_institucion') {
      // El admin_institucion carga solo usuarios de su institución seleccionada
      if (authProvider.selectedInstitutionId != null) {
        debugPrint('Cargando usuarios para la institución: ${authProvider.selectedInstitutionId}');
        await userProvider.loadUsersByInstitution(
          authProvider.accessToken!,
          authProvider.selectedInstitutionId!,
          page: 1,
          limit: 5,
          role: _selectedRoleFilter.isEmpty ? null : _selectedRoleFilter,
          activo: _statusFilter,
          search: _searchQuery.isEmpty ? null : _searchQuery,
        );
      } else {
        // Caso de resguardo: si un admin no tiene institución, no se cargan datos.
        debugPrint('Admin de institución sin institución seleccionada. No se cargarán usuarios.');
        userProvider.clearData(); // Limpia la lista para mostrar el estado vacío.
      }
    }
  }

  Future<void> _loadMoreUsers(UserProvider provider, String? accessToken, String? userRole) async {
    if (accessToken == null || provider.isLoadingMore || !provider.hasMoreData) return;
    if (userRole == 'super_admin') {
      final roles = (_selectedRoleFilter.isEmpty)
          ? ['super_admin', 'admin_institucion']
          : [_selectedRoleFilter];

      await provider.loadMoreUsers(
        accessToken,
        activo: _statusFilter,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        roles: roles,
      );
    } else {
      await provider.loadMoreUsers(accessToken);
    }
  }

  void _onSearchChanged(String query) {
    // Cancelar el timer anterior si existe
    _searchDebounceTimer?.cancel();
    
    setState(() {
      _isSearching = query.isNotEmpty;
    });
    
    // Iniciar un nuevo timer para debounced search
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query.trim();
      });
      _loadUsers();
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, UserProvider>(
      builder: (context, authProvider, userProvider, child) {
        final userRole = authProvider.user?['rol'] as String?;
        final title = userRole == 'admin_institucion' 
          ? 'Gestión de Profesores'
          : 'Gestión de Usuarios';
        final canCreateUsers = userRole == 'admin_institucion' || userRole == 'super_admin';

        return ClarityManagementPage(
          title: title,
          isLoading: userProvider.isLoading,
          hasError: userProvider.hasError,
          errorMessage: userProvider.errorMessage,
          itemCount: userProvider.users.length,
          itemBuilder: (context, index) {
            final user = userProvider.users[index];
            return _buildUserCard(user, userProvider, context);
          },
          filterWidgets: _buildFilterWidgets(context, authProvider),
          statisticWidgets: _buildStatisticWidgets(context, userProvider),
          onRefresh: _loadUsers,
          scrollController: _scrollController,
          hasMoreData: userProvider.hasMoreData,
          isLoadingMore: userProvider.isLoadingMore,
          emptyStateWidget: ClarityEmptyState(
            icon: _isSearching ? Icons.search_off : Icons.people,
            title: _isSearching
              ? 'No se encontraron resultados'
              : 'Aún no has creado ningún usuario',
            subtitle: _isSearching
              ? 'Intenta con otros términos de búsqueda'
              : 'Comienza creando tu primer usuario',
          ),
          floatingActionButton: canCreateUsers
              ? _buildSpeedDial(context, userRole!)
              : null,
        );
      },
    );
  }

  Widget _buildSpeedDial(BuildContext context, String userRole) {
    final colors = context.colors;
    
    if (userRole == 'super_admin') {
      return SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        backgroundColor: colors.primary,
        foregroundColor: colors.getTextColorForBackground(colors.primary),
        children: [
          SpeedDialChild(
            child: Icon(Icons.admin_panel_settings,
              color: colors.getTextColorForBackground(colors.primary)),
            backgroundColor: colors.primary,
            label: 'Crear Admin Institución',
            onTap: _navigateToCreateAdminInstitution,
          ),
          SpeedDialChild(
            child: Icon(Icons.shield,
              color: colors.getTextColorForBackground(colors.primary)),
            backgroundColor: colors.primary,
            label: 'Crear Super Admin',
            onTap: _navigateToCreateSuperAdmin,
          ),
        ],
      );
    } else {
      // admin_institucion
      return SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        backgroundColor: colors.primary,
        foregroundColor: colors.getTextColorForBackground(colors.primary),
        children: [
          SpeedDialChild(
            child: Icon(Icons.school,
              color: colors.getTextColorForBackground(colors.primary)),
            backgroundColor: colors.primary,
            label: 'Crear Profesor',
            onTap: _navigateToCreateProfessor,
          ),
          SpeedDialChild(
            child: Icon(Icons.person,
              color: colors.getTextColorForBackground(colors.primary)),
            backgroundColor: colors.primary,
            label: 'Crear Estudiante',
            onTap: _navigateToCreateStudent,
          ),
        ],
      );
    }
  }

  List<Widget> _buildFilterWidgets(BuildContext context, AuthProvider authProvider) {
    final colors = context.colors;
    final spacing = context.spacing;
    final textStyles = context.textStyles;

    return [
      TextField(
        controller: _searchController,
        style: textStyles.bodyLarge,
        decoration: InputDecoration(
          hintText: 'Buscar por nombre, email o teléfono...',
          hintStyle: textStyles.bodyMedium.withColor(colors.textMuted),
          prefixIcon: Icon(Icons.search, color: colors.textSecondary),
          suffixIcon: _isSearching
              ? IconButton(
                  icon: Icon(Icons.clear, color: colors.textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(spacing.borderRadius),
            borderSide: BorderSide(color: colors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(spacing.borderRadius),
            borderSide: BorderSide(color: colors.borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(spacing.borderRadius),
            borderSide: BorderSide(color: colors.primary, width: 2),
          ),
          filled: true,
          fillColor: colors.surface,
          contentPadding: EdgeInsets.symmetric(horizontal: spacing.md, vertical: spacing.sm),
        ),
        onChanged: _onSearchChanged,
      ),
      SizedBox(height: spacing.sm),
      Wrap(
        spacing: spacing.md,
        runSpacing: spacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('Mostrar:', style: textStyles.labelMedium),
          FilterChip(
            label: const Text('Activos'),
            selected: _statusFilter == true && !_isSearching,
            onSelected: !_isSearching ? (selected) {
              setState(() => _statusFilter = selected ? true : null);
              _loadUsers();
            } : null,
          ),
          FilterChip(
            label: const Text('Inactivos'),
            selected: _statusFilter == false && !_isSearching,
            onSelected: !_isSearching ? (selected) {
              setState(() => _statusFilter = selected ? false : null);
              _loadUsers();
            } : null,
          ),
          FilterChip(
            label: const Text('Todos'),
            selected: _statusFilter == null && !_isSearching,
            onSelected: !_isSearching ? (selected) {
              setState(() => _statusFilter = selected ? null : true);
              _loadUsers();
            } : null,
          ),
        ],
      ),
      SizedBox(height: spacing.sm),
      Row(
        children: [
          Expanded(
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final userRole = authProvider.user?['rol'] as String?;
                final isAdminInstitucion = userRole == 'admin_institucion';
                final isSuperAdmin = userRole == 'super_admin';
                
                return DropdownButtonFormField<String>(
                  value: _selectedRoleFilter.isEmpty ? null : _selectedRoleFilter,
                  hint: Text('Filtrar por rol', style: textStyles.bodyMedium),
                  items: isSuperAdmin ? [
                    DropdownMenuItem(value: '', child: Text('Todos los roles', style: textStyles.bodyMedium)),
                    DropdownMenuItem(value: 'admin_institucion', child: Text('Admins Institución', style: textStyles.bodyMedium)),
                    DropdownMenuItem(value: 'super_admin', child: Text('Super Admins', style: textStyles.bodyMedium)),
                  ] : isAdminInstitucion ? [
                    DropdownMenuItem(value: '', child: Text('Todos los usuarios', style: textStyles.bodyMedium)),
                    DropdownMenuItem(value: 'profesor', child: Text('Solo Profesores', style: textStyles.bodyMedium)),
                    DropdownMenuItem(value: 'estudiante', child: Text('Solo Estudiantes', style: textStyles.bodyMedium)),
                  ] : [
                    DropdownMenuItem(value: '', child: Text('Todos los roles', style: textStyles.bodyMedium)),
                    DropdownMenuItem(value: 'profesor', child: Text('Profesores', style: textStyles.bodyMedium)),
                    DropdownMenuItem(value: 'estudiante', child: Text('Estudiantes', style: textStyles.bodyMedium)),
                    DropdownMenuItem(value: 'admin_institucion', child: Text('Admins Institución', style: textStyles.bodyMedium)),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedRoleFilter = value ?? '');
                    // Recargar datos desde página 1 con el nuevo filtro
                    _loadUsers();
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(spacing.borderRadius),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: spacing.md, vertical: spacing.sm),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildStatisticWidgets(BuildContext context, UserProvider provider) {
    final stats = provider.getUserStatistics();
    final colors = context.colors;

    return [
      ClarityCompactStat(
        title: 'Total',
        value: stats['total'].toString(),
        icon: Icons.people,
        color: colors.primary,
      ),
      ClarityCompactStat(
        title: 'Activos',
        value: stats['activos'].toString(),
        icon: Icons.check_circle,
        color: colors.success,
      ),
      ClarityCompactStat(
        title: 'Profesores',
        value: stats['profesores'].toString(),
        icon: Icons.school,
        color: colors.info,
      ),
      ClarityCompactStat(
        title: 'Estudiantes',
        value: stats['estudiantes'].toString(),
        icon: Icons.person,
        color: colors.warning,
      ),
    ];
  }

  Widget _buildUserCard(User user, UserProvider provider, BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final userRole = authProvider.user?['rol'] as String?;
        final canEditUsers = userRole == 'admin_institucion' || userRole == 'super_admin';

        // FASE 4: Acciones para el menú contextual
        final List<ClarityContextMenuAction> contextActions = canEditUsers
            ? [
                ClarityContextMenuAction(
                  label: 'Editar',
                  icon: Icons.edit,
                  color: colors.primary,
                  onPressed: () => _navigateToUserEdit(user),
                ),
                ClarityContextMenuAction(
                  label: user.activo ? 'Desactivar' : 'Activar',
                  icon: user.activo ? Icons.toggle_off : Icons.toggle_on,
                  color: user.activo ? colors.warning : colors.success,
                  onPressed: () => _handleMenuAction('toggle_status', user, provider),
                ),
                ClarityContextMenuAction(
                  label: 'Eliminar',
                  icon: Icons.delete,
                  color: colors.error,
                  onPressed: () => _handleMenuAction('delete', user, provider),
                ),
              ]
            : [];

        return ClarityListItem(
          leading: CircleAvatar(
            backgroundColor: _getRoleColor(user.rol, context),
            child: Text(
              user.nombreCompleto.substring(0, 1).toUpperCase(),
              style: textStyles.labelMedium.copyWith(color: colors.white),
            ),
          ),
          title: user.nombreCompleto,
          subtitle: user.email,
          badgeText: user.activo ? 'Activo' : 'Inactivo',
          badgeColor: user.activo ? colors.success : colors.error,
          contextActions: contextActions.isNotEmpty ? contextActions : null,
          onTap: () => _navigateToUserDetail(user),
        );
      },
    );
  }

  Color _getRoleColor(String role, BuildContext context) {
    final colors = context.colors;
    switch (role) {
      case 'profesor':
        return colors.info;
      case 'estudiante':
        return colors.warning;
      case 'admin_institucion':
        return colors.primary;
      case 'super_admin':
        return colors.error;
      default:
        return colors.primary;
    }
  }

  void _handleMenuAction(String action, User user, UserProvider provider) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    switch (action) {
      case 'edit':
        _navigateToUserEdit(user);
        break;

      case 'toggle_status':
        final newStatus = !user.activo;
        final success = await provider.updateUser(
          authProvider.accessToken!,
          user.id,
          UpdateUserRequest(
            activo: newStatus,
            nombres: user.nombres, // Incluir valores actuales para evitar null
            apellidos: user.apellidos,
            email: user.email,
            telefono: user.telefono,
          ),
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Usuario ${newStatus ? 'activado' : 'desactivado'} correctamente',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onPrimary),
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
          // Recargar la lista después de cambiar el estado
          await _loadUsers();
        } else if (mounted) {
          // Mostrar error si la actualización falló
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                provider.errorMessage ?? 'Error al cambiar estado del usuario',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onError),
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        break;

      case 'delete':
        _showDeleteConfirmationDialog(user, provider);
        break;
    }
  }

  void _showDeleteConfirmationDialog(User user, UserProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar Usuario', style: Theme.of(context).textTheme.headlineSmall),
        content: Text(
          '¿Estás seguro de que quieres eliminar "${user.nombreCompleto}"?\n\n'
          'Esta acción no se puede deshacer.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar', style: Theme.of(context).textTheme.labelLarge),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteUser(user, provider);
            },
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: Text('Eliminar', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(User user, UserProvider provider) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await provider.deleteUser(
      authProvider.accessToken!,
      user.id,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Usuario eliminado correctamente',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onPrimary),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      // Recargar la lista después de eliminar
      await _loadUsers();
    } else if (mounted) {
      // Mostrar error si la eliminación falló
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Error al eliminar usuario',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onError),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _navigateToCreateProfessor() {
    context.push('/users/professor/create');
  }

  void _navigateToCreateStudent() {
    context.push('/users/student/create');
  }

  void _navigateToCreateAdminInstitution() {
    context.push('/users/admin_institucion/create');
  }

  void _navigateToCreateSuperAdmin() {
    context.push('/users/super_admin/create');
  }

  void _navigateToUserEdit(User user) {
    // Para edición, usamos push() ya que las rutas están fuera del StatefulShellRoute
    context.push('/users/${user.rol}/create?edit=true&userId=${user.id}');
  }

  void _navigateToUserDetail(User user) {
    context.push('/users/detail/${user.id}', extra: user);
  }
}