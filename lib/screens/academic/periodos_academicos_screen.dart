import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/grupo.dart'; // Para PeriodoAcademico
import '../../providers/auth_provider.dart';
import '../../providers/periodo_academico_provider.dart';
import '../../services/academic/periodo_service.dart';
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
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPeriodos());
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
    _loadPeriodos(search: query.isEmpty ? null : query);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 180) {
      _loadMorePeriodos();
    }
  }

  Future<void> _loadPeriodos({String? search}) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final periodoProvider = Provider.of<PeriodoAcademicoProvider>(context, listen: false);
    final token = authProvider.accessToken;
    if (token != null) {
      await periodoProvider.loadPeriodosAcademicos(token);
    }
  }

  Future<void> _loadMorePeriodos() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final periodoProvider = Provider.of<PeriodoAcademicoProvider>(context, listen: false);
    final token2 = authProvider.accessToken;
    if (token2 != null && (periodoProvider.paginationInfo?.hasNext ?? false)) {
      await periodoProvider.loadNextPage(token2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, PeriodoAcademicoProvider>(
      builder: (context, authProvider, periodoProvider, child) {
        return ClarityManagementPage(
          title: 'Períodos Académicos',
          backRoute: '/academic',
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
          isLoadingMore: periodoProvider.isLoading && (periodoProvider.paginationInfo?.hasNext ?? false),
          emptyStateWidget: ClarityEmptyState(
            icon: _isSearching ? Icons.search_off : Icons.calendar_today,
            title: _isSearching ? 'No se encontraron resultados' : 'Aún no has creado ningún período académico',
            subtitle: _isSearching ? 'Intenta con otros términos de búsqueda' : 'Comienza creando tu primer período académico',
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
        onChanged: (_) => _onSearchChanged(),
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

    return ClarityListItem(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.calendar_today, color: colors.primary),
      ),
      title: periodo.nombre,
      subtitleWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Del ${periodo.fechaInicio.day}/${periodo.fechaInicio.month}/${periodo.fechaInicio.year} al ${periodo.fechaFin.day}/${periodo.fechaFin.month}/${periodo.fechaFin.year}',
            style: textStyles.bodySmall.copyWith(color: colors.textSecondary),
          ),
          SizedBox(height: spacing.xs),
          Text(
            '${0} grupos asociados',
            style: textStyles.bodySmall.copyWith(color: colors.textMuted),
          ),
        ],
      ),
      badgeText: periodo.activo ? 'Activo' : 'Inactivo',
      badgeColor: periodo.activo ? colors.success : colors.error,
      contextActions: [
        ClarityContextMenuAction(
          label: periodo.activo ? 'Desactivar' : 'Activar',
          icon: periodo.activo ? Icons.visibility_off : Icons.visibility,
          color: periodo.activo ? colors.error : colors.success,
          onPressed: () => _togglePeriodoStatus(context, periodo, provider),
        ),
        ClarityContextMenuAction(
          label: 'Editar',
          icon: Icons.edit,
          color: colors.primary,
          onPressed: () => _showEditPeriodoDialog(context, periodo),
        ),
        ClarityContextMenuAction(
          label: 'Eliminar',
          icon: Icons.delete,
          color: colors.error,
          onPressed: () => _showDeletePeriodoDialog(context, periodo, provider),
        ),
      ],
      onTap: () => Navigator.of(context).pushNamed('/academic/periodos/${periodo.id}'),
    );
  }

  Future<void> _togglePeriodoStatus(BuildContext context, PeriodoAcademico periodo, PeriodoAcademicoProvider provider) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final colors = Theme.of(context).colorScheme;
  final messenger = ScaffoldMessenger.of(context);

  final tokenLocal = authProvider.accessToken;
  if (tokenLocal == null) {
    messenger.showSnackBar(const SnackBar(content: Text('Debes iniciar sesión para cambiar el estado de un período')));
    return;
  }

  final success = await provider.togglePeriodoStatus(tokenLocal, periodo.id);

    if (!mounted) return;

    if (success) {
  messenger.showSnackBar(
        SnackBar(
          content: Text('Período ${periodo.activo ? 'desactivado' : 'activado'} correctamente'),
        ),
      );
    } else {
  messenger.showSnackBar(
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
      if (result == true) _loadPeriodos();
    });
  }

  void _showEditPeriodoDialog(BuildContext context, PeriodoAcademico periodo) {
    showDialog(
      context: context,
      builder: (context) => EditPeriodoDialog(periodo: periodo),
    ).then((result) {
      if (result == true) _loadPeriodos();
    });
  }

  void _showDeletePeriodoDialog(BuildContext context, PeriodoAcademico periodo, PeriodoAcademicoProvider provider) {
    final colors = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Período Académico'),
        content: Text(
          '¿Estás seguro de que quieres eliminar el período "${periodo.nombre}"? Esta acción no se puede deshacer y eliminará todos los grupos asociados.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final messenger = ScaffoldMessenger.of(context);
              final tokenDelete = authProvider.accessToken;
              if (tokenDelete == null) {
                messenger.showSnackBar(const SnackBar(content: Text('Debes iniciar sesión para eliminar un período')));
                return;
              }

              final success = await provider.deletePeriodoAcademico(tokenDelete, periodo.id);
              if (!mounted) return;
              if (success) {
                messenger.showSnackBar(const SnackBar(content: Text('Período académico eliminado correctamente')));
                _loadPeriodos();
              } else {
                messenger.showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Error al eliminar período académico'), backgroundColor: colors.error));
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

// (Lógica del widget continúa aquí)

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

  // _isLoading not needed: ClarityFormDialog shows its own progress when saving

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyles = context.textStyles;
    final spacing = context.spacing;
    return ClarityFormDialog(
      title: Text('Crear Período Académico', style: textStyles.headlineMedium),
      formKey: _formKey,
      onSave: _createPeriodo,
      saveLabel: 'Crear',
      cancelLabel: 'Cancelar',
      children: [
        TextFormField(
          controller: _nombreController,
          decoration: const InputDecoration(
            labelText: 'Nombre del Período',
            hintText: 'Ej: Año 2025, Semestre 2025-I',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'El nombre es requerido';
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
            if (picked != null) setState(() => _fechaInicio = picked);
          },
          child: InputDecorator(
            decoration: const InputDecoration(labelText: 'Fecha de Inicio'),
            child: Text(_fechaInicio != null ? '${_fechaInicio!.day}/${_fechaInicio!.month}/${_fechaInicio!.year}' : 'Seleccionar fecha'),
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
            if (picked != null) setState(() => _fechaFin = picked);
          },
          child: InputDecorator(
            decoration: const InputDecoration(labelText: 'Fecha de Fin'),
            child: Text(_fechaFin != null ? '${_fechaFin!.day}/${_fechaFin!.month}/${_fechaFin!.year}' : 'Seleccionar fecha'),
          ),
        ),
      ],
    );
  }

  Future<bool> _createPeriodo() async {
    if (!_formKey.currentState!.validate()) return false;
    if (_fechaInicio == null || _fechaFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes seleccionar ambas fechas'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

  // dialog handles progress UI

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final periodoProvider = Provider.of<PeriodoAcademicoProvider>(context, listen: false);
      final colors = Theme.of(context).colorScheme;

      final token = authProvider.accessToken;
      if (token == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes iniciar sesión para crear períodos')));
        return false;
      }

      final success = await periodoProvider.createPeriodoAcademico(
        token,
        CreatePeriodoAcademicoRequest(
          nombre: _nombreController.text.trim(),
          fechaInicio: _fechaInicio!.toIso8601String(),
          fechaFin: _fechaFin!.toIso8601String(),
        ),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Período académico creado correctamente')),
        );
        return true;
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
      return false;
    } finally {}
    return false;
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

  // no local loading flag required now - ClarityFormDialog handles saving state

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

    return ClarityFormDialog(
      title: Text('Editar Período Académico', style: textStyles.headlineMedium),
      formKey: _formKey,
      onSave: _updatePeriodo,
      saveLabel: 'Actualizar',
      cancelLabel: 'Cancelar',
      children: [
        TextFormField(
          controller: _nombreController,
          decoration: const InputDecoration(
            labelText: 'Nombre del Período',
            hintText: 'Ej: Año 2025, Semestre 2025-I',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'El nombre es requerido';
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
            if (picked != null) setState(() => _fechaInicio = picked);
          },
          child: InputDecorator(
            decoration: const InputDecoration(labelText: 'Fecha de Inicio'),
            child: Text(_fechaInicio != null ? '${_fechaInicio!.day}/${_fechaInicio!.month}/${_fechaInicio!.year}' : 'Seleccionar fecha'),
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
            if (picked != null) setState(() => _fechaFin = picked);
          },
          child: InputDecorator(
            decoration: const InputDecoration(labelText: 'Fecha de Fin'),
            child: Text(_fechaFin != null ? '${_fechaFin!.day}/${_fechaFin!.month}/${_fechaFin!.year}' : 'Seleccionar fecha'),
          ),
        ),
      ],
    );
  }

  Future<bool> _updatePeriodo() async {
    if (!_formKey.currentState!.validate()) return false;
    if (_fechaInicio == null || _fechaFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes seleccionar ambas fechas'),
          backgroundColor: Colors.orange,
        ),
      );
          return false;
    }

  // progress is handled by ClarityFormDialog

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final periodoProvider = Provider.of<PeriodoAcademicoProvider>(context, listen: false);
      final colors = Theme.of(context).colorScheme;

      final token = authProvider.accessToken;
      if (token == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes iniciar sesión para actualizar períodos')));
        return false;
      }

      final success = await periodoProvider.updatePeriodoAcademico(
        token,
        widget.periodo.id,
        UpdatePeriodoAcademicoRequest(
          nombre: _nombreController.text.trim(),
          fechaInicio: _fechaInicio!.toIso8601String(),
          fechaFin: _fechaFin!.toIso8601String(),
        ),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Período académico actualizado correctamente')),
        );
        return true;
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
    } finally {}
    return false;
  }
}