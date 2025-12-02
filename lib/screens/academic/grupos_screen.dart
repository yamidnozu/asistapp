import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/components/clarity_management_page.dart';
import '../../widgets/components/clarity_components.dart';
import '../../theme/theme_extensions.dart';
import '../../providers/grupo_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/grupo.dart';
import 'grupo_dialogs.dart';

class GruposScreen extends StatefulWidget {
  const GruposScreen({super.key});

  @override
  State<GruposScreen> createState() => _GruposScreenState();
}

class _GruposScreenState extends State<GruposScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGrupos();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    setState(() => _isSearching = query.isNotEmpty);

    if (query.isNotEmpty) {
      // Implementar búsqueda local si es necesario
      // Por ahora, recargamos con el filtro del backend
      _loadGrupos(search: query);
    } else {
      _loadGrupos();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreGrupos();
    }
  }

  Future<void> _loadGrupos({String? search}) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final grupoProvider = Provider.of<GrupoProvider>(context, listen: false);

    final token = authProvider.accessToken;
    if (token != null) {
      await grupoProvider.loadGrupos(token, search: search);
    }
  }

  Future<void> _loadMoreGrupos() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final grupoProvider = Provider.of<GrupoProvider>(context, listen: false);

    final token = authProvider.accessToken;
    if (token != null) {
      final search = _isSearching ? _searchController.text.trim() : null;
      await grupoProvider.loadMoreGrupos(token, search: search);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GrupoProvider>(
      builder: (context, grupoProvider, child) {
        return ClarityManagementPage(
          title: 'Gestión de Grupos',
          backRoute: '/academic',
          isLoading: grupoProvider.isLoading,
          hasError: grupoProvider.hasError,
          errorMessage: grupoProvider.errorMessage,
          itemCount: grupoProvider.grupos.length,
          itemBuilder: (context, index) {
            final grupo = grupoProvider.grupos[index];
            return _buildGrupoCard(grupo, grupoProvider, context);
          },
          filterWidgets: _buildFilterWidgets(context),
          statisticWidgets: _buildStatisticWidgets(context, grupoProvider),
          onRefresh: _loadGrupos,
          scrollController: _scrollController,
          hasMoreData: grupoProvider.hasMoreData,
          isLoadingMore: grupoProvider.isLoadingMore,
          emptyStateWidget: ClarityEmptyState(
            icon: _isSearching ? Icons.search_off : Icons.group,
            title: _isSearching
              ? 'No se encontraron resultados'
              : 'Aún no has creado ningún grupo',
            subtitle: _isSearching
              ? 'Intenta con otros términos de búsqueda'
              : 'Comienza creando tu primer grupo académico',
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showCreateGrupoDialog(context),
            tooltip: 'Crear Grupo',
            child: const Icon(Icons.add),
          ),
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
        controller: _searchController,
        style: textStyles.bodyLarge,
        decoration: InputDecoration(
          hintText: 'Buscar por nombre, grado o sección...',
          hintStyle: textStyles.bodyMedium.copyWith(color: colors.textMuted),
          prefixIcon: Icon(Icons.search, color: colors.textSecondary),
          suffixIcon: _isSearching
              ? IconButton(
                  icon: Icon(Icons.clear, color: colors.textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged();
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
        onChanged: (value) => _onSearchChanged(),
      ),
      SizedBox(height: spacing.sm),
      // TODO: Agregar filtros adicionales cuando estén disponibles
      Text(
        'Próximamente: Más filtros disponibles',
        style: textStyles.bodySmall.copyWith(color: colors.textMuted),
      ),
    ];
  }

  List<Widget> _buildStatisticWidgets(BuildContext context, GrupoProvider provider) {
    final stats = provider.getGruposStatistics();
    final colors = context.colors;

    return [
      ClarityCompactStat(
        title: 'Total',
        value: stats['total'].toString(),
        icon: Icons.group,
        color: colors.primary,
      ),
      ClarityCompactStat(
        title: 'Activos',
        value: stats['activos'].toString(),
        icon: Icons.check_circle,
        color: colors.success,
      ),
      ClarityCompactStat(
        title: 'Inactivos',
        value: stats['inactivos'].toString(),
        icon: Icons.cancel,
        color: colors.warning,
      ),
    ];
  }

  Widget _buildGrupoCard(Grupo grupo, GrupoProvider provider, BuildContext context) {
    final colors = context.colors;

    final List<ClarityContextMenuAction> contextActions = [
      ClarityContextMenuAction(
        label: 'Editar',
        icon: Icons.edit,
        color: colors.primary,
        onPressed: () => _showEditGrupoDialog(context, grupo),
      ),
      ClarityContextMenuAction(
        label: 'Eliminar',
        icon: Icons.delete,
        color: colors.error,
        onPressed: () => _showDeleteConfirmationDialog(grupo, provider),
      ),
    ];

    return ClarityListItem(
      leading: CircleAvatar(
        backgroundColor: colors.primary,
        child: Icon(
          Icons.group,
          color: colors.white,
        ),
      ),
      title: grupo.nombre,
      subtitle: '${grupo.nombreCompleto} • ${grupo.estudiantesGruposCount} estudiantes • ${grupo.horariosCount} horarios',
      contextActions: contextActions,
      onTap: () => _navigateToGrupoDetail(grupo),
    );
  }

  void _showCreateGrupoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateGrupoDialog(),
    ).then((result) {
      if (result == true) {
        _loadGrupos(); // Recargar la lista
      }
    });
  }

  void _showEditGrupoDialog(BuildContext context, Grupo grupo) {
    showDialog(
      context: context,
      builder: (context) => EditGrupoDialog(grupo: grupo),
    ).then((result) {
      if (result == true) {
        _loadGrupos(); // Recargar la lista
      }
    });
  }

  void _showDeleteConfirmationDialog(Grupo grupo, GrupoProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar Grupo', style: Theme.of(context).textTheme.headlineSmall),
        content: Text(
          '¿Estás seguro de que quieres eliminar "${grupo.nombre}"?\n\n'
          'Esta acción no se puede deshacer y afectará a ${grupo.estudiantesGruposCount} estudiantes.',
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
              await _deleteGrupo(grupo, provider);
            },
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: Text('Eliminar', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteGrupo(Grupo grupo, GrupoProvider provider) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final token = authProvider.accessToken;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes iniciar sesión para eliminar un grupo')));
      return;
    }

    final success = await provider.deleteGrupo(
      token,
      grupo.id,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Grupo eliminado correctamente',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onPrimary),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      await _loadGrupos();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Error al eliminar grupo',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onError),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _navigateToGrupoDetail(Grupo grupo) {
    context.push('/academic/grupos/${grupo.id}', extra: grupo);
  }
}
