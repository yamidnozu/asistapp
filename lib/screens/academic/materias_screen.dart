import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/components/clarity_management_page.dart';
import '../../widgets/components/clarity_components.dart';
import '../../theme/theme_extensions.dart';
import '../../services/academic_service.dart' as academic_service;
import '../../providers/materia_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/materia.dart';

class MateriasScreen extends StatefulWidget {
  const MateriasScreen({super.key});

  @override
  State<MateriasScreen> createState() => _MateriasScreenState();
}

class _MateriasScreenState extends State<MateriasScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSearching = false;

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

    if (authProvider.accessToken != null) {
      await materiaProvider.loadMaterias(authProvider.accessToken!, search: search);
    }
  }

  Future<void> _loadMoreMaterias() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final materiaProvider = Provider.of<MateriaProvider>(context, listen: false);

    if (authProvider.accessToken != null) {
      final search = _isSearching ? _searchController.text.trim() : null;
      await materiaProvider.loadMoreMaterias(authProvider.accessToken!, search: search);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, MateriaProvider>(
      builder: (context, authProvider, materiaProvider, child) {
        return ClarityManagementPage(
          title: 'Gestión de Materias',
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
      // TODO: Agregar filtros adicionales cuando estén disponibles
      Text(
        'Próximamente: Más filtros disponibles',
        style: textStyles.bodySmall.copyWith(color: colors.textMuted),
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

    final success = await provider.deleteMateria(
      authProvider.accessToken!,
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
    // TODO: Implementar navegación a detalle de materia
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Detalle de materia: ${materia.nombre}')),
    );
  }
}

// Diálogo para crear materia
class CreateMateriaDialog extends StatefulWidget {
  const CreateMateriaDialog({super.key});

  @override
  State<CreateMateriaDialog> createState() => _CreateMateriaDialogState();
}

class _CreateMateriaDialogState extends State<CreateMateriaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _codigoController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _codigoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    return AlertDialog(
      title: Text('Crear Materia', style: textStyles.headlineMedium),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nombreController,
              decoration: InputDecoration(
                labelText: 'Nombre de la Materia',
                hintText: 'Ej: Matemáticas, Lenguaje, Ciencias',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El nombre es requerido';
                }
                return null;
              },
            ),
            SizedBox(height: spacing.md),
            TextFormField(
              controller: _codigoController,
              decoration: InputDecoration(
                labelText: 'Código (opcional)',
                hintText: 'Ej: MAT101, LEN201',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createMateria,
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('Crear'),
        ),
      ],
    );
  }

  Future<void> _createMateria() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final materiaProvider = Provider.of<MateriaProvider>(context, listen: false);

      final success = await materiaProvider.createMateria(
        authProvider.accessToken!,
        academic_service.CreateMateriaRequest(
          nombre: _nombreController.text.trim(),
          codigo: _codigoController.text.trim().isEmpty ? null : _codigoController.text.trim(),
        ),
      );

      if (success && mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Materia creada correctamente')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(materiaProvider.errorMessage ?? 'Error al crear materia'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

// Diálogo para editar materia
class EditMateriaDialog extends StatefulWidget {
  final Materia materia;

  const EditMateriaDialog({super.key, required this.materia});

  @override
  State<EditMateriaDialog> createState() => _EditMateriaDialogState();
}

class _EditMateriaDialogState extends State<EditMateriaDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _codigoController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.materia.nombre);
    _codigoController = TextEditingController(text: widget.materia.codigo ?? '');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _codigoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    return AlertDialog(
      title: Text('Editar Materia', style: textStyles.headlineMedium),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nombreController,
              decoration: InputDecoration(
                labelText: 'Nombre de la Materia',
                hintText: 'Ej: Matemáticas, Lenguaje, Ciencias',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El nombre es requerido';
                }
                return null;
              },
            ),
            SizedBox(height: spacing.md),
            TextFormField(
              controller: _codigoController,
              decoration: InputDecoration(
                labelText: 'Código (opcional)',
                hintText: 'Ej: MAT101, LEN201',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateMateria,
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('Actualizar'),
        ),
      ],
    );
  }

  Future<void> _updateMateria() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final materiaProvider = Provider.of<MateriaProvider>(context, listen: false);

      final success = await materiaProvider.updateMateria(
        authProvider.accessToken!,
        widget.materia.id,
        academic_service.UpdateMateriaRequest(
          nombre: _nombreController.text.trim(),
          codigo: _codigoController.text.trim().isEmpty ? null : _codigoController.text.trim(),
        ),
      );

      if (success && mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Materia actualizada correctamente')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(materiaProvider.errorMessage ?? 'Error al actualizar materia'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}