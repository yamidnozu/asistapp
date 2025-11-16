// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/components/index.dart';
import '../../theme/theme_extensions.dart';
import '../../models/grupo.dart';
import '../../models/materia.dart';
import '../../models/user.dart';
import '../../providers/grupo_paginated_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/periodo_academico_provider.dart';
import '../../providers/horario_provider.dart';
import '../../models/horario.dart';
import '../../models/conflict_error.dart';
import '../../providers/materia_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/academic_service.dart' as academic_service;

class HorariosScreen extends StatefulWidget {
  const HorariosScreen({super.key});

  @override
  State<HorariosScreen> createState() => _HorariosScreenState();
}

class _HorariosScreenState extends State<HorariosScreen> {
  Grupo? _selectedGrupo;
  PeriodoAcademico? _selectedPeriodo;

  final List<String> _horas = [
    '07:00', '08:00', '09:00', '10:00', '11:00', '12:00',
    '13:00', '14:00', '15:00', '16:00', '17:00', '18:00',
  ];

  final List<String> _diasSemana = ['Lunes','Martes','Miércoles','Jueves','Viernes','Sábado','Domingo'];
  final List<int> _diasSemanaValues = [1,2,3,4,5,6,7];

  @override
  void initState() {
    super.initState();
    // Carga inicial: periodos, grupos, materias y profesores
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final periodoProvider = Provider.of<PeriodoAcademicoProvider>(context, listen: false);
  final grupoProvider = Provider.of<GrupoPaginatedProvider>(context, listen: false);
    final materiaProvider = Provider.of<MateriaProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final token = authProvider.accessToken;
    final institutionId = authProvider.selectedInstitutionId;

    if (token != null) {
      try {
        // Cargar sólo los periodos activos para evitar mostrar periodos innecesarios
        await periodoProvider.loadPeriodosActivos(token);

        // Si hay periodos activos, seleccionar el primero por defecto
        if (periodoProvider.periodosActivos.isNotEmpty) {
          // Seleccionamos el primer periodo activo por defecto
          setState(() => _selectedPeriodo = periodoProvider.periodosActivos.first);
          await grupoProvider.loadItems(token, filters: {'periodoId': _selectedPeriodo!.id});
          // Si hay grupos en este periodo, seleccionamos el primero y cargamos sus horarios
            if (grupoProvider.items.isNotEmpty) {
            setState(() => _selectedGrupo = grupoProvider.items.first);
            await _loadHorariosForGrupo(_selectedGrupo!.id);
          }
        } else {
          // Si no hay periodos activos, cargar todos los grupos sin filtro
          await grupoProvider.loadItems(token);
        }

        // Cargar materias y profesores (para el diálogo de creación/edición)
        await materiaProvider.loadMaterias(token);
        if (institutionId != null) {
          await userProvider.loadUsersByInstitution(token, institutionId);
        }
  } catch (e) {
        if (mounted) {
          final colors = context.colors;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error cargando datos iniciales: $e'), backgroundColor: colors.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
  return Consumer3<PeriodoAcademicoProvider, GrupoPaginatedProvider, HorarioProvider>(
      builder: (context, periodoProvider, grupoProvider, horarioProvider, child) {
        return ClarityManagementPage(
          title: 'Horarios',
          isLoading: horarioProvider.isLoading,
          hasError: horarioProvider.hasError,
          errorMessage: horarioProvider.errorMessage,
          // Solo mostrar calendario cuando se haya seleccionado un grupo
          itemCount: _selectedGrupo != null ? 1 : 0,
          itemBuilder: (context, index) => _buildWeeklyCalendar(horarioProvider),
          filterWidgets: _buildFilterWidgets(context, grupoProvider),
          onRefresh: () async {
            if (_selectedGrupo != null) _loadHorariosForGrupo(_selectedGrupo!.id);
          },
          scrollController: null,
          emptyStateWidget: ClarityEmptyState(
            icon: Icons.calendar_month,
            title: _selectedGrupo == null ? 'Selecciona un grupo' : 'No hay clases en el grupo',
            subtitle: _selectedGrupo == null ? 'Selecciona un grupo para ver el calendario semanal' : 'Crea la primera clase para este grupo',
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              if (_selectedGrupo == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona un grupo para crear una clase')));
                return;
              }
              // Mostrar un diálogo para crear la clase en la primera hora disponible del día
              final primeraHora = _horas.isNotEmpty ? _horas.first : '07:00';
              _showCreateClassDialog(primeraHora, 1);
            },
            tooltip: 'Crear Clase',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildWeeklyCalendar(HorarioProvider horarioProvider) {
    final colors = context.colors;
    final textStyles = context.textStyles;
  final spacing = context.spacing;
  // spacing preserved for consistency with other pages; used inside dropdown inputs

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final hourColumnWidth = isMobile ? 60.0 : 80.0;
        final cellHeight = isMobile ? 70.0 : 80.0;

        return SingleChildScrollView(
          child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(spacing.borderRadius),
            border: Border.all(color: colors.borderLight),
          ),
          child: Column(
            children: [
              // Header con días de la semana
              Row(
                children: [
                  // Columna de horas (vacía en header) --- ahora con la misma altura que las celdas
                  SizedBox(width: hourColumnWidth, height: cellHeight),
                  // Días de la semana
                  ..._diasSemana.map((dia) => Expanded(
                    child: Container(
                      // El header usa la misma altura que una fila para alinear perfectamente
                      height: cellHeight,
                      padding: EdgeInsets.symmetric(
                        vertical: spacing.sm,
                        horizontal: spacing.xs,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(color: colors.borderLight),
                        ),
                      ),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                          dia,
                          style: textStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.primary,
                          ),
                          textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  )),
                ],
              ),
              Divider(height: 0),
              // Filas de horas con altura fija
              ..._horas.map((hora) => _buildHourRow(
                hora,
                horarioProvider,
                hourColumnWidth: hourColumnWidth,
                cellHeight: cellHeight,
                isMobile: isMobile,
              )),
            ],
          ),
        ),
      );
      },
    );
  }

  List<Widget> _buildFilterWidgets(BuildContext context, GrupoPaginatedProvider grupoProvider) {
  final spacing = context.spacing;

    return [
      // Use a responsive Wrap so filters adapt to different screen sizes and
      // avoid horizontal overflow on mobile (they will wrap to the next line).
      LayoutBuilder(
        builder: (context, constraints) {
          // Use multiple columns on wider screens — this makes the filters
          // responsive and prevents header overflow on small devices.
          // - >= 1000px: 3 columns
          // - >= 700px: 2 columns
          // - else: 1 column
          final width = constraints.maxWidth;
          
          // Breakpoints adjusted to common grid values:
          // - >= 1024px: 3 columns
          // - >= 600px: 2 columns
          // - else: 1 column
          final columns = width >= 1024 ? 3 : (width >= 600 ? 2 : 1);
          final double itemWidth = (width - ((columns - 1) * 12)) / columns;

          return Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.start,
            children: [
              SizedBox(
                width: itemWidth,
                child: Consumer<PeriodoAcademicoProvider>(
                  builder: (context, periodoProvider, child) {
                    return DropdownButtonFormField<PeriodoAcademico>(
                      isExpanded: true,
                      value: _selectedPeriodo,
                      decoration: InputDecoration(
                        labelText: 'Período Académico',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: spacing.md, vertical: spacing.sm),
                      ),
                      style: context.textStyles.bodyLarge,
                      items: periodoProvider.periodosActivos
                      .map<DropdownMenuItem<PeriodoAcademico>>((p) => DropdownMenuItem<PeriodoAcademico>(value: p, child: Text(p.nombre, overflow: TextOverflow.ellipsis, maxLines: 1)))
                      .toList(),
                  onChanged: (p) async {
                    setState(() {
                      _selectedPeriodo = p;
                      _selectedGrupo = null;
                    });
                    if (p != null) {
                      final token = Provider.of<AuthProvider>(context, listen: false).accessToken;
                      if (token != null) {
                        await grupoProvider.loadItems(token, filters: {'periodoId': p.id});
                        // Seleccionar primer grupo si existe y cargar horarios
                        if (grupoProvider.items.isNotEmpty) {
                          setState(() => _selectedGrupo = grupoProvider.items.first);
                          await _loadHorariosForGrupo(_selectedGrupo!.id);
                        }
                      }
                    }
                  },
                );
              },
                ),
              ),

              SizedBox(
                width: itemWidth,
                child: DropdownButtonFormField<Grupo>(
                  isExpanded: true,
              value: _selectedGrupo,
              decoration: InputDecoration(labelText: 'Grupo'),
              items: (_selectedPeriodo == null
                  ? <DropdownMenuItem<Grupo>>[]
                  : grupoProvider.items
                      .where((g) => g.periodoId == _selectedPeriodo!.id)
                      .map<DropdownMenuItem<Grupo>>((g) => DropdownMenuItem<Grupo>(value: g, child: Text('${g.nombre} - ${g.grado}', overflow: TextOverflow.ellipsis, maxLines: 1)))
                      .toList()),
              onChanged: (_selectedPeriodo == null)
                  ? null
                  : (g) => setState(() {
                        _selectedGrupo = g;
                        if (g != null) _loadHorariosForGrupo(g.id);
                      }),
                ),
              ),
            ],
          );
        },
      ),
    ];
  }

