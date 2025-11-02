import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/institution.dart';
import '../../providers/auth_provider.dart';
import '../../providers/institution_provider.dart';
import '../../theme/theme_extensions.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/common/management_scaffold.dart';
import 'institution_form_screen.dart';
import 'create_institution_admin_screen.dart';

class InstitutionsListScreen extends StatefulWidget {
  const InstitutionsListScreen({super.key});

  @override
  State<InstitutionsListScreen> createState() => _InstitutionsListScreenState();
}

class _InstitutionsListScreenState extends State<InstitutionsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounceTimer;
  
  // Estado centralizado de filtros
  String _searchQuery = '';
  bool? _statusFilter; // null = todas, true = activas, false = inactivas

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
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final institutionProvider = Provider.of<InstitutionProvider>(context, listen: false);

      if (authProvider.accessToken != null && institutionProvider.hasMoreData && !institutionProvider.isLoadingMore) {
        institutionProvider.loadMoreInstitutions(
          authProvider.accessToken!,
          search: _searchQuery.isNotEmpty ? _searchQuery : null,
          activa: _statusFilter,
        );
      }
    }
  }

  Future<void> _loadInstitutions() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final institutionProvider = Provider.of<InstitutionProvider>(context, listen: false);

    if (authProvider.accessToken != null) {
      debugPrint('Cargando instituciones con token: ${authProvider.accessToken!.substring(0, 20)}...');
      await institutionProvider.loadInstitutions(
        authProvider.accessToken!,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        activa: _statusFilter,
      );
      debugPrint('Instituciones cargadas: ${institutionProvider.institutions.length}');
      debugPrint('Estado del provider: ${institutionProvider.state}');
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
      setState(() {
        _searchQuery = query;
      });
      _loadInstitutions();
    });
  }

  void _onStatusFilterChanged(bool? status) {
    setState(() {
      _statusFilter = status;
    });
    _loadInstitutions();
  }

  Future<void> _loadPage(int page) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final institutionProvider = Provider.of<InstitutionProvider>(context, listen: false);

    if (authProvider.accessToken != null) {
      await institutionProvider.loadInstitutions(
        authProvider.accessToken!,
        page: page,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        activa: _statusFilter,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, InstitutionProvider>(
      builder: (context, authProvider, institutionProvider, child) {
        return ManagementScaffold(
          title: "Gestión de Instituciones",
          isLoading: institutionProvider.isLoading && institutionProvider.institutions.isEmpty,
          hasError: institutionProvider.hasError,
          errorMessage: institutionProvider.errorMessage ?? 'Error desconocido',
          itemCount: institutionProvider.institutions.length,
          itemBuilder: (context, index) => _buildInstitutionCard(
            institutionProvider.institutions[index],
            institutionProvider,
            context,
          ),
          hasMoreData: institutionProvider.hasMoreData,
          onRefresh: () => _loadInstitutions(),
          scrollController: _scrollController,
          floatingActionButton: FloatingActionButton(
            key: const Key('addInstitutionButton'),
            onPressed: () => _navigateToForm(context),
            backgroundColor: context.colors.primary,
            child: Icon(Icons.add, color: context.colors.getTextColorForBackground(context.colors.primary)),
          ),
          filterWidgets: _buildFilterWidgets(context),
          statisticWidgets: _buildStatisticWidgets(context, institutionProvider),
          paginationInfo: institutionProvider.paginationInfo,
          onPageChange: _loadPage,
          emptyStateTitle: _searchQuery.isNotEmpty ? 'No se encontraron instituciones' : 'No hay instituciones',
          emptyStateMessage: _searchQuery.isNotEmpty ? 'Intenta con otros términos de búsqueda' : 'Comienza creando tu primera institución',
          emptyStateIcon: _searchQuery.isNotEmpty ? Icons.search_off : Icons.business,
        );
      },
    );
  }

  List<Widget> _buildFilterWidgets(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final textStyles = context.textStyles;

    return [
      TextField(
        key: const Key('searchInstitutionField'),
        controller: _searchController,
        style: textStyles.bodyLarge,
        decoration: InputDecoration(
          hintText: 'Buscar por nombre, código o email...',
          hintStyle: textStyles.bodyMedium.withColor(colors.textMuted),
          prefixIcon: Icon(Icons.search, color: colors.textSecondary),
          suffixIcon: _searchQuery.isNotEmpty
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
            label: const Text('Todas'),
            selected: _statusFilter == null,
            onSelected: (selected) {
              if (selected) _onStatusFilterChanged(null);
            },
          ),
          SizedBox(width: spacing.md),
          FilterChip(
            label: const Text('Activas'),
            selected: _statusFilter == true,
            onSelected: (selected) {
              if (selected) _onStatusFilterChanged(true);
            },
          ),
          SizedBox(width: spacing.md),
          FilterChip(
            label: const Text('Inactivas'),
            selected: _statusFilter == false,
            onSelected: (selected) {
              if (selected) _onStatusFilterChanged(false);
            },
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildStatisticWidgets(BuildContext context, InstitutionProvider provider) {
    return [
      _buildCompactStat(
        'Total',
        provider.totalInstitutions.toString(),
        Icons.business,
        context.colors.primary,
        context.textStyles,
      ),
      Container(
        height: 24,
        width: 1,
        color: context.colors.border,
      ),
      _buildCompactStat(
        'Activas',
        provider.activeInstitutionsCount.toString(),
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
        'Inactivas',
        provider.inactiveInstitutionsCount.toString(),
        Icons.cancel,
        context.colors.error,
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

  Widget _buildInstitutionCard(Institution institution, InstitutionProvider provider, BuildContext context) {
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
          backgroundColor: institution.activa ? colors.success : colors.error,
          child: Icon(
            institution.activa ? Icons.check : Icons.close,
            color: colors.surface,
          ),
        ),
        title: Text(
          institution.nombre,
          style: textStyles.titleMedium.bold,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (institution.email != null) Row(children: [
              Icon(Icons.email_outlined, size: 14, color: colors.textSecondary),
              SizedBox(width: 4),
              Text(institution.email!, style: textStyles.bodySmall),
            ]),
            if (institution.telefono != null) Row(children: [
              Icon(Icons.phone_outlined, size: 14, color: colors.textSecondary),
              SizedBox(width: 4),
              Text(institution.telefono!, style: textStyles.bodySmall),
            ]),
          ],
        ),
        trailing: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final userRole = authProvider.user?['rol'] as String?;
            final isSuperAdmin = userRole == 'super_admin';
            
            return PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value, institution, provider),
              itemBuilder: (context) => [
                if (isSuperAdmin) PopupMenuItem(
                  value: 'create_admin',
                  child: Row(
                    children: [
                      Icon(Icons.admin_panel_settings, color: colors.primary),
                      SizedBox(width: spacing.sm),
                      Text('Crear Administrador', style: textStyles.bodyMedium.withColor(colors.primary)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: colors.textSecondary),
                      SizedBox(width: spacing.sm),
                      Text('Editar', style: textStyles.bodyMedium),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle_status',
                  child: Row(
                    children: [
                      Icon(Icons.toggle_on, color: colors.textSecondary),
                      SizedBox(width: spacing.sm),
                      Text('Cambiar Estado', style: textStyles.bodyMedium),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: colors.error),
                      SizedBox(width: spacing.sm),
                      Text('Eliminar', style: textStyles.bodyMedium.withColor(colors.error)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        onTap: () => _navigateToForm(context, institution: institution),
      ),
    );
  }

  void _handleMenuAction(String action, Institution institution, InstitutionProvider provider) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    switch (action) {
      case 'create_admin':
        _navigateToCreateInstitutionAdmin(institution);
        break;
        
      case 'edit':
        _navigateToForm(context, institution: institution);
        break;

      case 'toggle_status':
        final newStatus = !institution.activa;
        final success = await provider.updateInstitution(
          authProvider.accessToken!,
          institution.id,
          activa: newStatus,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Institución ${newStatus ? 'activada' : 'desactivada'} correctamente',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onPrimary),
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
        break;

      case 'delete':
        _showDeleteConfirmationDialog(institution, provider);
        break;
    }
  }

  void _showDeleteConfirmationDialog(Institution institution, InstitutionProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar Institución', style: Theme.of(context).textTheme.headlineSmall),
        content: Text(
          '¿Estás seguro de que quieres eliminar "${institution.nombre}"?\n\n'
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
              await _deleteInstitution(institution, provider);
            },
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: Text('Eliminar', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteInstitution(Institution institution, InstitutionProvider provider) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await provider.deleteInstitution(
      authProvider.accessToken!,
      institution.id,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Institución eliminada correctamente',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onPrimary),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  void _navigateToForm(BuildContext context, {Institution? institution}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InstitutionFormScreen(institution: institution),
      ),
    );
  }

  void _navigateToCreateInstitutionAdmin(Institution institution) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateInstitutionAdminScreen(institution: institution),
      ),
    );
  }
}