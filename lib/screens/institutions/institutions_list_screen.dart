import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/institution.dart';
import '../../providers/auth_provider.dart';
import '../../providers/institution_provider.dart';
import '../../theme/theme_extensions.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/responsive_utils.dart';
import '../../utils/app_routes.dart';
import '../../widgets/dashboard_widgets.dart';
import 'institution_form_screen.dart';

class InstitutionsListScreen extends StatefulWidget {
  const InstitutionsListScreen({super.key});

  @override
  State<InstitutionsListScreen> createState() => _InstitutionsListScreenState();
}

class _InstitutionsListScreenState extends State<InstitutionsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showActiveOnly = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Cargar instituciones después de que el widget se construya completamente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInstitutions();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInstitutions() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final institutionProvider = Provider.of<InstitutionProvider>(context, listen: false);

    if (authProvider.accessToken != null) {
      debugPrint('Cargando instituciones con token: ${authProvider.accessToken!.substring(0, 20)}...');
      await institutionProvider.loadInstitutions(authProvider.accessToken!);
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
    setState(() {
      _isSearching = query.isNotEmpty;
    });
  }

  List<Institution> _getFilteredInstitutions(InstitutionProvider provider) {
    List<Institution> institutions;

    if (_isSearching) {
      institutions = provider.searchInstitutions(_searchController.text);
    } else {
      institutions = _showActiveOnly ? provider.activeInstitutions : provider.institutions;
    }

    return institutions;
  }

  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final textStyles = context.textStyles;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: DashboardAppBar(
        title: 'Gestión de Instituciones',
        backgroundColor: colors.primary,
        actions: [
          DashboardAppBarActions(
            userRole: 'Super Admin',
            roleIcon: Icons.verified_user,
            onLogout: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              if (context.mounted) {
                context.go(AppRoutes.login);
              }
            },
          ),
        ],
      ),
      body: Consumer2<AuthProvider, InstitutionProvider>(
        builder: (context, authProvider, institutionProvider, child) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final responsive = ResponsiveUtils.getResponsiveValues(constraints);
              return DashboardBody(
                userGreeting: UserGreetingWidget(
                  userName: authProvider.user?['nombres'] ?? 'Super Admin',
                  responsive: responsive,
                ),
                dashboardOptions: _buildInstitutionsContent(institutionProvider, responsive, colors, spacing, textStyles),
                responsive: responsive,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(context),
        backgroundColor: colors.primary,
        child: Icon(Icons.add, color: colors.getTextColorForBackground(colors.primary)),
      ),
    );
  }

  Widget _buildInstitutionsContent(InstitutionProvider provider, Map<String, dynamic> responsive, AppColors colors, AppSpacing spacing, AppTextStyles textStyles) {
    if (provider.isLoading && provider.institutions.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (provider.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colors.error),
            SizedBox(height: spacing.lg),
            Text(
              'Error al cargar instituciones',
              style: textStyles.headlineMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacing.md),
            Text(
              provider.errorMessage ?? 'Error desconocido',
              style: textStyles.bodyMedium.withColor(colors.textSecondary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacing.lg),
            ElevatedButton(
              onPressed: _loadInstitutions,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary, // Color consistente con el tema
                padding: EdgeInsets.symmetric(
                  horizontal: spacing.lg,
                  vertical: spacing.md,
                ),
              ),
              child: Text('Reintentar', style: textStyles.button), // Usar estilo de botón sin color fijo
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildSearchAndFilters(provider, colors, spacing, textStyles),
        SizedBox(height: spacing.lg),
        _buildStatisticsCards(provider, colors, spacing, textStyles),
        SizedBox(height: spacing.lg),
        // Usar ConstrainedBox en lugar de Expanded para evitar problemas de layout
        ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: 200, // Altura mínima
            maxHeight: MediaQuery.of(context).size.height * 0.6, // Máximo 60% de la pantalla
          ),
          child: _buildInstitutionsList(provider, colors, spacing, textStyles),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters(InstitutionProvider provider, AppColors colors, AppSpacing spacing, AppTextStyles textStyles) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: spacing.lg),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spacing.borderRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(spacing.md), // Reducido de lg a md
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              style: textStyles.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, código o email...',
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
                contentPadding: EdgeInsets.symmetric(horizontal: spacing.md, vertical: spacing.sm), // Reducido padding vertical
              ),
              onChanged: _onSearchChanged,
            ),
            SizedBox(height: spacing.sm), // Reducido de md a sm
            Row(
              children: [
                Text('Mostrar:', style: textStyles.labelMedium),
                SizedBox(width: spacing.md),
                FilterChip(
                  label: const Text('Activas'),  // Sin estilo manual - usa el tema
                  selected: _showActiveOnly && !_isSearching,
                  onSelected: !_isSearching ? (selected) {
                    setState(() => _showActiveOnly = selected);
                  } : null,
                ),
                SizedBox(width: spacing.md),
                FilterChip(
                  label: const Text('Todas'),  // Sin estilo manual - usa el tema
                  selected: !_showActiveOnly && !_isSearching,
                  onSelected: !_isSearching ? (selected) {
                    setState(() => _showActiveOnly = !selected);
                  } : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCards(InstitutionProvider provider, AppColors colors, AppSpacing spacing, AppTextStyles textStyles) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: spacing.lg),
      padding: EdgeInsets.symmetric(horizontal: spacing.md, vertical: spacing.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(spacing.borderRadius),
        border: Border.all(color: colors.borderLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCompactStat(
            'Total',
            provider.totalInstitutions.toString(),
            Icons.business,
            colors.primary,
            textStyles,
          ),
          Container(
            height: 24,
            width: 1,
            color: colors.border,
          ),
          _buildCompactStat(
            'Activas',
            provider.activeInstitutionsCount.toString(),
            Icons.check_circle,
            colors.success,
            textStyles,
          ),
          Container(
            height: 24,
            width: 1,
            color: colors.border,
          ),
          _buildCompactStat(
            'Inactivas',
            provider.inactiveInstitutionsCount.toString(),
            Icons.cancel,
            colors.error,
            textStyles,
          ),
        ],
      ),
    );
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

  Widget _buildInstitutionsList(InstitutionProvider provider, AppColors colors, AppSpacing spacing, AppTextStyles textStyles) {
    final filteredInstitutions = _getFilteredInstitutions(provider);

    if (filteredInstitutions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isSearching ? Icons.search_off : Icons.business,
              size: 64,
              color: colors.textMuted,
            ),
            SizedBox(height: spacing.lg),
            Text(
              _isSearching
                  ? 'No se encontraron instituciones'
                  : 'No hay instituciones ${_showActiveOnly ? 'activas' : ''}',
              style: textStyles.headlineMedium.withColor(colors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: filteredInstitutions.isEmpty ? 200 : null, // Altura fija si está vacío, null si tiene contenido
      child: ListView.builder(
        shrinkWrap: filteredInstitutions.isNotEmpty, // Solo shrinkWrap si hay contenido
        physics: filteredInstitutions.isNotEmpty ? const NeverScrollableScrollPhysics() : null,
        padding: EdgeInsets.symmetric(horizontal: spacing.lg),
        itemCount: filteredInstitutions.length,
        itemBuilder: (context, index) {
          final institution = filteredInstitutions[index];
          return _buildInstitutionCard(institution, provider, colors, spacing, textStyles);
        },
      ),
    );
  }

  Widget _buildInstitutionCard(Institution institution, InstitutionProvider provider, AppColors colors, AppSpacing spacing, AppTextStyles textStyles) {
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
            Text('Código: ${institution.codigo}', style: textStyles.bodySmall),
            if (institution.email != null) Text('Email: ${institution.email}', style: textStyles.bodySmall),
            if (institution.telefono != null) Text('Teléfono: ${institution.telefono}', style: textStyles.bodySmall),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, institution, provider),
          itemBuilder: (context) => [
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
        ),
        onTap: () => _navigateToForm(context, institution: institution),
      ),
    );
  }

  void _handleMenuAction(String action, Institution institution, InstitutionProvider provider) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    switch (action) {
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
}