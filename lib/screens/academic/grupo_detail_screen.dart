import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../models/grupo.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/grupo_provider.dart';
import '../../providers/estudiantes_by_grupo_paginated_provider.dart';
import '../../providers/estudiantes_sin_asignar_paginated_provider.dart';
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
  // Loading and students are handled by paginated providers

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadEstudiantes();
    });
  }

  Future<void> _loadEstudiantes() async {
    // no local loading flags: use paginated providers

    try {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final token = authProvider.accessToken;
      if (token == null) return;

    // Cargar estudiantes asignados al grupo (paginated provider)
    final byGrupo = Provider.of<EstudiantesByGrupoPaginatedProvider>(context, listen: false);
    final sinAsignar = Provider.of<EstudiantesSinAsignarPaginatedProvider>(context, listen: false);
    await byGrupo.loadEstudiantes(token, widget.grupo.id, page: 1, limit: 10);
    await sinAsignar.loadItems(token, page: 1, limit: 10);
  // providers hold the items

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
        setState(() {});
      }
    }
  }
// Providers are looked up inside methods when needed.
  Future<void> _asignarEstudiante(User estudiante) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final grupoProvider = Provider.of<GrupoProvider>(context, listen: false);
      final byGrupo = Provider.of<EstudiantesByGrupoPaginatedProvider>(context, listen: false);
      final sinAsignar = Provider.of<EstudiantesSinAsignarPaginatedProvider>(context, listen: false);
      

      final token = authProvider.accessToken;
      if (token == null) return;

      final success = await grupoProvider.asignarEstudianteAGrupo(
        token,
        widget.grupo.id,
        estudiante.id,
      );

      if (success) {
        await byGrupo.loadEstudiantes(token, widget.grupo.id, page: 1, limit: 10);
        await sinAsignar.loadItems(token, page: 1, limit: 10);
        setState(() {});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${estudiante.nombreCompleto} asignado al grupo'),
              backgroundColor: context.colors.success,
            ),
          );
        }
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
      final byGrupo = Provider.of<EstudiantesByGrupoPaginatedProvider>(context, listen: false);
      final sinAsignar = Provider.of<EstudiantesSinAsignarPaginatedProvider>(context, listen: false);
      // paginated providers used after success to refresh data

      final token = authProvider.accessToken;
      if (token == null) return;

      final success = await grupoProvider.desasignarEstudianteDeGrupo(
        token,
        widget.grupo.id,
        estudiante.id,
      );

      if (success) {
        await byGrupo.loadEstudiantes(token, widget.grupo.id, page: 1, limit: 10);
        await sinAsignar.loadItems(token, page: 1, limit: 10);
        setState(() {});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${estudiante.nombreCompleto} removido del grupo'),
              backgroundColor: context.colors.success,
            ),
          );
        }
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
        title: const Text('Detalles del Grupo'),
        backgroundColor: colors.primary,
        foregroundColor: colors.getTextColorForBackground(colors.primary),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.getTextColorForBackground(colors.primary)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/academic/grupos');
            }
          },
        ),
      ),
      body: Builder(builder: (context) {
        final byGrupo = Provider.of<EstudiantesByGrupoPaginatedProvider>(context);
        final sinAsignar = Provider.of<EstudiantesSinAsignarPaginatedProvider>(context);
        final isLoading = (byGrupo.isLoading || sinAsignar.isLoading) &&
            (byGrupo.items.isEmpty && sinAsignar.items.isEmpty);

        return isLoading
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
                        'Estudiantes: ${byGrupo.items.length}',
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
                      icon: const Icon(Icons.add),
                      label: const Text('Asignar Estudiante'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: spacing.lg),

                byGrupo.items.isEmpty
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
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: byGrupo.items.length,
                      itemBuilder: (context, index) {
                        final estudiante = byGrupo.items[index];
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
                            subtitle: Text(estudiante.email ?? ''),
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
      );
    }),
    );
  }
}

class AsignarEstudianteDialog extends StatefulWidget {
  final Function(List<User>) onAsignar;

  const AsignarEstudianteDialog({
    super.key,
    required this.onAsignar,
  });

  @override
  State<AsignarEstudianteDialog> createState() => _AsignarEstudianteDialogState();
}

class _AsignarEstudianteDialogState extends State<AsignarEstudianteDialog> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  final ScrollController _scrollController = ScrollController();
  // ignore: prefer_final_fields - Este campo se modifica en _toggleSeleccion
  Set<String> _selectedEstudiantes = {};

  @override
  void initState() {
    super.initState();
    // Inicializa el listado desde el provider en el siguiente frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.accessToken;
      final sinAsignar = Provider.of<EstudiantesSinAsignarPaginatedProvider>(context, listen: false);
      if (token != null) {
        sinAsignar.loadItems(token, page: 1, limit: 10);
      }
    });
    _searchController.addListener(_filterEstudiantes);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _filterEstudiantes() {
    final query = _searchController.text.toLowerCase();
    // Cuando hay un texto de búsqueda, delegamos al proveedor para búsqueda remota
    final sinAsignar = Provider.of<EstudiantesSinAsignarPaginatedProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.accessToken;
    // Cancel previous debounce
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (token == null) return;
      if (query.isEmpty) {
        // Reset search - load first page
        sinAsignar.loadItems(token, page: 1, limit: 10);
      } else {
        sinAsignar.loadItems(token, page: 1, limit: 10, search: query);
      }
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
    final sinAsignar = Provider.of<EstudiantesSinAsignarPaginatedProvider>(context, listen: false);
    final estudiantesSeleccionados = sinAsignar.items
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
                prefixIcon: const Icon(Icons.search),
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

            // Lista de estudiantes (usando provider para búsqueda remota y paginación)
            Expanded(
              child: Builder(builder: (context) {
                final sinAsignar = Provider.of<EstudiantesSinAsignarPaginatedProvider>(context);
                final items = sinAsignar.items;
                if (sinAsignar.isLoading && items.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                return items.isEmpty
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
                    controller: _scrollController,
                    itemCount: items.length + (sinAsignar.hasMoreData ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= items.length) {
                        // Load more placeholder
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Center(
                            child: ElevatedButton(
                              onPressed: sinAsignar.isLoadingMore || !sinAsignar.hasMoreData
                                  ? null
                                  : () {
                                      final token = Provider.of<AuthProvider>(context, listen: false).accessToken;
                                      if (token != null) sinAsignar.loadNextPage(token);
                                    },
                              child: Text(sinAsignar.isLoadingMore ? 'Cargando...' : 'Cargar más'),
                            ),
                          ),
                        );
                      }

                      final estudiante = items[index];
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
                                        estudiante.email ?? '',
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
        );
      }),
            ),
          ],
        ),
      ),
        actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
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

  void _onScroll() {
    final sinAsignar = Provider.of<EstudiantesSinAsignarPaginatedProvider>(context, listen: false);
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= (maxScroll - 100) && sinAsignar.hasMoreData && !sinAsignar.isLoadingMore) {
      final token = Provider.of<AuthProvider>(context, listen: false).accessToken;
      if (token != null) sinAsignar.loadNextPage(token);
    }
  }
}