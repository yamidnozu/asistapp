import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/components/clarity_management_page.dart';
import '../../widgets/components/clarity_components.dart';
import '../../theme/theme_extensions.dart';
import '../../providers/materia_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/materia.dart';
import 'materia_dialogs.dart';

class MateriasScreen extends StatefulWidget {
  const MateriasScreen({super.key});

  @override
  State<MateriasScreen> createState() => _MateriasScreenState();
}

class _MateriasScreenState extends State<MateriasScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSearching = false;
  bool? _filterActivo;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMaterias();
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
      _loadMaterias(search: query);
    } else {
      _loadMaterias();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreMaterias();
    }
  }

  Future<void> _loadMaterias({String? search}) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final materiaProvider = Provider.of<MateriaProvider>(context, listen: false);

    final token = authProvider.accessToken;
    if (token != null) {
      await materiaProvider.loadMaterias(token, search: search);
    }
  }

  Future<void> _loadMoreMaterias() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final materiaProvider = Provider.of<MateriaProvider>(context, listen: false);

    final token = authProvider.accessToken;
    if (token != null) {
      final search = _isSearching ? _searchController.text.trim() : null;
      await materiaProvider.loadMoreMaterias(token, search: search);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, MateriaProvider>(
      builder: (context, authProvider, materiaProvider, child) {
        return ClarityManagementPage(
          title: 'Gestión de Materias',
          backRoute: '/academic',
          isLoading: materiaProvider.isLoading,
          hasError: materiaProvider.hasError,
          errorMessage: materiaProvider.errorMessage,
          itemCount: materiaProvider.materias.length,
          itemBuilder: (context, index) {
            final materia = materiaProvider.materias[index];
            return _buildMateriaCard(materia, materiaProvider, context);
          },
          filterWidgets: _buildFilterWidgets(context),
          statisticWidgets: _buildStatisticWidgets(context, materiaProvider),
          onRefresh: _loadMaterias,
          scrollController: _scrollController,
          hasMoreData: materiaProvider.hasMoreData,
          isLoadingMore: materiaProvider.isLoadingMore,
          emptyStateWidget: ClarityEmptyState(
            icon: _isSearching ? Icons.search_off : Icons.subject,
            title: _isSearching
              ? 'No se encontraron resultados'
              : 'Aún no has creado ninguna materia',
            subtitle: _isSearching
              ? 'Intenta con otros términos de búsqueda'
              : 'Comienza creando tu primera materia académica',
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showCreateMateriaDialog(context),
            tooltip: 'Crear Materia',
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
          hintText: 'Buscar por nombre o código...',
          hintStyle: textStyles.bodyMedium.withColor(colors.textMuted),
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
      // Filtro por estado activo/inactivo
      Row(
        children: [
          FilterChip(
            label: const Text('Todas'),
            selected: _filterActivo == null,
            onSelected: (_) {
              setState(() => _filterActivo = null);
              _loadMaterias(search: _searchController.text.trim());
            },
            selectedColor: colors.primary.withValues(alpha: 0.2),
            checkmarkColor: colors.primary,
            labelStyle: TextStyle(
              color: _filterActivo == null ? colors.primary : colors.textSecondary,
              fontSize: 12,
            ),
          ),
          SizedBox(width: spacing.sm),
          FilterChip(
            label: const Text('Activas'),
            selected: _filterActivo == true,
            onSelected: (_) {
              setState(() => _filterActivo = true);
              _loadMaterias(search: _searchController.text.trim());
            },
            selectedColor: colors.success.withValues(alpha: 0.2),
            checkmarkColor: colors.success,
            labelStyle: TextStyle(
              color: _filterActivo == true ? colors.success : colors.textSecondary,
              fontSize: 12,
            ),
          ),
          SizedBox(width: spacing.sm),
          FilterChip(
            label: const Text('Inactivas'),
            selected: _filterActivo == false,
            onSelected: (_) {
              setState(() => _filterActivo = false);
              _loadMaterias(search: _searchController.text.trim());
            },
            selectedColor: colors.error.withValues(alpha: 0.2),
            checkmarkColor: colors.error,
            labelStyle: TextStyle(
              color: _filterActivo == false ? colors.error : colors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildStatisticWidgets(BuildContext context, MateriaProvider provider) {
    final stats = provider.getMateriasStatistics();
    final colors = context.colors;

    return [
      ClarityCompactStat(
        title: 'Total',
        value: stats['total'].toString(),
        icon: Icons.subject,
        color: colors.primary,
      ),
      ClarityCompactStat(
        title: 'Con Código',
        value: stats['con_codigo'].toString(),
        icon: Icons.tag,
        color: colors.success,
      ),
      ClarityCompactStat(
        title: 'Sin Código',
        value: stats['sin_codigo'].toString(),
        icon: Icons.label_off,
        color: colors.warning,
      ),
    ];
  }

  Widget _buildMateriaCard(Materia materia, MateriaProvider provider, BuildContext context) {
    final colors = context.colors;

    final List<ClarityContextMenuAction> contextActions = [
      ClarityContextMenuAction(
        label: 'Editar',
        icon: Icons.edit,
        color: colors.primary,
        onPressed: () => _showEditMateriaDialog(context, materia),
      ),
      ClarityContextMenuAction(
        label: 'Eliminar',
        icon: Icons.delete,
        color: colors.error,
        onPressed: () => _showDeleteConfirmationDialog(materia, provider),
      ),
    ];

    return ClarityListItem(
      leading: CircleAvatar(
        backgroundColor: colors.primary,
        child: Icon(
          Icons.subject,
          color: colors.white,
        ),
      ),
      title: materia.nombre,
      subtitle: materia.codigo != null ? 'Código: ${materia.codigo}' : 'Sin código asignado',
      contextActions: contextActions,
      onTap: () => _navigateToMateriaDetail(materia),
    );
  }

  void _showCreateMateriaDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateMateriaDialog(),
    ).then((result) {
      if (result == true) {
        _loadMaterias(); // Recargar la lista
      }
    });
  }

  void _showEditMateriaDialog(BuildContext context, Materia materia) {
    showDialog(
      context: context,
      builder: (context) => EditMateriaDialog(materia: materia),
    ).then((result) {
      if (result == true) {
        _loadMaterias(); // Recargar la lista
      }
    });
  }

  void _showDeleteConfirmationDialog(Materia materia, MateriaProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar Materia', style: Theme.of(context).textTheme.headlineSmall),
        content: Text(
          '¿Estás seguro de que quieres eliminar "${materia.nombre}"?\n\n'
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
              await _deleteMateria(materia, provider);
            },
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: Text('Eliminar', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMateria(Materia materia, MateriaProvider provider) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final token = authProvider.accessToken;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes iniciar sesión para eliminar una materia')));
      return;
    }

    final success = await provider.deleteMateria(
      token,
      materia.id,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Materia eliminada correctamente',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onPrimary),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      await _loadMaterias();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Error al eliminar materia',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onError),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _navigateToMateriaDetail(Materia materia) {
    // PENDIENTE: Implementar navegación a detalle de materia
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Detalle de materia: ${materia.nombre}')),
    );
  }
}

// NOTA: Las clases de diálogos fueron movidas a lib/screens/academic/materia_dialogs.dart