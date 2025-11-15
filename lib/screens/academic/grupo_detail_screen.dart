import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/grupo.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/grupo_provider.dart';
import '../../theme/theme_extensions.dart';
import '../../widgets/components/index.dart';

class GrupoDetailScreen extends StatefulWidget {
  final Grupo grupo;

  const GrupoDetailScreen({
    super.key,
    required this.grupo,
  });

  @override
  State<GrupoDetailScreen> createState() => _GrupoDetailScreenState();
}

class _GrupoDetailScreenState extends State<GrupoDetailScreen> {
  bool _isLoading = false;
  List<User> _estudiantesAsignados = [];
  List<User> _estudiantesDisponibles = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEstudiantes();
    });
  }

  Future<void> _loadEstudiantes() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final grupoProvider = Provider.of<GrupoProvider>(context, listen: false);

      final token = authProvider.accessToken;
      if (token == null) return;

      // Cargar estudiantes asignados al grupo
      await grupoProvider.loadEstudiantesByGrupo(token, widget.grupo.id);
      _estudiantesAsignados = grupoProvider.estudiantesByGrupo;

      // Cargar estudiantes sin asignar
      await grupoProvider.loadEstudiantesSinAsignar(token);
      _estudiantesDisponibles = grupoProvider.estudiantesSinAsignar;

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar estudiantes: $e'),
            backgroundColor: context.colors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _asignarEstudiante(User estudiante) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final grupoProvider = Provider.of<GrupoProvider>(context, listen: false);

      final token = authProvider.accessToken;
      if (token == null) return;

      final success = await grupoProvider.asignarEstudianteAGrupo(
        token,
        widget.grupo.id,
        estudiante.id,
      );

      if (success && mounted) {
        setState(() {
          _estudiantesAsignados.add(estudiante);
          _estudiantesDisponibles.removeWhere((e) => e.id == estudiante.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${estudiante.nombreCompleto} asignado al grupo'),
            backgroundColor: context.colors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al asignar estudiante: $e'),
            backgroundColor: context.colors.error,
          ),
        );
      }
    }
  }

  Future<void> _desasignarEstudiante(User estudiante) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final grupoProvider = Provider.of<GrupoProvider>(context, listen: false);

      final token = authProvider.accessToken;
      if (token == null) return;

      final success = await grupoProvider.desasignarEstudianteDeGrupo(
        token,
        widget.grupo.id,
        estudiante.id,
      );

      if (success && mounted) {
        setState(() {
          _estudiantesDisponibles.add(estudiante);
          _estudiantesAsignados.removeWhere((e) => e.id == estudiante.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${estudiante.nombreCompleto} removido del grupo'),
            backgroundColor: context.colors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al remover estudiante: $e'),
            backgroundColor: context.colors.error,
          ),
        );
      }
    }
  }

  void _showAsignarEstudianteDialog() {
    showDialog(
      context: context,
      builder: (context) => AsignarEstudianteDialog(
        estudiantesDisponibles: _estudiantesDisponibles,
        onAsignar: (estudiantes) {
          for (final estudiante in estudiantes) {
            _asignarEstudiante(estudiante);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final textStyles = context.textStyles;

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles del Grupo'),
        backgroundColor: colors.primary,
        foregroundColor: colors.getTextColorForBackground(colors.primary),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: EdgeInsets.all(spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información del grupo
                ClarityCard(
                  title: Text(
                    'Información del Grupo',
                    style: textStyles.titleMedium.bold,
                  ),
                  leading: Icon(
                    Icons.group,
                    color: colors.primary,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.grupo.nombre,
                        style: textStyles.headlineMedium.bold,
                      ),
                      SizedBox(height: spacing.sm),
                      Text(
                        'Estudiantes: ${_estudiantesAsignados.length}',
                        style: textStyles.bodyMedium,
                      ),
                      Text(
                        'Horarios: ${widget.grupo.horariosCount}',
                        style: textStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: spacing.xl),

                // Estudiantes asignados
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Estudiantes Asignados',
                      style: textStyles.headlineMedium.bold,
                    ),
                    ElevatedButton.icon(
                      onPressed: _showAsignarEstudianteDialog,
                      icon: Icon(Icons.add),
                      label: Text('Asignar Estudiante'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: spacing.lg),

                _estudiantesAsignados.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(spacing.xl),
                        child: Column(
                          children: [
                            Icon(
                              Icons.group_off,
                              size: 64,
                              color: colors.textSecondary,
                            ),
                            SizedBox(height: spacing.md),
                            Text(
                              'No hay estudiantes asignados',
                              style: textStyles.bodyLarge.withColor(colors.textSecondary),
                            ),
                            SizedBox(height: spacing.md),
                            Text(
                              'Asigna estudiantes para que puedan registrar asistencia',
                              style: textStyles.bodyMedium.withColor(colors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _estudiantesAsignados.length,
                      itemBuilder: (context, index) {
                        final estudiante = _estudiantesAsignados[index];
                        return Card(
                          margin: EdgeInsets.only(bottom: spacing.sm),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: colors.primary,
                              child: Text(
                                estudiante.inicial,
                                style: textStyles.button.withColor(colors.onPrimary),
                              ),
                            ),
                            title: Text(estudiante.nombreCompleto),
                            subtitle: Text(estudiante.email),
                            trailing: IconButton(
                              icon: Icon(Icons.remove_circle, color: colors.error),
                              onPressed: () => _desasignarEstudiante(estudiante),
                              tooltip: 'Remover del grupo',
                            ),
                          ),
                        );
                      },
                    ),
              ],
            ),
          ),
    );
  }
}

class AsignarEstudianteDialog extends StatefulWidget {
  final List<User> estudiantesDisponibles;
  final Function(List<User>) onAsignar;

  const AsignarEstudianteDialog({
    super.key,
    required this.estudiantesDisponibles,
    required this.onAsignar,
  });

  @override
  State<AsignarEstudianteDialog> createState() => _AsignarEstudianteDialogState();
}

class _AsignarEstudianteDialogState extends State<AsignarEstudianteDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<User> _filteredEstudiantes = [];
  // ignore: prefer_final_fields - Este campo se modifica en _toggleSeleccion
  Set<String> _selectedEstudiantes = {};

  @override
  void initState() {
    super.initState();
    _filteredEstudiantes = widget.estudiantesDisponibles;
    _searchController.addListener(_filterEstudiantes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterEstudiantes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredEstudiantes = widget.estudiantesDisponibles.where((estudiante) {
        return estudiante.nombreCompleto.toLowerCase().contains(query) ||
               estudiante.email.toLowerCase().contains(query) ||
               (estudiante.nombres.isNotEmpty && estudiante.nombres.toLowerCase().contains(query)) ||
               estudiante.apellidos.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _toggleSeleccion(String estudianteId) {
    setState(() {
      if (_selectedEstudiantes.contains(estudianteId)) {
        _selectedEstudiantes.remove(estudianteId);
      } else {
        _selectedEstudiantes.add(estudianteId);
      }
    });
  }

  void _asignarSeleccionados() {
    final estudiantesSeleccionados = widget.estudiantesDisponibles
        .where((estudiante) => _selectedEstudiantes.contains(estudiante.id))
        .toList();

    if (estudiantesSeleccionados.isNotEmpty) {
      widget.onAsignar(estudiantesSeleccionados);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    return AlertDialog(
      title: Text('Asignar Estudiantes', style: textStyles.headlineMedium),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            // Campo de búsqueda
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar estudiantes...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(spacing.borderRadius),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: spacing.md,
                  vertical: spacing.sm,
                ),
              ),
            ),
            SizedBox(height: spacing.md),

            // Contador de seleccionados
            if (_selectedEstudiantes.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(horizontal: spacing.sm, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(spacing.borderRadius / 2),
                ),
                child: Text(
                  '${_selectedEstudiantes.length} estudiante${_selectedEstudiantes.length != 1 ? 's' : ''} seleccionado${_selectedEstudiantes.length != 1 ? 's' : ''}',
                  style: textStyles.labelSmall.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            SizedBox(height: spacing.md),

            // Lista de estudiantes
            Expanded(
              child: _filteredEstudiantes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_search,
                          size: 48,
                          color: colors.textMuted,
                        ),
                        SizedBox(height: spacing.md),
                        Text(
                          _searchController.text.isEmpty
                            ? 'No hay estudiantes disponibles'
                            : 'No se encontraron estudiantes',
                          style: textStyles.bodyMedium.copyWith(color: colors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredEstudiantes.length,
                    itemBuilder: (context, index) {
                      final estudiante = _filteredEstudiantes[index];
                      final isSelected = _selectedEstudiantes.contains(estudiante.id);

                      return Card(
                        margin: EdgeInsets.only(bottom: spacing.xs),
                        color: isSelected ? colors.primary.withValues(alpha: 0.05) : null,
                        child: InkWell(
                          onTap: () => _toggleSeleccion(estudiante.id),
                          child: Padding(
                            padding: EdgeInsets.all(spacing.sm),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: isSelected,
                                  onChanged: (value) => _toggleSeleccion(estudiante.id),
                                  activeColor: colors.primary,
                                ),
                                SizedBox(width: spacing.sm),
                                CircleAvatar(
                                  backgroundColor: colors.primary,
                                  radius: 20,
                                  child: Text(
                                    estudiante.inicial,
                                    style: textStyles.button.copyWith(color: colors.onPrimary),
                                  ),
                                ),
                                SizedBox(width: spacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        estudiante.nombreCompleto,
                                        style: textStyles.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: colors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        estudiante.email,
                                        style: textStyles.bodySmall.copyWith(
                                          color: colors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _selectedEstudiantes.isEmpty ? null : _asignarSeleccionados,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
          ),
          child: Text('Asignar (${_selectedEstudiantes.length})'),
        ),
      ],
    );
  }
}