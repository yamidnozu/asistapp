import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/grupo.dart'; // Para PeriodoAcademico
import '../../providers/auth_provider.dart';
import '../../providers/periodo_academico_provider.dart';
import '../../services/academic_service.dart' as academic_service;
import '../../theme/theme_extensions.dart';
import '../../widgets/components/index.dart';

class PeriodosAcademicosScreen extends StatefulWidget {
  const PeriodosAcademicosScreen({super.key});

  @override
  State<PeriodosAcademicosScreen> createState() => _PeriodosAcademicosScreenState();
}

class _PeriodosAcademicosScreenState extends State<PeriodosAcademicosScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounceTimer;

  // Estado centralizado de filtros
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPeriodos();
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

    final periodoProvider = Provider.of<PeriodoAcademicoProvider>(context, listen: false);

    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _loadMorePeriodos(periodoProvider, authProvider.accessToken);
    }
  }

  Future<void> _loadPeriodos() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final periodoProvider = Provider.of<PeriodoAcademicoProvider>(context, listen: false);

    if (authProvider.accessToken == null) {
      debugPrint('Error: No hay token de acceso para cargar períodos académicos.');
      return;
    }

    await periodoProvider.loadPeriodosAcademicos(
      authProvider.accessToken!,
      page: 1,
      limit: 10,
    );
  }

  Future<void> _loadMorePeriodos(PeriodoAcademicoProvider provider, String? accessToken) async {
    if (accessToken == null || provider.isLoading) return;

    await provider.loadNextPage(accessToken);
  }

  void _onSearchChanged(String query) {
    _searchDebounceTimer?.cancel();

    setState(() {
      _isSearching = query.isNotEmpty;
    });

    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _loadPeriodos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, PeriodoAcademicoProvider>(
      builder: (context, authProvider, periodoProvider, child) {
        return ClarityManagementPage(
          title: 'Gestión de Períodos Académicos',
          isLoading: periodoProvider.isLoading,
          hasError: periodoProvider.hasError,
          errorMessage: periodoProvider.errorMessage,
          itemCount: periodoProvider.periodosAcademicos.length,
          itemBuilder: (context, index) {
            final periodo = periodoProvider.periodosAcademicos[index];
            return _buildPeriodoCard(periodo, periodoProvider, context);
          },
          filterWidgets: _buildFilterWidgets(context),
          statisticWidgets: _buildStatisticWidgets(context, periodoProvider),
          onRefresh: _loadPeriodos,
          scrollController: _scrollController,
          hasMoreData: periodoProvider.paginationInfo?.hasNext ?? false,
          emptyStateWidget: ClarityEmptyState(
            icon: _isSearching ? Icons.search_off : Icons.calendar_today,
            title: _isSearching
              ? 'No se encontraron resultados'
              : 'Aún no has creado ningún período académico',
            subtitle: _isSearching
              ? 'Intenta con otros términos de búsqueda'
              : 'Comienza creando tu primer período académico',
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showCreatePeriodoDialog(context),
            tooltip: 'Crear Período Académico',
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
          hintText: 'Buscar por nombre...',
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
    ];
  }

  List<Widget> _buildStatisticWidgets(BuildContext context, PeriodoAcademicoProvider provider) {
    final stats = provider.getPeriodosStatistics();
    final colors = context.colors;

    return [
      ClarityCompactStat(
        title: 'Total',
        value: stats['total'].toString(),
        icon: Icons.calendar_today,
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
        color: colors.error,
      ),
    ];
  }

  Widget _buildPeriodoCard(PeriodoAcademico periodo, PeriodoAcademicoProvider provider, BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: spacing.md, vertical: spacing.xs),
      child: Padding(
        padding: EdgeInsets.all(spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        periodo.nombre,
                        style: textStyles.headlineSmall,
                      ),
                      SizedBox(height: spacing.xs),
                      Text(
                        'Del ${periodo.fechaInicio.day}/${periodo.fechaInicio.month}/${periodo.fechaInicio.year} al ${periodo.fechaFin.day}/${periodo.fechaFin.month}/${periodo.fechaFin.year}',
                        style: textStyles.bodyMedium.copyWith(color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: spacing.sm, vertical: spacing.xs),
                  decoration: BoxDecoration(
                    color: periodo.activo ? colors.success.withValues(alpha: 0.1) : colors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(spacing.borderRadius),
                  ),
                  child: Text(
                    periodo.activo ? 'Activo' : 'Inactivo',
                    style: textStyles.bodySmall.copyWith(
                      color: periodo.activo ? colors.success : colors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.md),
            Row(
              children: [
                Text(
                  '${0} grupos asociados',
                  style: textStyles.bodySmall.copyWith(color: colors.textMuted),
                ),
                const Spacer(),
                // Toggle status button
                IconButton(
                  icon: Icon(
                    periodo.activo ? Icons.visibility_off : Icons.visibility,
                    color: periodo.activo ? colors.error : colors.success,
                  ),
                  onPressed: () => _togglePeriodoStatus(context, periodo, provider),
                  tooltip: periodo.activo ? 'Desactivar período' : 'Activar período',
                ),
                // Edit button
                IconButton(
                  icon: Icon(Icons.edit, color: colors.primary),
                  onPressed: () => _showEditPeriodoDialog(context, periodo),
                  tooltip: 'Editar período',
                ),
                // Delete button
                IconButton(
                  icon: Icon(Icons.delete, color: colors.error),
                  onPressed: () => _showDeletePeriodoDialog(context, periodo, provider),
                  tooltip: 'Eliminar período',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _togglePeriodoStatus(BuildContext context, PeriodoAcademico periodo, PeriodoAcademicoProvider provider) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final colors = Theme.of(context).colorScheme;

    final success = await provider.togglePeriodoStatus(authProvider.accessToken!, periodo.id);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar( // ignore: use_build_context_synchronously
        SnackBar(
          content: Text('Período ${periodo.activo ? 'desactivado' : 'activado'} correctamente'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar( // ignore: use_build_context_synchronously
        SnackBar(
          content: Text(provider.errorMessage ?? 'Error al cambiar el status del período'),
          backgroundColor: colors.error,
        ),
      );
    }
  }

  void _showCreatePeriodoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreatePeriodoDialog(),
    ).then((result) {
      if (result == true) {
        _loadPeriodos(); // Recargar la lista
      }
    });
  }

  void _showEditPeriodoDialog(BuildContext context, PeriodoAcademico periodo) {
    showDialog(
      context: context,
      builder: (context) => EditPeriodoDialog(periodo: periodo),
    ).then((result) {
      if (result == true) {
        _loadPeriodos(); // Recargar la lista
      }
    });
  }

  void _showDeletePeriodoDialog(BuildContext context, PeriodoAcademico periodo, PeriodoAcademicoProvider provider) {
    final colors = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Período Académico'),
        content: Text(
          '¿Estás seguro de que quieres eliminar el período "${periodo.nombre}"? '
          'Esta acción no se puede deshacer y eliminará todos los grupos asociados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Cerrar diálogo

              final authProvider = Provider.of<AuthProvider>(context, listen: false);

              final success = await provider.deletePeriodoAcademico(authProvider.accessToken!, periodo.id);

              if (!mounted) return;

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar( // ignore: use_build_context_synchronously
                  const SnackBar(content: Text('Período académico eliminado correctamente')),
                );
                _loadPeriodos(); // Recargar la lista
              } else {
                ScaffoldMessenger.of(context).showSnackBar( // ignore: use_build_context_synchronously
                  SnackBar(
                    content: Text(provider.errorMessage ?? 'Error al eliminar el período académico'),
                    backgroundColor: colors.error,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: colors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

// Diálogo para crear período académico
class CreatePeriodoDialog extends StatefulWidget {
  const CreatePeriodoDialog({super.key});

  @override
  State<CreatePeriodoDialog> createState() => _CreatePeriodoDialogState();
}

class _CreatePeriodoDialogState extends State<CreatePeriodoDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  bool _isLoading = false;

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    return AlertDialog(
      title: Text('Crear Período Académico', style: textStyles.headlineMedium),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Período',
                hintText: 'Ej: Año 2025, Semestre 2025-I',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El nombre es requerido';
                }
                return null;
              },
            ),
            SizedBox(height: spacing.md),
            // Fecha de inicio
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() {
                    _fechaInicio = picked;
                  });
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha de Inicio',
                ),
                child: Text(
                  _fechaInicio != null
                      ? '${_fechaInicio!.day}/${_fechaInicio!.month}/${_fechaInicio!.year}'
                      : 'Seleccionar fecha',
                ),
              ),
            ),
            SizedBox(height: spacing.md),
            // Fecha de fin
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _fechaInicio ?? DateTime.now(),
                  firstDate: _fechaInicio ?? DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() {
                    _fechaFin = picked;
                  });
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha de Fin',
                ),
                child: Text(
                  _fechaFin != null
                      ? '${_fechaFin!.day}/${_fechaFin!.month}/${_fechaFin!.year}'
                      : 'Seleccionar fecha',
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createPeriodo,
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Crear'),
        ),
      ],
    );
  }

  Future<void> _createPeriodo() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaInicio == null || _fechaFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes seleccionar ambas fechas'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final periodoProvider = Provider.of<PeriodoAcademicoProvider>(context, listen: false);
      final colors = Theme.of(context).colorScheme;

      final success = await periodoProvider.createPeriodoAcademico(
        authProvider.accessToken!,
        academic_service.CreatePeriodoAcademicoRequest(
          nombre: _nombreController.text.trim(),
          fechaInicio: _fechaInicio!.toIso8601String(),
          fechaFin: _fechaFin!.toIso8601String(),
        ),
      );

      if (success && mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Período académico creado correctamente')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(periodoProvider.errorMessage ?? 'Error al crear período académico'),
            backgroundColor: colors.error,
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

// Diálogo para editar período académico
class EditPeriodoDialog extends StatefulWidget {
  final PeriodoAcademico periodo;

  const EditPeriodoDialog({super.key, required this.periodo});

  @override
  State<EditPeriodoDialog> createState() => _EditPeriodoDialogState();
}

class _EditPeriodoDialogState extends State<EditPeriodoDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreController;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.periodo.nombre);
    _fechaInicio = widget.periodo.fechaInicio;
    _fechaFin = widget.periodo.fechaFin;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    return AlertDialog(
      title: Text('Editar Período Académico', style: textStyles.headlineMedium),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Período',
                hintText: 'Ej: Año 2025, Semestre 2025-I',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El nombre es requerido';
                }
                return null;
              },
            ),
            SizedBox(height: spacing.md),
            // Fecha de inicio
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _fechaInicio ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() {
                    _fechaInicio = picked;
                  });
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha de Inicio',
                ),
                child: Text(
                  _fechaInicio != null
                      ? '${_fechaInicio!.day}/${_fechaInicio!.month}/${_fechaInicio!.year}'
                      : 'Seleccionar fecha',
                ),
              ),
            ),
            SizedBox(height: spacing.md),
            // Fecha de fin
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _fechaFin ?? DateTime.now(),
                  firstDate: _fechaInicio ?? DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() {
                    _fechaFin = picked;
                  });
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha de Fin',
                ),
                child: Text(
                  _fechaFin != null
                      ? '${_fechaFin!.day}/${_fechaFin!.month}/${_fechaFin!.year}'
                      : 'Seleccionar fecha',
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updatePeriodo,
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Actualizar'),
        ),
      ],
    );
  }

  Future<void> _updatePeriodo() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaInicio == null || _fechaFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes seleccionar ambas fechas'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final periodoProvider = Provider.of<PeriodoAcademicoProvider>(context, listen: false);
      final colors = Theme.of(context).colorScheme;

      final success = await periodoProvider.updatePeriodoAcademico(
        authProvider.accessToken!,
        widget.periodo.id,
        academic_service.UpdatePeriodoAcademicoRequest(
          nombre: _nombreController.text.trim(),
          fechaInicio: _fechaInicio!.toIso8601String(),
          fechaFin: _fechaFin!.toIso8601String(),
        ),
      );

      if (success && mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Período académico actualizado correctamente')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(periodoProvider.errorMessage ?? 'Error al actualizar período académico'),
            backgroundColor: colors.error,
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