  Widget _buildHourRow(
    String hora,
    HorarioProvider horarioProvider, {
    required double hourColumnWidth,
    required double cellHeight,
    required bool isMobile,
  }) {
    final colors = context.colors;
    final textStyles = context.textStyles;
  // Use spacing in header, not needed here

    return SizedBox(
      height: cellHeight, // Altura fija para alineación perfecta
      child: Row(
        children: [
          // Columna de hora
        Container(
            width: hourColumnWidth,
            height: cellHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: colors.borderLight),
                right: BorderSide(color: colors.borderLight),
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                hora,
                style: textStyles.bodySmall.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

              // Celdas de días
          ...List.generate(_diasSemana.length, (index) {
            final diaSemana = _diasSemanaValues[index];
            return Expanded(
              child: _buildScheduleCell(
                hora,
                diaSemana,
                horarioProvider,
                cellHeight: cellHeight,
                isMobile: isMobile,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildScheduleCell(
    String hora,
    int diaSemana,
    HorarioProvider horarioProvider, {
    required double cellHeight,
    required bool isMobile,
  }) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    // 🔧 IMPORTANTE: Usar SOLO horarios del grupo seleccionado para renderizar la grilla
    // (Mientras que _horarios completo se usa para detectar conflictos globales)
    final horarios = horarioProvider.horariosDelGrupoSeleccionado;

    // Verificar si esta celda está ocupada por una clase multi-hora que comenzó antes
    final celdaOcupada = _estaCeldaOcupada(hora, diaSemana, horarios);
    if (celdaOcupada) {
      // La celda está ocupada por una clase que comenzó en una hora anterior
      return Container(
        height: cellHeight,
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: colors.borderLight),
            top: BorderSide(color: colors.borderLight),
          ),
          color: colors.surface.withValues(alpha: 0.3), // Color sutil para indicar ocupación
        ),
      );
    }

    // Buscar si existe un horario que comience en esta celda
    final horarioExistente = horarios.where(
      (horario) => horario.diaSemana == diaSemana && horario.horaInicio == hora,
    ).cast<Horario?>().firstOrNull;

    if (horarioExistente != null) {
      // Calcular duración en horas para determinar cuántas celdas ocupar
      final duracionHoras = _calcularDuracionEnHoras(horarioExistente.horaInicio, horarioExistente.horaFin);
      final alturaTotal = cellHeight * duracionHoras;

      // Mostrar la clase existente ocupando múltiples celdas
      return InkWell(
        onTap: () => _showEditClassDialog(horarioExistente),
        child: Container(
          height: alturaTotal,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: colors.borderLight),
              top: BorderSide(color: colors.borderLight),
            ),
            color: _getMateriaColor(horarioExistente.materia.nombre),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? spacing.xs : spacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  horarioExistente.materia.nombre,
                  style: textStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.white,
                    fontSize: isMobile ? 11 : 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (horarioExistente.profesor != null) ...[
                  SizedBox(height: isMobile ? spacing.xs : spacing.sm),
                  Text(
                    '${horarioExistente.profesor!.nombres.split(' ').first} ${horarioExistente.profesor!.apellidos.split(' ').first}',
                    style: textStyles.bodySmall.copyWith(
                      color: colors.white.withValues(alpha: 0.9),
                      fontSize: isMobile ? 9 : 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                SizedBox(height: isMobile ? spacing.xs : spacing.sm),
                Text(
                  '${horarioExistente.horaInicio} - ${horarioExistente.horaFin}',
                  style: textStyles.bodySmall.copyWith(
                    color: colors.white.withValues(alpha: 0.8),
                    fontSize: isMobile ? 8 : 9,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Celda vacía clickeable para crear nueva clase
    return InkWell(
      onTap: () => _showCreateClassDialog(hora, diaSemana),
      child: Container(
        height: cellHeight,
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: colors.borderLight),
            top: BorderSide(color: colors.borderLight),
          ),
        ),
        child: Center(
          child: Icon(
            Icons.add,
            size: isMobile ? 16 : 20,
            color: colors.primary.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  /// Calcula la duración en horas entre dos tiempos (HH:MM)
  double _calcularDuracionEnHoras(String horaInicio, String horaFin) {
    final inicioInt = _horaToInt(horaInicio);
    final finInt = _horaToInt(horaFin);
    return (finInt - inicioInt) / 60.0;
  }
  bool _estaCeldaOcupada(String hora, int diaSemana, List<Horario> horarios) {
    // Verificar si alguna clase que comenzó antes se extiende hasta esta hora
    for (final horario in horarios) {
      if (horario.diaSemana == diaSemana) {
        // Si la clase comienza en esta hora, no está ocupada (se mostrará aquí)
        if (horario.horaInicio == hora) continue;

        // Verificar si esta clase se extiende hasta la hora actual
        final horaInicioInt = _horaToInt(horario.horaInicio);
        final horaFinInt = _horaToInt(horario.horaFin);
        final horaActualInt = _horaToInt(hora);

        // La celda está ocupada si la clase comenzó antes y termina después de la hora actual
        if (horaInicioInt < horaActualInt && horaFinInt > horaActualInt) {
          return true;
        }
      }
    }
    return false;
  }

  int _horaToInt(String hora) {
    // Convertir "HH:MM" a minutos desde medianoche
    final parts = hora.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    return hours * 60 + minutes;
  }

  Future<void> _loadHorariosForGrupo(String grupoId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final horarioProvider = Provider.of<HorarioProvider>(context, listen: false);
    final colors = context.colors;

    final token = authProvider.accessToken;
    if (token != null) {
      try {
        // ✅ Cargar AMBOS: horarios del grupo Y todos los del período (para detectar conflictos)
        // Sin que se sobrescriban entre sí
        if (_selectedPeriodo != null) {
          await horarioProvider.loadHorariosForGrupoWithConflictDetection(
            token,
            grupoId,
            _selectedPeriodo!.id,
          );
        } else {
          // Si no hay período seleccionado, al menos cargar el grupo
          await horarioProvider.loadHorariosByGrupo(token, grupoId);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error cargando horarios: $e'),
              backgroundColor: colors.error,
            ),
          );
        }
      }
    }
  }

  Color _getMateriaColor(String materiaNombre) {
    // Generar colores consistentes basados en el nombre de la materia
    final colors = context.colors;
    final hash = materiaNombre.hashCode;
    final index = hash % 5;

    switch (index) {
      case 0:
        return colors.primary;
      case 1:
        return colors.secondary;
      case 2:
        return Colors.green;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.purple;
      default:
        return colors.primary;
    }
  }

  Future<void> _showEditClassDialog(Horario horario) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditClassDialog(horario: horario),
    );

    if (result == true && _selectedGrupo != null) {
      // Recargar horarios después de editar/eliminar una clase
      _loadHorariosForGrupo(_selectedGrupo!.id);
    }
  }

  Future<void> _showCreateClassDialog(String hora, int diaSemana) async {
    if (_selectedGrupo == null) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CreateClassDialog(
        grupo: _selectedGrupo!,
        horaInicio: hora,
        diaSemana: diaSemana,
      ),
    );

    if (result == true && _selectedGrupo != null) {
      // Recargar horarios después de crear una clase
      _loadHorariosForGrupo(_selectedGrupo!.id);
    }
  }
}

// Diálogo para crear una clase
class CreateClassDialog extends StatefulWidget {
  final Grupo grupo;
  final String horaInicio;
  final int diaSemana;

  const CreateClassDialog({
    super.key,
    required this.grupo,
    required this.horaInicio,
    required this.diaSemana,
  });

  @override
  State<CreateClassDialog> createState() => _CreateClassDialogState();
}

class _CreateClassDialogState extends State<CreateClassDialog> {
  final _formKey = GlobalKey<FormState>();
  Materia? _selectedMateria;
  User? _selectedProfesor;
  String? _selectedHoraFin;

  @override
  void initState() {
    super.initState();
    // Establecer horaFin por defecto (1 hora después)
    _selectedHoraFin = _getHoraFin(widget.horaInicio);
  }

  @override
  Widget build(BuildContext context) {
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    return ClarityFormDialog(
      title: Text('Crear Clase', style: textStyles.headlineMedium),
      formKey: _formKey,
      onSave: _createClass,
      saveLabel: 'Crear Clase',
      cancelLabel: 'Cancelar',
      children: [
        // Información del horario
        Container(
          padding: EdgeInsets.all(spacing.md),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(spacing.borderRadius),
            border: Border.all(color: context.colors.borderLight),
          ),
          child: Column(
            children: [
              Text(
                'Horario: ${widget.horaInicio} - ${_selectedHoraFin ?? _getHoraFin(widget.horaInicio)}',
                style: textStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
              Text('Día: ${_getDiaNombre(widget.diaSemana)}', style: textStyles.bodyMedium),
              Text('Grupo: ${widget.grupo.nombre}', style: textStyles.bodyMedium),
            ],
          ),
        ),
                // Información del horario (ya mostrado arriba)

                SizedBox(height: spacing.lg),

                // Selector de Hora Fin
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _selectedHoraFin,
                  decoration: InputDecoration(
                    labelText: 'Hora de Fin',
                    hintText: 'Selecciona la hora de fin',
                  ),
                      items: _getHorasFinDisponibles(widget.horaInicio).map((hora) {
                    return DropdownMenuItem<String>(
                      value: hora,
                      child: Text(hora, overflow: TextOverflow.ellipsis, maxLines: 1),
                    );
                  }).toList(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'La hora de fin es requerida';
                    }
                    return null;
                  },
                  onChanged: (hora) {
                    setState(() => _selectedHoraFin = hora);
                  },
                ),

            SizedBox(height: spacing.md),

                // Selector de Materia
                Consumer<MateriaProvider>(
                  builder: (context, materiaProvider, child) {
                    return DropdownButtonFormField<Materia>(
                      isExpanded: true,
                      value: _selectedMateria,
                      decoration: InputDecoration(
                        labelText: 'Materia',
                        hintText: 'Selecciona una materia',
                      ),
                      items: materiaProvider.materias.map((materia) {
                        return DropdownMenuItem<Materia>(
                          value: materia,
                          child: Text(materia.nombre, overflow: TextOverflow.ellipsis, maxLines: 1),
                        );
                      }).toList(),
                      validator: (value) {
                        if (value == null) {
                          return 'La materia es requerida';
                        }
                        return null;
                      },
                      onChanged: (materia) {
                        setState(() => _selectedMateria = materia);
                      },
                    );
                  },
                ),

                SizedBox(height: spacing.md),

                // Selector de Profesor
                Consumer2<UserProvider, HorarioProvider>(
                  builder: (context, userProvider, horarioProvider, child) {
                    // Obtener profesores disponibles (sin conflictos)
                    final profesoresDisponibles = horarioProvider.getProfesoresDisponibles(
                      userProvider.professors,
                      widget.diaSemana,
                      widget.horaInicio,
                      _selectedHoraFin ?? _getHoraFin(widget.horaInicio),
                    );

                    // Encontrar el profesor en la lista actual (por referencia)
                    User? selectedProfesorFromList;
                    if (_selectedProfesor != null) {
                      selectedProfesorFromList = profesoresDisponibles.firstWhere(
                        (p) => p.id == _selectedProfesor!.id,
                        orElse: () => _selectedProfesor!,
                      );
                    }

                    return DropdownButtonFormField<User?>(
                      isExpanded: true,
                      value: selectedProfesorFromList,
                      decoration: InputDecoration(
                        labelText: 'Profesor (opcional)',
                        hintText: 'Selecciona un profesor',
                        helperText: profesoresDisponibles.length < userProvider.professors.length
                            ? '${profesoresDisponibles.length} disponibles'
                            : null,
                      ),
                      items: [
                        const DropdownMenuItem<User?>(
                          value: null,
                          child: Text('Sin profesor'),
                        ),
                        ...profesoresDisponibles.map((profesor) {
                          return DropdownMenuItem<User?>(
                            value: profesor,
                            child: Text('${profesor.nombres} ${profesor.apellidos}', overflow: TextOverflow.ellipsis, maxLines: 1),
                          );
                        }),
                      ],
                      onChanged: (profesor) {
                        setState(() => _selectedProfesor = profesor);
                      },
                    );
                  },
                ),
  ],
      
    );
  }

  Future<bool> _createClass() async {
  if (!_formKey.currentState!.validate()) return false;
  if (_selectedMateria == null) return false;


    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final horarioProvider = Provider.of<HorarioProvider>(context, listen: false);
    final colors = context.colors;

    try {
      final token = authProvider.accessToken;
  if (token == null) return false;

      // Obtener periodoId dinámicamente del grupo seleccionado
      final periodoId = widget.grupo.periodoId;

      final success = await horarioProvider.createHorario(
        token,
        academic_service.CreateHorarioRequest(
          periodoId: periodoId,
          grupoId: widget.grupo.id,
          materiaId: _selectedMateria!.id,
          profesorId: _selectedProfesor?.id,
          diaSemana: widget.diaSemana,
          horaInicio: widget.horaInicio,
          horaFin: _selectedHoraFin ?? _getHoraFin(widget.horaInicio),
        ),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Clase creada correctamente')),
        );
        return true;
      } else if (mounted) {
        final errorMessage = horarioProvider.errorMessage ?? 'Error al crear clase';
        
        // Verificar si es un error de conflicto usando el ConflictError del provider
        if (horarioProvider.conflictError != null) {
          _showConflictDialog(horarioProvider.conflictError!, 'crear');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: colors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: colors.error,
          ),
        );
      }
    } finally {}
    return false;
  }

  String _getHoraFin(String horaInicio) {
    // Asumir clases de 1 hora
    final parts = horaInicio.split(':');
    final hour = int.parse(parts[0]);
    final nextHour = hour + 1;
    return '${nextHour.toString().padLeft(2, '0')}:00';
  }

  String _getDiaNombre(int diaSemana) {
    const dias = {
      1: 'Lunes',
      2: 'Martes',
      3: 'Miércoles',
      4: 'Jueves',
      5: 'Viernes',
      6: 'Sábado',
      7: 'Domingo',
    };
    return dias[diaSemana] ?? 'Desconocido';
  }

  List<String> _getHorasFinDisponibles(String horaInicio) {
    // Parsear horaInicio
    final parts = horaInicio.split(':');
    final hourInicio = int.parse(parts[0]);

    // Generar horas disponibles (desde 1 hora después hasta el final del día)
    final horasDisponibles = <String>[];
    for (int hour = hourInicio + 1; hour <= 18; hour++) {
      horasDisponibles.add('${hour.toString().padLeft(2, '0')}:00');
    }

    return horasDisponibles;
  }

  void _showConflictDialog(ConflictError conflictError, String operation) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: colors.warning),
            SizedBox(width: spacing.sm),
            Text('Conflicto de Horario', style: textStyles.headlineMedium),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No se puede $operation la clase debido a un conflicto de horario.',
              style: textStyles.bodyMedium,
            ),
            SizedBox(height: spacing.md),
            Container(
              padding: EdgeInsets.all(spacing.sm),
              decoration: BoxDecoration(
                color: colors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(spacing.borderRadius),
                border: Border.all(color: colors.error.withValues(alpha: 0.3)),
              ),
              child: Text(
                conflictError.userFriendlyMessage,
                style: textStyles.bodySmall.copyWith(
                  color: colors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Mostrar IDs de horarios en conflicto si están disponibles
            if (conflictError.conflictingHorarioIds.isNotEmpty) ...[
              SizedBox(height: spacing.md),
              Text('Horarios en conflicto:', style: textStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              SizedBox(height: spacing.sm),
              ...conflictError.conflictingHorarioIds.map((id) => Text('- $id', style: textStyles.bodySmall.copyWith(color: colors.textSecondary))),
            ],
            SizedBox(height: spacing.md),
            Text(
              'Sugerencias para resolver el conflicto:',
              style: textStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: spacing.sm),
            ...conflictError.suggestions.map((suggestion) => Text(
              '• $suggestion',
              style: textStyles.bodySmall.copyWith(color: colors.textSecondary),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Revisar Horarios'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
            ),
            child: Text('Entendido'),
          ),
        ],
      ),
    );
  }
}

// Diálogo para editar una clase
class EditClassDialog extends StatefulWidget {
  final Horario horario;

