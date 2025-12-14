import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/theme_extensions.dart';
// Using theme extensions via context: colors, textStyles, spacing
import '../../widgets/components/index.dart';
import '../../widgets/common/skeleton_list.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounceTimer;
  UserProvider? _userProvider;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Configurar filtro automático para admin_institucion
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _userProvider = Provider.of<UserProvider>(context, listen: false);
      final userRole = authProvider.user?['rol'] as String?;

      debugPrint('UsersListScreen initState - userRole: $userRole');
      debugPrint(
          'UsersListScreen initState - Filtros iniciales: ${_userProvider!.filters}');

      // Limpiar filtros previos y configurar los nuevos
      _userProvider!.filters.clear();

      // Inicializar filtro de estado activo por defecto
      _userProvider!.filters['activo'] = 'true';

      if (userRole == 'admin_institucion') {
        // Para admin_institucion, no establecer filtro de rol
        debugPrint('UsersListScreen initState - admin_institucion detectado');
      } else if (userRole == 'super_admin') {
        // Para super_admin, los roles se establecen en _loadUsers
        debugPrint('UsersListScreen initState - super_admin detectado');
      }

      debugPrint(
          'UsersListScreen initState - Filtros configurados: ${_userProvider!.filters}');
      _loadUsers();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchDebounceTimer?.cancel();
    // Limpiar filtros al salir de la pantalla - removido para evitar error de setState durante dispose
    // _userProvider?.clearFilters();
    super.dispose();
  }

  // Helper para verificar si hay búsqueda activa
  bool _hasActiveSearch(UserProvider provider) {
    final search = provider.filters['search'];
    return search != null && search.toString().isNotEmpty;
  }

  // Helper para obtener el rol seleccionado del filtro
  String _getSelectedRole(UserProvider provider) {
    final rolesFilter = provider.filters['roles'];
    if (rolesFilter != null) {
      final rolesStr = rolesFilter.toString();
      // Si el filtro contiene múltiples roles (coma separada), no devolver un valor
      // único para el Dropdown (evita error: no item matches el valor compuesto).
      if (rolesStr.contains(',')) return '';
      return rolesStr;
    }
    return (provider.filters['role'] ?? '').toString();
  }

  // Helper para obtener el filtro de estado
  bool? _getStatusFilter(UserProvider provider) {
    final activo = provider.filters['activo'];
    if (activo == null) return null;
    return activo.toString() == 'true';
  }

  void _onScroll() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (_hasActiveSearch(userProvider))
      return; // No cargar más durante búsqueda

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      final userRole = authProvider.user?['rol'] as String?;
      final token = authProvider.accessToken;
      _loadMoreUsers(userProvider, token, userRole);
    }
  }

  Future<void> _loadUsers() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userRole = authProvider.user?['rol'] as String?;

    final token = authProvider.accessToken;
    if (token == null) {
      debugPrint('Error: No hay token de acceso para cargar usuarios.');
      return;
    }

    // Obtener filtros del provider para determinar los roles a buscar
    final selectedRoleFilter = _getSelectedRole(userProvider);

    debugPrint(
        '_loadUsers - userRole: $userRole, selectedRoleFilter: $selectedRoleFilter');
    debugPrint('_loadUsers - Filtros actuales ANTES: ${userProvider.filters}');

    // Lógica diferenciada por rol
    if (userRole == 'super_admin') {
      // El super_admin solo ve admin_institucion y super_admin
      debugPrint(
          'Cargando usuarios (admin_institucion y super_admin) como super_admin...');
      // Determinar roles según el filtro de UI: si no hay filtro, enviar ambos roles
      if (selectedRoleFilter.isEmpty) {
        userProvider.filters['roles'] = 'super_admin,admin_institucion';
      } else {
        userProvider.filters['roles'] = selectedRoleFilter;
      }

      debugPrint(
          '_loadUsers - Filtros actuales DESPUÉS: ${userProvider.filters}');

      await userProvider.loadUsers(
        token,
        page: 1,
        limit: 15,
      );
    } else if (userRole == 'admin_institucion') {
      // El admin_institucion carga solo usuarios de su institución seleccionada
      if (authProvider.selectedInstitutionId != null) {
        debugPrint(
            'Cargando usuarios para la institución: ${authProvider.selectedInstitutionId}');
        // Configurar filtro de rol si está seleccionado
        if (selectedRoleFilter.isNotEmpty) {
          userProvider.filters['role'] = selectedRoleFilter;
        } else {
          userProvider.filters.remove('role');
        }

        debugPrint(
            '_loadUsers - Filtros actuales DESPUÉS: ${userProvider.filters}');

        await userProvider.loadUsersByInstitution(
          token,
          authProvider.selectedInstitutionId!,
          page: 1,
          limit: 15,
        );
      } else {
        // Caso de resguardo: si un admin no tiene institución, no se cargan datos.
        debugPrint(
            'Admin de institución sin institución seleccionada. No se cargarán usuarios.');
        userProvider
            .clearData(); // Limpia la lista para mostrar el estado vacío.
      }
    }
  }

  Future<void> _loadMoreUsers(
      UserProvider provider, String? accessToken, String? userRole) async {
    if (accessToken == null || provider.isLoadingMore || !provider.hasMoreData)
      return;
    await provider.loadNextPage(accessToken);
  }

  void _onSearchChanged(String query) {
    // Cancelar el timer anterior si existe
    _searchDebounceTimer?.cancel();

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Iniciar un nuevo timer para debounced search
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      // Modificar el filtro directamente para evitar múltiples notifyListeners
      if (query.trim().isNotEmpty) {
        userProvider.filters['search'] = query.trim();
      } else {
        userProvider.filters.remove('search');
      }
      userProvider.refreshData(authProvider.accessToken!);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, UserProvider>(
      builder: (context, authProvider, userProvider, child) {
        final userRole = authProvider.user?['rol'] as String?;
        final title = userRole == 'admin_institucion'
            ? 'Gestión de Usuarios de la Institución'
            : 'Gestión de Usuarios';
        final canCreateUsers =
            userRole == 'admin_institucion' || userRole == 'super_admin';
        final isSearching = _hasActiveSearch(userProvider);

        return ClarityManagementPage(
          title: title,
          isLoading: userProvider.isLoading,
          loadingWidget:
              const SkeletonList(height: 90), // Skeleton personalizado
          hasError: userProvider.hasError,
          errorMessage: userProvider.errorMessage,
          itemCount: userProvider.users.length,
          itemBuilder: (context, index) {
            final user = userProvider.users[index];
            return _buildUserCard(user, userProvider, context);
          },
          // Reducir el espacio entre items para una lista más compacta
          itemSpacing: context.spacing.sm,
          filterWidgets:
              _buildFilterWidgets(context, authProvider, userProvider),
          statisticWidgets: _buildStatisticWidgets(context, userProvider),
          onRefresh: _loadUsers,
          scrollController: _scrollController,
          hasMoreData: userProvider.hasMoreData,
          isLoadingMore: userProvider.isLoadingMore,
          emptyStateWidget: ClarityEmptyState(
            icon: isSearching ? Icons.search_off : Icons.people,
            title: isSearching
                ? 'No se encontraron resultados'
                : 'Aún no has creado ningún usuario',
            subtitle: isSearching
                ? 'Intenta con otros términos de búsqueda'
                : 'Comienza creando tu primer usuario',
          ),
          floatingActionButton:
              canCreateUsers ? _buildSpeedDial(context, userRole!) : null,
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
            key: const Key('createUser_professor'),
            child: Icon(Icons.school,
                color: colors.getTextColorForBackground(colors.primary)),
            backgroundColor: colors.primary,
            label: 'Crear Profesor',
            onTap: _navigateToCreateProfessor,
          ),
          SpeedDialChild(
            key: const Key('createUser_student'),
            child: Icon(Icons.person,
                color: colors.getTextColorForBackground(colors.primary)),
            backgroundColor: colors.primary,
            label: 'Crear Estudiante',
            onTap: _navigateToCreateStudent,
          ),
          SpeedDialChild(
            key: const Key('createUser_acudiente'),
            child: Icon(Icons.family_restroom,
                color: colors.getTextColorForBackground(colors.primary)),
            backgroundColor: colors.primary,
            label: 'Crear Acudiente',
            onTap: _navigateToCreateAcudiente,
          ),
        ],
      );
    }
  }

  List<Widget> _buildFilterWidgets(BuildContext context,
      AuthProvider authProvider, UserProvider userProvider) {
    final colors = context.colors;
    final spacing = context.spacing;
    final textStyles = context.textStyles;
    final isSearching = _hasActiveSearch(userProvider);
    final statusFilter = _getStatusFilter(userProvider);
    final selectedRoleFilter = _getSelectedRole(userProvider);

    return [
      TextField(
        controller: _searchController,
        style: textStyles.bodyLarge,
        decoration: InputDecoration(
          hintText: 'Buscar por nombre, email o teléfono...',
          hintStyle: textStyles.bodyMedium.withColor(colors.textMuted),
          prefixIcon: Icon(Icons.search, color: colors.textSecondary),
          suffixIcon: isSearching
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
          contentPadding: EdgeInsets.symmetric(
              horizontal: spacing.md, vertical: spacing.sm),
        ),
        onChanged: _onSearchChanged,
      ),
      SizedBox(height: spacing.sm),
      // Mejorar responsividad de los filtros
      Wrap(
        spacing: spacing.md,
        runSpacing: spacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('Mostrar:', style: textStyles.labelMedium),
          _statusFilterChip(
            context,
            label: 'Activos',
            selected: statusFilter == true && !isSearching,
            color: context.colors.success,
            onTap: () =>
                _onStatusFilterChanged(true, userProvider, authProvider),
          ),
          _statusFilterChip(
            context,
            label: 'Inactivos',
            selected: statusFilter == false && !isSearching,
            color: context.colors.grey400,
            onTap: () =>
                _onStatusFilterChanged(false, userProvider, authProvider),
          ),
          _statusFilterChip(
            context,
            label: 'Todos',
            selected: statusFilter == null && !isSearching,
            color: context.colors.grey400,
            onTap: () =>
                _onStatusFilterChanged(null, userProvider, authProvider),
          ),
        ],
      ),
      SizedBox(height: spacing.sm),
      Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: selectedRoleFilter,
              hint: Text('Filtrar por rol', style: textStyles.bodyMedium),
              items: _buildRoleDropdownItems(authProvider, textStyles),
              onChanged: (value) =>
                  _onRoleFilterChanged(value, userProvider, authProvider),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(spacing.borderRadius),
                ),
                contentPadding: EdgeInsets.symmetric(
                    horizontal: spacing.md, vertical: spacing.sm),
              ),
              isExpanded: true,
            ),
          ),
        ],
      ),
    ];
  }

  List<DropdownMenuItem<String>> _buildRoleDropdownItems(
      AuthProvider authProvider, dynamic textStyles) {
    final userRole = authProvider.user?['rol'] as String?;
    final isAdminInstitucion = userRole == 'admin_institucion';
    final isSuperAdmin = userRole == 'super_admin';

    if (isSuperAdmin) {
      return [
        DropdownMenuItem(
            value: '',
            child: Text('Todos los roles', style: textStyles.bodyMedium)),
        DropdownMenuItem(
            value: 'admin_institucion',
            child: Text('Admins Institución', style: textStyles.bodyMedium)),
        DropdownMenuItem(
            value: 'super_admin',
            child: Text('Super Admins', style: textStyles.bodyMedium)),
      ];
    } else if (isAdminInstitucion) {
      return [
        DropdownMenuItem(
            value: '',
            child: Text('Todos los usuarios', style: textStyles.bodyMedium)),
        DropdownMenuItem(
            value: 'profesor',
            child: Text('Solo Profesores', style: textStyles.bodyMedium)),
        DropdownMenuItem(
            value: 'estudiante',
            child: Text('Solo Estudiantes', style: textStyles.bodyMedium)),
        DropdownMenuItem(
            value: 'acudiente',
            child: Text('Solo Acudientes', style: textStyles.bodyMedium)),
      ];
    } else {
      return [
        DropdownMenuItem(
            value: '',
            child: Text('Todos los roles', style: textStyles.bodyMedium)),
        DropdownMenuItem(
            value: 'profesor',
            child: Text('Profesores', style: textStyles.bodyMedium)),
        DropdownMenuItem(
            value: 'estudiante',
            child: Text('Estudiantes', style: textStyles.bodyMedium)),
        DropdownMenuItem(
            value: 'admin_institucion',
            child: Text('Admins Institución', style: textStyles.bodyMedium)),
      ];
    }
  }

  void _onStatusFilterChanged(
      bool? status, UserProvider provider, AuthProvider authProvider) {
    debugPrint('_onStatusFilterChanged llamado con status: $status');
    debugPrint('Filtros ANTES: ${provider.filters}');

    // Modificar el filtro directamente para evitar múltiples notifyListeners
    if (status != null) {
      provider.filters['activo'] = status.toString();
    } else {
      provider.filters.remove('activo');
    }

    debugPrint('Filtros DESPUÉS: ${provider.filters}');
    provider.refreshData(authProvider.accessToken!);
  }

  void _onRoleFilterChanged(
      String? value, UserProvider provider, AuthProvider authProvider) {
    final role = value ?? '';
    final userRole = authProvider.user?['rol'] as String?;

    // Modificar el filtro directamente para evitar múltiples notifyListeners
    if (userRole == 'super_admin') {
      // Para super_admin usamos 'roles' (plural)
      if (role.isNotEmpty) {
        provider.filters['roles'] = role;
      } else {
        // Si no hay rol seleccionado, mostrar ambos roles
        provider.filters['roles'] = 'super_admin,admin_institucion';
      }
    } else if (userRole == 'admin_institucion') {
      // Para admin_institucion usamos 'role' (singular)
      if (role.isNotEmpty) {
        provider.filters['role'] = role;
      } else {
        provider.filters.remove('role');
      }
    }
    provider.refreshData(authProvider.accessToken!);
  }

  Widget _statusFilterChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    final spacing = context.spacing;
    final textStyles = context.textStyles;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(spacing.borderRadius),
      child: Container(
        padding:
            EdgeInsets.symmetric(horizontal: spacing.sm, vertical: spacing.xs),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : colors.surface,
          border: Border.all(
            color: selected ? color : colors.borderLight,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(spacing.borderRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: spacing.xs),
            Text(
              label,
              style: textStyles.bodySmall.copyWith(
                color: selected ? color : colors.textPrimary,
                fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStatisticWidgets(
      BuildContext context, UserProvider provider) {
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

  Widget _buildUserCard(
      User user, UserProvider provider, BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final userRole = authProvider.user?['rol'] as String?;
        final canEditUsers =
            userRole == 'admin_institucion' || userRole == 'super_admin';

        // FASE 4: Acciones para el menú contextual
        // Evitar que un admin se desactive o elimine a sí mismo
        final currentUserId = authProvider.user?['id']?.toString();
        final bool isSelf = currentUserId != null && currentUserId == user.id;

        final List<ClarityContextMenuAction> contextActions = canEditUsers
            ? [
                ClarityContextMenuAction(
                  label: 'Editar',
                  icon: Icons.edit,
                  color: colors.primary,
                  onPressed: () => _navigateToUserEdit(user),
                ),
                if (!isSelf)
                  ClarityContextMenuAction(
                    label: (user.activo == true) ? 'Desactivar' : 'Activar',
                    icon: (user.activo == true)
                        ? Icons.toggle_off
                        : Icons.toggle_on,
                    color:
                        (user.activo == true) ? colors.warning : colors.success,
                    onPressed: () =>
                        _handleMenuAction('toggle_status', user, provider),
                  ),
                if (!isSelf)
                  ClarityContextMenuAction(
                    label: 'Eliminar',
                    icon: Icons.delete,
                    color: colors.error,
                    onPressed: () =>
                        _handleMenuAction('delete', user, provider),
                  ),
              ]
            : [];

        return ClarityListItem(
          leading: CircleAvatar(
            backgroundColor: _getRoleColor(user.rol ?? '', context),
            child: Text(
              user.nombreCompleto.substring(0, 1).toUpperCase(),
              style: textStyles.labelMedium.copyWith(color: colors.white),
            ),
          ),
          title: user.nombreCompleto,
          subtitle: null,
          subtitleWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila con email y estado
              Row(
                children: [
                  Expanded(
                    child: Text(
                      user.email ?? '',
                      style: textStyles.bodySmall
                          .copyWith(color: context.colors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Chip de estado discreto
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: context.colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: context.colors.borderLight,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: (user.activo == true)
                                ? context.colors.primary.withValues(alpha: 0.7)
                                : context.colors.textMuted,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          (user.activo == true) ? 'Activo' : 'Inactivo',
                          style: textStyles.bodySmall.copyWith(
                            color: context.colors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (user.rol == 'admin_institucion' &&
                  (user.instituciones?.isNotEmpty ?? false)) ...[
                const SizedBox(height: 4),
                // Mostrar instituciones en una línea aparte como cajitas compactas
                Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  children: (user.instituciones ?? []).map((i) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: context.colors.surfaceVariant,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(4)),
                        border: Border.all(
                            color: context.colors.border, width: 0.5),
                      ),
                      constraints: const BoxConstraints(maxWidth: 160),
                      child: Text(
                        i.nombre,
                        style: textStyles.bodySmall.copyWith(
                          color: context.colors.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
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
      case 'acudiente':
        return colors.success;
      default:
        return colors.primary;
    }
  }

  void _handleMenuAction(
      String action, User user, UserProvider provider) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    switch (action) {
      case 'edit':
        _navigateToUserEdit(user);
        break;

      case 'toggle_status':
        final newStatus = !(user.activo == true);
        final token = authProvider.accessToken;
        if (token == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Debes iniciar sesión para editar usuarios')));
          return;
        }

        final success = await provider.updateUser(
          token,
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
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.onPrimary),
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
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.onError),
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
        title: Text('Eliminar Usuario',
            style: Theme.of(context).textTheme.headlineSmall),
        content: Text(
          '¿Estás seguro de que quieres eliminar "${user.nombreCompleto}"?\n\n'
          'Esta acción no se puede deshacer.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child:
                Text('Cancelar', style: Theme.of(context).textTheme.labelLarge),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteUser(user, provider);
            },
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            child: Text('Eliminar',
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(User user, UserProvider provider) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final token = authProvider.accessToken;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Debes iniciar sesión para eliminar usuarios')));
      return;
    }

    final success = await provider.deleteUser(
      token,
      user.id,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Usuario eliminado correctamente',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Theme.of(context).colorScheme.onPrimary),
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
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Theme.of(context).colorScheme.onError),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _navigateToCreateProfessor() {
    context.push('/users/create', extra: 'profesor');
  }

  void _navigateToCreateStudent() {
    context.push('/users/create', extra: 'estudiante');
  }

  void _navigateToCreateAdminInstitution() {
    context.push('/users/create', extra: 'admin_institucion');
  }

  void _navigateToCreateSuperAdmin() {
    context.push('/users/create', extra: 'super_admin');
  }

  void _navigateToCreateAcudiente() {
    context.push('/users/create', extra: 'acudiente');
  }

  void _navigateToUserEdit(User user) {
    // Para edición, usamos push() ya que las rutas están fuera del StatefulShellRoute
    // Navegar a la ruta de creación/edición centralizada pasando el rol en `extra`
    // El router espera '/users/create' y obtiene el rol desde state.extra
    context.push('/users/create?edit=true&userId=${user.id}', extra: user.rol);
  }

  void _navigateToUserDetail(User user) {
    context.push('/users/detail/${user.id}', extra: user);
  }
}
