import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/institution.dart';
import '../../providers/auth_provider.dart';
import '../../providers/institution_provider.dart';
import '../../theme/theme_extensions.dart';
import '../../widgets/components/index.dart';
// Routes now usan go_router y se definen en app_router.dart; los screens se instancian desde allí vía 'extra'

class InstitutionsListScreen extends StatefulWidget {
  const InstitutionsListScreen({super.key});

  @override
  State<InstitutionsListScreen> createState() => _InstitutionsListScreenState();
}

class _InstitutionsListScreenState extends State<InstitutionsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Cargar instituciones después de que el widget se construya completamente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInstitutions();
    });
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    // Limpiar filtros al salir de la pantalla - removido para evitar error de setState durante dispose
    // final institutionProvider = Provider.of<InstitutionProvider>(context, listen: false);
    // institutionProvider.clearFilters();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final institutionProvider =
          Provider.of<InstitutionProvider>(context, listen: false);

      final token = authProvider.accessToken;
      if (token != null &&
          institutionProvider.hasMoreData &&
          !institutionProvider.isLoadingMore) {
        institutionProvider.loadMoreInstitutions(token);
      }
    }
  }

  Future<void> _loadInstitutions() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final institutionProvider =
        Provider.of<InstitutionProvider>(context, listen: false);

    final token = authProvider.accessToken;
    if (token != null) {
      debugPrint(
          'Cargando instituciones con token: ${token.substring(0, 20)}...');
      await institutionProvider.loadInstitutions(token);
      debugPrint(
          'Instituciones cargadas: ${institutionProvider.institutions.length}');
      debugPrint(
          'Estado del provider: isLoading=${institutionProvider.isLoading}, hasError=${institutionProvider.hasError}');
      if (institutionProvider.hasError) {
        debugPrint('Error del provider: ${institutionProvider.errorMessage}');
      }
    } else {
      debugPrint('No hay token de acceso disponible');
    }
  }

  void _onSearchChanged(String query) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      final institutionProvider =
          Provider.of<InstitutionProvider>(context, listen: false);
      // Modificar el filtro directamente para evitar múltiples notifyListeners
      if (query.isNotEmpty) {
        institutionProvider.filters['search'] = query;
      } else {
        institutionProvider.filters.remove('search');
      }
      institutionProvider.refreshData(
          Provider.of<AuthProvider>(context, listen: false).accessToken!);
    });
  }

  void _onStatusFilterChanged(bool? status) {
    final institutionProvider =
        Provider.of<InstitutionProvider>(context, listen: false);
    // Modificar el filtro directamente para evitar múltiples notifyListeners
    if (status != null) {
      institutionProvider.filters['activa'] = status.toString();
    } else {
      institutionProvider.filters.remove('activa');
    }
    institutionProvider.refreshData(
        Provider.of<AuthProvider>(context, listen: false).accessToken!);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, InstitutionProvider>(
      builder: (context, authProvider, institutionProvider, child) {
        final userRole = authProvider.user?['rol'] as String?;
        final canCreateInstitutions = userRole == 'super_admin';
        final administrationName = authProvider.administrationName;

        final List<Widget> filters = _buildFilterWidgets(context);
        if (userRole == 'admin_institucion' && administrationName != null) {
          filters.insert(
            0,
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Icon(Icons.admin_panel_settings,
                      size: 18, color: context.colors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Eres administrador de: $administrationName',
                      style: context.textStyles.bodyMedium
                          .copyWith(color: context.colors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message:
                        'Tu cuenta tiene permisos administrativos sobre esta institución',
                    child: Icon(Icons.info_outline,
                        size: 18, color: context.colors.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }

        return ClarityManagementPage(
          title: 'Gestión de Instituciones',
          isLoading: institutionProvider.isLoading,
          hasError: institutionProvider.hasError,
          errorMessage: institutionProvider.errorMessage,
          itemCount: institutionProvider.institutions.length,
          itemBuilder: (context, index) {
            final institution = institutionProvider.institutions[index];
            return _buildInstitutionCard(
                institution, institutionProvider, context);
          },
          filterWidgets: _buildFilterWidgets(context),
          statisticWidgets:
              _buildStatisticWidgets(context, institutionProvider),
          onRefresh: _loadInstitutions,
          scrollController: _scrollController,
          hasMoreData: institutionProvider.hasMoreData,
          isLoadingMore: institutionProvider.isLoadingMore,
          emptyStateWidget: (institutionProvider.institutions.isEmpty ||
                      institutionProvider.hasError) &&
                  administrationName != null
              ? ClarityEmptyState(
                  icon: Icons.account_balance,
                  title: administrationName,
                  subtitle: institutionProvider.hasError
                      ? 'No tienes permiso para ver la lista completa de instituciones. Mostrando el nombre de la administración.'
                      : ((institutionProvider.filters['search'] as String?)
                                  ?.isNotEmpty ??
                              false
                          ? 'No se encontraron instituciones para "${institutionProvider.filters['search']}". Mostrando la administración: $administrationName'
                          : 'No hay instituciones disponibles. Mostrando la administración: $administrationName'),
                )
              : ClarityEmptyState(
                  icon: (institutionProvider.filters['search'] as String?)
                              ?.isNotEmpty ??
                          false
                      ? Icons.search_off
                      : Icons.business,
                  title: (institutionProvider.filters['search'] as String?)
                              ?.isNotEmpty ??
                          false
                      ? 'No se encontraron instituciones'
                      : 'No hay instituciones',
                  subtitle: (institutionProvider.filters['search'] as String?)
                              ?.isNotEmpty ??
                          false
                      ? 'Intenta con otros términos de búsqueda'
                      : 'Comienza creando tu primera institución',
                ),
          floatingActionButton: canCreateInstitutions
              ? FloatingActionButton(
                  onPressed: () => _navigateToForm(context),
                  backgroundColor: context.colors.primary,
                  child: Icon(
                    Icons.add,
                    color: context.colors
                        .getTextColorForBackground(context.colors.primary),
                  ),
                )
              : null,
        );
      },
    );
  }

  List<Widget> _buildFilterWidgets(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final textStyles = context.textStyles;

    return [
      Consumer<InstitutionProvider>(
        builder: (context, institutionProvider, child) => TextField(
          key: const Key('searchInstitutionField'),
          controller: _searchController,
          style: textStyles.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Buscar por nombre, código o email...',
            hintStyle: textStyles.bodyMedium.withColor(colors.textMuted),
            prefixIcon: Icon(Icons.search, color: colors.textSecondary),
            suffixIcon: (institutionProvider.filters['search'] as String?)
                        ?.isNotEmpty ??
                    false
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
      ),
      SizedBox(height: spacing.sm),
      Consumer<InstitutionProvider>(
        builder: (context, institutionProvider, child) => Wrap(
          spacing: spacing.md,
          runSpacing: spacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Mostrar:', style: textStyles.labelMedium),
            FilterChip(
              label: const Text('Todas'),
              selected: institutionProvider.filters['activa'] == null,
              onSelected: (selected) {
                if (selected) _onStatusFilterChanged(null);
              },
            ),
            FilterChip(
              label: const Text('Activas'),
              selected: institutionProvider.filters['activa'] == 'true',
              onSelected: (selected) {
                if (selected) _onStatusFilterChanged(true);
              },
            ),
            FilterChip(
              label: const Text('Inactivas'),
              selected: institutionProvider.filters['activa'] == 'false',
              onSelected: (selected) {
                if (selected) _onStatusFilterChanged(false);
              },
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildStatisticWidgets(
      BuildContext context, InstitutionProvider provider) {
    final colors = context.colors;
    return [
      ClarityCompactStat(
        title: 'Total',
        value: provider.totalInstitutions.toString(),
        icon: Icons.business,
        color: colors.primary,
      ),
      ClarityCompactStat(
        title: 'Activas',
        value: provider.activeInstitutionsCount.toString(),
        icon: Icons.check_circle,
        color: colors.success,
      ),
      ClarityCompactStat(
        title: 'Inactivas',
        value: provider.inactiveInstitutionsCount.toString(),
        icon: Icons.cancel,
        color: colors.error,
      ),
    ];
  }

  Widget _buildInstitutionCard(Institution institution,
      InstitutionProvider provider, BuildContext context) {
    final colors = context.colors;

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final userRole = authProvider.user?['rol'] as String?;
        final isSuperAdmin = userRole == 'super_admin';

        // FASE 4: Acciones para el menú contextual
        final List<ClarityContextMenuAction> contextActions = [
          if (isSuperAdmin) ...[
            ClarityContextMenuAction(
              label: 'Crear Admin',
              icon: Icons.admin_panel_settings,
              color: colors.primary,
              onPressed: () => _navigateToCreateInstitutionAdmin(institution),
            ),
            ClarityContextMenuAction(
              label: 'Gestionar Admins',
              icon: Icons.group,
              color: colors.info,
              onPressed: () =>
                  context.push('/institutions/${institution.id}/admins'),
            ),
          ],
          ClarityContextMenuAction(
            label: 'Editar',
            icon: Icons.edit,
            color: colors.primary,
            onPressed: () => _navigateToForm(context, institution: institution),
          ),
          ClarityContextMenuAction(
            label: institution.activa ? 'Desactivar' : 'Activar',
            icon: institution.activa ? Icons.toggle_off : Icons.toggle_on,
            color: institution.activa ? colors.warning : colors.success,
            onPressed: () =>
                _handleMenuAction('toggle_status', institution, provider),
          ),
          ClarityContextMenuAction(
            label: 'Eliminar',
            icon: Icons.delete,
            color: colors.error,
            onPressed: () => _handleMenuAction('delete', institution, provider),
          ),
        ];

        return ClarityListItem(
          leading: Icon(
            Icons.business,
            color: colors.primary,
            size: 32,
          ),
          title: institution.nombre,
          subtitleWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila 1: Email/Teléfono
              Row(
                children: [
                  Icon(Icons.contact_mail,
                      size: 14, color: colors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      institution.email ??
                          institution.telefono ??
                          'Sin contacto',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Fila 2: Estado + Configuración de Notificaciones
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  // Chip de estado discreto
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colors.borderLight,
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
                            color: institution.activa
                                ? colors.primary.withValues(alpha: 0.7)
                                : colors.textMuted,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          institution.activa ? 'Activa' : 'Inactiva',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colors.textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  // Chip de Configuración de Notificaciones
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: institution.notificacionesActivas
                          ? colors.info.withValues(alpha: 0.1)
                          : colors.textMuted.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: institution.notificacionesActivas
                            ? colors.info.withValues(alpha: 0.3)
                            : colors.textMuted.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          institution.notificacionesActivas
                              ? Icons.notifications_active
                              : Icons.notifications_off,
                          size: 12,
                          color: institution.notificacionesActivas
                              ? colors.info
                              : colors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          institution.notificationConfigSummary,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: institution.notificacionesActivas
                                        ? colors.info
                                        : colors.textMuted,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          contextActions: contextActions,
          onTap: () => _navigateToForm(context, institution: institution),
        );
      },
    );
  }

  void _handleMenuAction(String action, Institution institution,
      InstitutionProvider provider) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.accessToken;

    switch (action) {
      case 'create_admin':
        _navigateToCreateInstitutionAdmin(institution);
        break;

      case 'edit':
        _navigateToForm(context, institution: institution);
        break;

      case 'toggle_status':
        final newStatus = !institution.activa;
        if (token == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content:
                  Text('Debes iniciar sesión para modificar la institución')));
          return;
        }

        final success = await provider.updateInstitution(
          token,
          institution.id,
          activa: newStatus,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Institución ${newStatus ? 'activada' : 'desactivada'} correctamente',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.onPrimary),
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
        break;

      case 'delete':
        _showDeleteConfirmationDialog(institution, provider);
        break;
      case 'manage_admins':
        // Navegar a la pantalla de gestión de administradores
        context.push('/institutions/${institution.id}/admins');
        break;
    }
  }

  void _showDeleteConfirmationDialog(
      Institution institution, InstitutionProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar Institución',
            style: Theme.of(context).textTheme.headlineSmall),
        content: Text(
          '¿Estás seguro de que quieres eliminar "${institution.nombre}"?\n\n'
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
              await _deleteInstitution(institution, provider);
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

  Future<void> _deleteInstitution(
      Institution institution, InstitutionProvider provider) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.accessToken;

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Debes iniciar sesión para eliminar la institución')));
      return;
    }

    final success = await provider.deleteInstitution(
      token,
      institution.id,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Institución eliminada correctamente',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Theme.of(context).colorScheme.onPrimary),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  void _navigateToForm(BuildContext context, {Institution? institution}) {
    // Navegar con go_router pasando la institución como extra
    context.push('/institutions/form', extra: institution);
  }

  void _navigateToCreateInstitutionAdmin(Institution institution) {
    // Navegar con go_router pasando la institución como extra
    context.push('/institutions/create-admin', extra: institution);
  }
}