  const EditClassDialog({super.key, required this.horario});

  @override
  State<EditClassDialog> createState() => _EditClassDialogState();
}

class _EditClassDialogState extends State<EditClassDialog> {
  final _formKey = GlobalKey<FormState>();
  User? _selectedProfesor;
  String? _selectedHoraFin;

  @override
  void initState() {
    super.initState();
    _selectedProfesor = widget.horario.profesor;
    _selectedHoraFin = widget.horario.horaFin;
  }

  @override
  Widget build(BuildContext context) {
    final textStyles = context.textStyles;
    final spacing = context.spacing;
    final colors = context.colors;

    return ClarityFormDialog(
      title: Text('Editar Clase', style: textStyles.headlineMedium),
      formKey: _formKey,
      onSave: _updateClass,
      saveLabel: 'Actualizar',
      cancelLabel: 'Cancelar',
      children: [
        // ClarityFormDialog already wraps children in a [Form]; avoid nesting
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
              // Información del horario (solo lectura)
              Container(
                padding: EdgeInsets.all(spacing.md),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(spacing.borderRadius),
                  border: Border.all(color: colors.borderLight),
                ),
                child: Column(
                  children: [
                    Text('Horario: ${widget.horario.horaInicio} - ${_selectedHoraFin ?? widget.horario.horaFin}', style: textStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                    Text('Día: ${widget.horario.diaSemanaNombre}', style: textStyles.bodyMedium),
                    Text('Grupo: ${widget.horario.grupo.nombre}', style: textStyles.bodyMedium),
                    Text('Materia: ${widget.horario.materia.nombre}', style: textStyles.bodyMedium),
                  ],
                ),
              ),

              SizedBox(height: spacing.lg),

              DropdownButtonFormField<String>(
                isExpanded: true,
                value: _selectedHoraFin,
                decoration: InputDecoration(labelText: 'Hora de Fin', hintText: 'Selecciona la hora de fin'),
                items: _getHorasFinDisponibles(widget.horario.horaInicio).map((hora) => DropdownMenuItem<String>(value: hora, child: Text(hora, overflow: TextOverflow.ellipsis, maxLines: 1))).toList(),
                validator: (value) => (value == null || value.isEmpty) ? 'La hora de fin es requerida' : null,
                onChanged: (hora) => setState(() => _selectedHoraFin = hora),
              ),

              SizedBox(height: spacing.md),

              Consumer<UserProvider>(
                builder: (context, userProvider, child) {
                  User? selectedProfesorFromList;
                  if (_selectedProfesor != null) {
                    selectedProfesorFromList = userProvider.professors.firstWhere((p) => p.id == _selectedProfesor!.id, orElse: () => _selectedProfesor!);
                  }

                  return DropdownButtonFormField<User?>(
                    isExpanded: true,
                    value: selectedProfesorFromList,
                    decoration: InputDecoration(labelText: 'Profesor', hintText: 'Selecciona un profesor'),
                    items: [
                      const DropdownMenuItem<User?>(value: null, child: Text('Sin profesor')),
                      ...userProvider.professors.map((profesor) => DropdownMenuItem<User?>(value: profesor, child: Text('${profesor.nombres} ${profesor.apellidos}', overflow: TextOverflow.ellipsis, maxLines: 1))),
                    ],
                    onChanged: (profesor) => setState(() => _selectedProfesor = profesor),
                  );
                },
              ),

              SizedBox(height: spacing.md),

              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final nav = Navigator.of(context);
                    final confirmed = await _showDeleteConfirmationDialog();
                    if (confirmed != true) return;
                    final success = await _deleteClass();
                    if (success) {
                      if (mounted) messenger.showSnackBar(const SnackBar(content: Text('Clase eliminada correctamente')));
                      nav.pop(true);
                    }
                  },
                  style: TextButton.styleFrom(foregroundColor: colors.error),
                  child: const Text('Eliminar'),
                ),
              ),
            ],
          ),
      ],
    );
  }

  List<String> _getHorasFinDisponibles(String horaInicio) {
    final parts = horaInicio.split(':');
    final hourInicio = int.parse(parts[0]);
    final horasDisponibles = <String>[];
    for (int hour = hourInicio + 1; hour <= 18; hour++) {
      horasDisponibles.add('${hour.toString().padLeft(2, '0')}:00');
    }
    return horasDisponibles;
  }

  Future<bool> _updateClass() async {
    if (!_formKey.currentState!.validate()) return false;
    final messenger = ScaffoldMessenger.of(context);
    final colors = context.colors;
  // progress handled by ClarityFormDialog
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final horarioProvider = Provider.of<HorarioProvider>(context, listen: false);
      final token = authProvider.accessToken;
      if (token == null) return false;

      final success = await horarioProvider.updateHorario(
        token,
        widget.horario.id,
        academic_service.UpdateHorarioRequest(
          profesorId: _selectedProfesor?.id,
          diaSemana: widget.horario.diaSemana,
          horaInicio: widget.horario.horaInicio,
          horaFin: _selectedHoraFin ?? widget.horario.horaFin,
        ),
      );

      if (success) {
        messenger.showSnackBar(SnackBar(content: Text('Clase actualizada correctamente')));
        return true;
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: colors.error));
    } finally {
    }
    return false;
  }

  Future<bool?> _showDeleteConfirmationDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar esta clase?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: Text('Eliminar')),
        ],
      ),
    );
  }

  Future<bool> _deleteClass() async {
    final confirmed = await _showDeleteConfirmationDialog();
    if (confirmed != true) return false;
    final messenger = ScaffoldMessenger.of(context);
    final colors = context.colors;
  // progress handled by ClarityFormDialog
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final horarioProvider = Provider.of<HorarioProvider>(context, listen: false);
      final token = authProvider.accessToken;
      if (token == null) return false;

      final success = await horarioProvider.deleteHorario(token, widget.horario.id);
      if (!mounted) return false;
      if (success) {
        messenger.showSnackBar(SnackBar(content: Text('Clase eliminada correctamente')));
        return true;
      } else {
        messenger.showSnackBar(SnackBar(content: Text(horarioProvider.errorMessage ?? 'Error al eliminar clase'), backgroundColor: colors.error));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: colors.error));
    } finally {
    }
    return false;
  }

  // _showConflictDialog is defined above inside dialogs (Create/Edit) and used there; duplicate removed.

}