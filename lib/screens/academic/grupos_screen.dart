import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/grupo.dart';
import '../../providers/auth_provider.dart';
import '../../providers/grupo_provider.dart';
import '../../services/academic_service.dart' as academic_service;
import '../../theme/theme_extensions.dart';
import '../../widgets/components/index.dart';

class GruposScreen extends StatefulWidget {
  const GruposScreen({super.key});

  @override
  State<GruposScreen> createState() => _GruposScreenState();
}

class _GruposScreenState extends State<GruposScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounceTimer;

  // Estado centralizado de filtros
  String _searchQuery = '';
  final String _selectedPeriodoId = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGrupos();
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
    if (_isSearching) return;

    final grupoProvider = Provider.of<GrupoProvider>(context, listen: false);

    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _loadMoreGrupos(grupoProvider, authProvider.accessToken);
    }
  }

  Future<void> _loadGrupos() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final grupoProvider = Provider.of<GrupoProvider>(context, listen: false);

    if (authProvider.accessToken == null) {
      debugPrint('Error: No hay token de acceso para cargar grupos.');
      return;
    }

    await grupoProvider.loadGrupos(
      authProvider.accessToken!,
      page: 1,
      limit: 10,
      periodoId: _selectedPeriodoId.isEmpty ? null : _selectedPeriodoId,
      search: _searchQuery.isEmpty ? null : _searchQuery,
    );
  }

  Future<void> _loadMoreGrupos(GrupoProvider provider, String? accessToken) async {
    if (accessToken == null || provider.isLoadingMore || !provider.hasMoreData) return;

    await provider.loadMoreGrupos(
      accessToken,
      periodoId: _selectedPeriodoId.isEmpty ? null : _selectedPeriodoId,
      search: _searchQuery.isEmpty ? null : _searchQuery,
    );
  }

  void _onSearchChanged(String query) {
    _searchDebounceTimer?.cancel();

    setState(() {
      _isSearching = query.isNotEmpty;
    });

    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query.trim();
      });
      _loadGrupos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, GrupoProvider>(
      builder: (context, authProvider, grupoProvider, child) {
        return ClarityManagementPage(
          title: 'Gestión de Grupos',
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
      // TODO: Agregar filtro por periodo académico cuando esté disponible
      Text(
        'Próximamente: Filtro por periodo académico',
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
        title: 'Estudiantes',
        value: '0', // TODO: Calcular total de estudiantes
        icon: Icons.people,
        color: colors.info,
      ),
    ];
  }

  Widget _buildGrupoCard(Grupo grupo, GrupoProvider provider, BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;

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
        backgroundColor: colors.info,
        child: Text(
          grupo.grado,
          style: textStyles.labelMedium.copyWith(color: colors.white),
        ),
      ),
      title: grupo.nombre,
      subtitle: 'Grado: ${grupo.grado}${grupo.seccion != null ? ' - Sección: ${grupo.seccion}' : ''}',
      badgeText: grupo.periodoAcademico.activo ? 'Activo' : 'Inactivo',
      badgeColor: grupo.periodoAcademico.activo ? colors.success : colors.error,
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

    final success = await provider.deleteGrupo(
      authProvider.accessToken!,
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
    // TODO: Implementar navegación a detalle de grupo
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Detalle de grupo: ${grupo.nombre}')),
    );
  }
}

// Diálogo para crear grupo
class CreateGrupoDialog extends StatefulWidget {
  const CreateGrupoDialog({super.key});

  @override
  State<CreateGrupoDialog> createState() => _CreateGrupoDialogState();
}

class _CreateGrupoDialogState extends State<CreateGrupoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _gradoController = TextEditingController();
  final _seccionController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _gradoController.dispose();
    _seccionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    return AlertDialog(
      title: Text('Crear Grupo', style: textStyles.headlineMedium),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nombreController,
              decoration: InputDecoration(
                labelText: 'Nombre del Grupo',
                hintText: 'Ej: Grupo A, 1ro Básico A',
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
              controller: _gradoController,
              decoration: InputDecoration(
                labelText: 'Grado',
                hintText: 'Ej: 1ro, 2do, 3ro',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El grado es requerido';
                }
                return null;
              },
            ),
            SizedBox(height: spacing.md),
            TextFormField(
              controller: _seccionController,
              decoration: InputDecoration(
                labelText: 'Sección (opcional)',
                hintText: 'Ej: A, B, C',
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
          onPressed: _isLoading ? null : _createGrupo,
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

  Future<void> _createGrupo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final grupoProvider = Provider.of<GrupoProvider>(context, listen: false);

      // TODO: Obtener periodo académico activo
      const periodoId = '550e8400-e29b-41d4-a716-446655440000'; // ID por defecto

      final success = await grupoProvider.createGrupo(
        authProvider.accessToken!,
        academic_service.CreateGrupoRequest(
          nombre: _nombreController.text.trim(),
          grado: _gradoController.text.trim(),
          seccion: _seccionController.text.trim().isEmpty ? null : _seccionController.text.trim(),
          periodoId: periodoId,
        ),
      );

      if (success && mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Grupo creado correctamente')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(grupoProvider.errorMessage ?? 'Error al crear grupo'),
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

// Diálogo para editar grupo
class EditGrupoDialog extends StatefulWidget {
  final Grupo grupo;

  const EditGrupoDialog({super.key, required this.grupo});

  @override
  State<EditGrupoDialog> createState() => _EditGrupoDialogState();
}

class _EditGrupoDialogState extends State<EditGrupoDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  late final TextEditingController _gradoController;
  late final TextEditingController _seccionController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.grupo.nombre);
    _gradoController = TextEditingController(text: widget.grupo.grado);
    _seccionController = TextEditingController(text: widget.grupo.seccion ?? '');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _gradoController.dispose();
    _seccionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    return AlertDialog(
      title: Text('Editar Grupo', style: textStyles.headlineMedium),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nombreController,
              decoration: InputDecoration(
                labelText: 'Nombre del Grupo',
                hintText: 'Ej: Grupo A, 1ro Básico A',
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
              controller: _gradoController,
              decoration: InputDecoration(
                labelText: 'Grado',
                hintText: 'Ej: 1ro, 2do, 3ro',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El grado es requerido';
                }
                return null;
              },
            ),
            SizedBox(height: spacing.md),
            TextFormField(
              controller: _seccionController,
              decoration: InputDecoration(
                labelText: 'Sección (opcional)',
                hintText: 'Ej: A, B, C',
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
          onPressed: _isLoading ? null : _updateGrupo,
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

  Future<void> _updateGrupo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final grupoProvider = Provider.of<GrupoProvider>(context, listen: false);

      final success = await grupoProvider.updateGrupo(
        authProvider.accessToken!,
        widget.grupo.id,
        academic_service.UpdateGrupoRequest(
          nombre: _nombreController.text.trim(),
          grado: _gradoController.text.trim(),
          seccion: _seccionController.text.trim().isEmpty ? null : _seccionController.text.trim(),
        ),
      );

      if (success && mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Grupo actualizado correctamente')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(grupoProvider.errorMessage ?? 'Error al actualizar grupo'),
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