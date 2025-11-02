import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/theme_extensions.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/management_scaffold.dart';

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
      await userProvider.loadUsers(
        authProvider.accessToken!,
        page: 1,
        limit: 15,
      );
      
      // Filtrar en el cliente para mostrar solo admin_institucion y super_admin
      // Nota: Esto se puede mover al backend en el futuro para mejor performance
      userProvider.filterUsersLocally(['admin_institucion', 'super_admin']);
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
    await provider.loadMoreUsers(accessToken);
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
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, UserProvider>(
      builder: (context, authProvider, userProvider, child) {
        final userRole = authProvider.user?['rol'] as String?;
        final title = userRole == 'admin_institucion' 
          ? 'Gestión de Profesores'
          : 'Gestión de Usuarios';

        return ManagementScaffold(
          title: title,
          isLoading: userProvider.isLoading && userProvider.users.isEmpty,
          hasError: userProvider.hasError,
          errorMessage: userProvider.errorMessage ?? 'Error desconocido',
          itemCount: userProvider.users.length,
          itemBuilder: (context, index) => _buildUserCard(
            userProvider.users[index],
            userProvider,
            context,
          ),
          hasMoreData: userProvider.hasMoreData,
          onRefresh: () => _loadUsers(),
          scrollController: _scrollController,
          floatingActionButton: Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final userRole = authProvider.user?['rol'] as String?;
              final canCreateUsers = userRole == 'admin_institucion' || userRole == 'super_admin';
              
              if (!canCreateUsers) return const SizedBox.shrink();
              
              // Configuración diferente según el rol
              if (userRole == 'super_admin') {
                return SpeedDial(
                  icon: Icons.add,
                  activeIcon: Icons.close,
                  backgroundColor: context.colors.primary,
                  foregroundColor: context.colors.getTextColorForBackground(context.colors.primary),
                  children: [
                    SpeedDialChild(
                      child: Icon(Icons.admin_panel_settings, color: context.colors.getTextColorForBackground(context.colors.primary)),
                      backgroundColor: context.colors.primary,
                      label: 'Crear Admin Institución',
                      onTap: _navigateToCreateAdminInstitution,
                    ),
                    SpeedDialChild(
                      child: Icon(Icons.shield, color: context.colors.getTextColorForBackground(context.colors.primary)),
                      backgroundColor: context.colors.primary,
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
                  backgroundColor: context.colors.primary,
                  foregroundColor: context.colors.getTextColorForBackground(context.colors.primary),
                  children: [
                    SpeedDialChild(
                      child: Icon(Icons.school, color: context.colors.getTextColorForBackground(context.colors.primary)),
                      backgroundColor: context.colors.primary,
                      label: 'Crear Profesor',
                      onTap: _navigateToCreateProfessor,
                    ),
                    SpeedDialChild(
                      child: Icon(Icons.person, color: context.colors.getTextColorForBackground(context.colors.primary)),
                      backgroundColor: context.colors.primary,
                      label: 'Crear Estudiante',
                      onTap: _navigateToCreateStudent,
                    ),
                  ],
                );
              }
            },
          ),
          filterWidgets: _buildFilterWidgets(context, authProvider),
          statisticWidgets: _buildStatisticWidgets(context, userProvider),
          paginationInfo: null, // No pagination widget for users
          onPageChange: (_) async {}, // Not used
          emptyStateTitle: _isSearching ? 'No se encontraron resultados para tu búsqueda' : 'Aún no has creado ningún usuario',
          emptyStateMessage: _isSearching ? 'Intenta con otros términos de búsqueda' : 'Comienza creando tu primer usuario',
          emptyStateIcon: _isSearching ? Icons.search_off : Icons.people,
        );
      },
    );
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
      Row(
        children: [
          Text('Mostrar:', style: textStyles.labelMedium),
          SizedBox(width: spacing.md),
          FilterChip(
            label: const Text('Activos'),
            selected: _statusFilter == true && !_isSearching,
            onSelected: !_isSearching ? (selected) {
              setState(() => _statusFilter = selected ? true : null);
              _loadUsers();
            } : null,
          ),
          SizedBox(width: spacing.md),
          FilterChip(
            label: const Text('Inactivos'),
            selected: _statusFilter == false && !_isSearching,
            onSelected: !_isSearching ? (selected) {
              setState(() => _statusFilter = selected ? false : null);
              _loadUsers();
            } : null,
          ),
          SizedBox(width: spacing.md),
          FilterChip(
            label: const Text('Todos'),
            selected: _statusFilter == null && !_isSearching,
            onSelected: !_isSearching ? (selected) {
              setState(() => _statusFilter = selected ? null : true);
              _loadUsers();
            } : null,
          ),
          SizedBox(width: spacing.md),
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

    return [
      _buildCompactStat(
        'Total',
        stats['total'].toString(),
        Icons.people,
        context.colors.primary,
        context.textStyles,
      ),
      Container(
        height: 24,
        width: 1,
        color: context.colors.border,
      ),
      _buildCompactStat(
        'Activos',
        stats['activos'].toString(),
        Icons.check_circle,
        context.colors.success,
        context.textStyles,
      ),
      Container(
        height: 24,
        width: 1,
        color: context.colors.border,
      ),
      _buildCompactStat(
        'Profesores',
        stats['profesores'].toString(),
        Icons.school,
        context.colors.info,
        context.textStyles,
      ),
      Container(
        height: 24,
        width: 1,
        color: context.colors.border,
      ),
      _buildCompactStat(
        'Estudiantes',
        stats['estudiantes'].toString(),
        Icons.person,
        context.colors.warning,
        context.textStyles,
      ),
    ];
  }

  Widget _buildCompactStat(String title, String value, IconData icon, Color color, AppTextStyles textStyles) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 6),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: textStyles.titleMedium.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: textStyles.bodySmall.copyWith(
                color: color.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserCard(User user, UserProvider provider, BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final textStyles = context.textStyles;
    return Card(
      margin: EdgeInsets.only(bottom: spacing.xs),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.borderRadius),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: user.activo ? colors.success : colors.error,
          child: Icon(
            user.activo ? Icons.check : Icons.close,
            color: colors.surface,
          ),
        ),
        title: Text(
          user.nombreCompleto,
          style: textStyles.titleMedium.bold,
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
            SizedBox(height: spacing.xs),
            Chip(
              label: Text(
                _getRoleDisplayName(user.rol),
                style: textStyles.bodySmall.withColor(colors.primary),
              ),
              backgroundColor: colors.primary.withValues(alpha: 0.1),
              side: BorderSide(color: colors.primary.withValues(alpha: 0.3)),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: EdgeInsets.zero,
            ),
          ],
        ),
        trailing: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final userRole = authProvider.user?['rol'] as String?;
            final canEditUsers = userRole == 'admin_institucion' || userRole == 'super_admin';
            
            if (!canEditUsers) return const SizedBox.shrink();
            
            return PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value, user, provider),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: context.colors.textSecondary),
                      SizedBox(width: context.spacing.sm),
                      Text('Editar', style: context.textStyles.bodyMedium),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle_status',
                  child: Row(
                    children: [
                      Icon(Icons.toggle_on, color: context.colors.textSecondary),
                      SizedBox(width: context.spacing.sm),
                      Text('Cambiar Estado', style: context.textStyles.bodyMedium),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: context.colors.error),
                      SizedBox(width: context.spacing.sm),
                      Text('Eliminar', style: context.textStyles.bodyMedium.withColor(context.colors.error)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        onTap: () => _navigateToUserDetail(user),
      ),
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'profesor':
        return 'Profesor';
      case 'estudiante':
        return 'Estudiante';
      case 'admin_institucion':
        return 'Admin Institución';
      case 'super_admin':
        return 'Super Admin';
      default:
        return role;
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
      authProvider.user?['rol'] as String? ?? '',
      user.rol,
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