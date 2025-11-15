// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/grupo_provider.dart';
import '../../providers/materia_provider.dart';
import '../../providers/horario_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/periodo_academico_provider.dart';
import '../../services/academic_service.dart' as academic_service;
import '../../theme/theme_extensions.dart';
import '../../models/grupo.dart';
import '../../models/materia.dart';
import '../../models/user.dart';
import '../../models/horario.dart';
import '../../models/conflict_error.dart';

class HorariosScreen extends StatefulWidget {
  const HorariosScreen({super.key});

  @override
  State<HorariosScreen> createState() => _HorariosScreenState();
}

class _HorariosScreenState extends State<HorariosScreen> {
  PeriodoAcademico? _selectedPeriodo; // <-- AÑADIR ESTA LÍNEA
  Grupo? _selectedGrupo;

  // Horas del día para la grilla
  final List<String> _horas = [
    '07:00', '08:00', '09:00', '10:00', '11:00', '12:00',
    '13:00', '14:00', '15:00', '16:00', '17:00', '18:00'
  ];

  // Días de la semana
  final List<String> _diasSemana = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'];
  final List<int> _diasSemanaValues = [1, 2, 3, 4, 5]; // Lunes=1, Domingo=7

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final grupoProvider = Provider.of<GrupoProvider>(context, listen: false);
    final materiaProvider = Provider.of<MateriaProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final periodoProvider = Provider.of<PeriodoAcademicoProvider>(context, listen: false);
    final colors = context.colors;

    final token = authProvider.accessToken;
    final institutionId = authProvider.selectedInstitutionId;

    if (token != null && institutionId != null) {
      try {
        // Cargar periodos
        await periodoProvider.loadPeriodosActivos(token);

        // Cargar grupos
        await grupoProvider.loadGrupos(token);

        // Cargar materias
        await materiaProvider.loadMaterias(token);

        // Cargar profesores (filtrar por rol 'profesor')
        await userProvider.loadUsersByInstitution(token, institutionId);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error cargando datos: $e'),
              backgroundColor: colors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.primary,
        foregroundColor: colors.white,
        elevation: 0,
        title: Text(
          'Gestión de Horarios',
          style: textStyles.headlineMedium.copyWith(color: colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(spacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AÑADIR ESTE DROPDOWN PARA SELECCIONAR EL PERÍODO
            Text(
              'Seleccionar Período Académico',
              style: textStyles.headlineSmall,
            ),
            SizedBox(height: spacing.md),
            Consumer<PeriodoAcademicoProvider>(
              builder: (context, periodoProvider, child) {
                // Lógica para cargar periodos si no están
                // ...
                return SizedBox(
                  width: double.maxFinite,
                  child: DropdownButtonFormField<PeriodoAcademico>(
                    value: _selectedPeriodo,
                    hint: const Text('Selecciona un período activo'),
                    decoration: InputDecoration(
                      labelText: 'Período Académico',
                      hintText: 'Selecciona un período',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(spacing.borderRadius),
                      ),
                    ),
                    items: periodoProvider.periodosActivos.map((periodo) {
                      return DropdownMenuItem<PeriodoAcademico>(
                        value: periodo,
                        child: Text(periodo.nombre),
                      );
                    }).toList(),
                    onChanged: (periodo) {
                      setState(() {
                        _selectedPeriodo = periodo;
                        _selectedGrupo = null; // Reinicia el grupo al cambiar de periodo
                        // Aquí podrías cargar los grupos del período seleccionado si es necesario
                      });
                    },
                  ),
                );
              },
            ),
            SizedBox(height: spacing.lg),

            // MODIFICAR EL DROPDOWN DE GRUPO
            Text(
              'Seleccionar Grupo',
              style: textStyles.headlineSmall,
            ),
            SizedBox(height: spacing.md),
            Consumer<GrupoProvider>(
              builder: (context, grupoProvider, child) {
                // Filtra los grupos para mostrar solo los del período seleccionado
                final gruposFiltrados = _selectedPeriodo == null
                    ? <Grupo>[]
                    : grupoProvider.grupos
                        .where((g) => g.periodoId == _selectedPeriodo!.id)
                        .toList();

                return SizedBox(
                  width: double.maxFinite,
                  child: DropdownButtonFormField<Grupo>(
                    value: _selectedGrupo,
                    hint: Text(_selectedPeriodo == null
                        ? 'Selecciona un período primero'
                        : 'Selecciona un grupo'),
                    decoration: InputDecoration(
                      labelText: 'Grupo',
                      hintText: 'Selecciona un grupo',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(spacing.borderRadius),
                      ),
                    ),
                    items: gruposFiltrados.map((grupo) { // <-- Usa la lista filtrada
                      return DropdownMenuItem<Grupo>(
                        value: grupo,
                        child: Text('${grupo.nombre} - ${grupo.grado}'),
                      );
                    }).toList(),
                    onChanged: _selectedPeriodo == null ? null : (grupo) {
                      setState(() => _selectedGrupo = grupo);
                      if (grupo != null) {
                        _loadHorariosForGrupo(grupo.id);
                      }
                    },
                  ),
                );
              },
            ),

            SizedBox(height: spacing.xl),

            // Vista de Calendario Semanal
            if (_selectedGrupo != null) ...[
              Text(
                'Horario Semanal - ${_selectedGrupo!.nombre}',
                style: textStyles.headlineSmall,
              ),
              SizedBox(height: spacing.md),
              Consumer<HorarioProvider>(
                builder: (context, horarioProvider, child) {
                  // Mostrar loader si está cargando
                  if (horarioProvider.isLoading) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(spacing.xl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                            ),
                            SizedBox(height: spacing.md),
                            Text(
                              'Cargando horarios...',
                              style: textStyles.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Mostrar error si existe
                  if (horarioProvider.hasError) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(spacing.xl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: colors.error,
                            ),
                            SizedBox(height: spacing.md),
                            Text(
                              'Error: ${horarioProvider.errorMessage}',
                              style: textStyles.bodyMedium.copyWith(
                                color: colors.error,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: spacing.md),
                            ElevatedButton(
                              onPressed: () {
                                if (_selectedGrupo != null) {
                                  _loadHorariosForGrupo(_selectedGrupo!.id);
                                }
                              },
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Si no hay horarios después de cargar (en el grupo seleccionado)
                  if (horarioProvider.horariosDelGrupoSeleccionado.isEmpty && horarioProvider.isLoaded) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(spacing.xl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 48,
                              color: colors.textSecondary,
                            ),
                            SizedBox(height: spacing.md),
                            Text(
                              'No hay horarios para este grupo',
                              style: textStyles.bodyMedium.copyWith(
                                color: colors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Mostrar calendario si hay horarios
                  return _buildWeeklyCalendar(horarioProvider);
                },
              ),
            ] else ...[
              Center(
                child: Padding(
                  padding: EdgeInsets.all(spacing.xl),
                  child: Column(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 64,
                        color: colors.textSecondary,
                      ),
                      SizedBox(height: spacing.md),
                      Text(
                        'Selecciona un grupo para ver su horario',
                        style: textStyles.bodyLarge.copyWith(
                          color: colors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyCalendar(HorarioProvider horarioProvider) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcular tamaños responsive
        final isMobile = constraints.maxWidth < 600;
        final hourColumnWidth = isMobile ? 60.0 : 80.0;
        final cellHeight = isMobile ? 70.0 : 80.0; // Altura fija por hora para mejor alineación

        return Container(
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
        );
      },
    );
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
  bool _isLoading = false;

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

    return AlertDialog(
      title: Text('Crear Clase', style: textStyles.headlineMedium),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                      Text(
                        'Día: ${_getDiaNombre(widget.diaSemana)}',
                        style: textStyles.bodyMedium,
                      ),
                      Text(
                        'Grupo: ${widget.grupo.nombre}',
                        style: textStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: spacing.lg),

                // Selector de Hora Fin
                DropdownButtonFormField<String>(
                  value: _selectedHoraFin,
                  decoration: InputDecoration(
                    labelText: 'Hora de Fin',
                    hintText: 'Selecciona la hora de fin',
                  ),
                  items: _getHorasFinDisponibles(widget.horaInicio).map((hora) {
                    return DropdownMenuItem<String>(
                      value: hora,
                      child: Text(hora),
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
                      value: _selectedMateria,
                      decoration: InputDecoration(
                        labelText: 'Materia',
                        hintText: 'Selecciona una materia',
                      ),
                      items: materiaProvider.materias.map((materia) {
                        return DropdownMenuItem<Materia>(
                          value: materia,
                          child: Text(materia.nombre),
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
                            child: Text('${profesor.nombres} ${profesor.apellidos}'),
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
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createClass,
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('Crear Clase'),
        ),
      ],
    );
  }

  Future<void> _createClass() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMateria == null) return;

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final horarioProvider = Provider.of<HorarioProvider>(context, listen: false);
    final colors = context.colors;

    try {
      final token = authProvider.accessToken;
      if (token == null) return;

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
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Clase creada correctamente')),
        );
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

  const EditClassDialog({
    super.key,
    required this.horario,
  });

  @override
  State<EditClassDialog> createState() => _EditClassDialogState();
}

class _EditClassDialogState extends State<EditClassDialog> {
  final _formKey = GlobalKey<FormState>();
  User? _selectedProfesor;
  String? _selectedHoraFin;
  bool _isLoading = false;

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

    return AlertDialog(
      title: Text('Editar Clase', style: textStyles.headlineMedium),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Información del horario (solo lectura)
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
                        'Horario: ${widget.horario.horaInicio} - ${_selectedHoraFin ?? widget.horario.horaFin}',
                        style: textStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Día: ${widget.horario.diaSemanaNombre}',
                        style: textStyles.bodyMedium,
                      ),
                      Text(
                        'Grupo: ${widget.horario.grupo.nombre}',
                        style: textStyles.bodyMedium,
                      ),
                      Text(
                        'Materia: ${widget.horario.materia.nombre}',
                        style: textStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: spacing.lg),

                // Selector de Hora Fin
                DropdownButtonFormField<String>(
                  value: _selectedHoraFin,
                  decoration: InputDecoration(
                    labelText: 'Hora de Fin',
                    hintText: 'Selecciona la hora de fin',
                  ),
                  items: _getHorasFinDisponibles(widget.horario.horaInicio).map((hora) {
                    return DropdownMenuItem<String>(
                      value: hora,
                      child: Text(hora),
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

                // Selector de Profesor
                Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    // Encontrar el profesor en la lista actual (por referencia)
                    User? selectedProfesorFromList;
                    if (_selectedProfesor != null) {
                      selectedProfesorFromList = userProvider.professors.firstWhere(
                        (p) => p.id == _selectedProfesor!.id,
                        orElse: () => _selectedProfesor!,
                      );
                    }

                    return DropdownButtonFormField<User?>(
                      value: selectedProfesorFromList,
                      decoration: InputDecoration(
                        labelText: 'Profesor',
                        hintText: 'Selecciona un profesor',
                      ),
                      items: [
                        const DropdownMenuItem<User?>(
                          value: null,
                          child: Text('Sin profesor'),
                        ),
                        ...userProvider.professors.map((profesor) {
                          return DropdownMenuItem<User?>(
                            value: profesor,
                            child: Text('${profesor.nombres} ${profesor.apellidos}'),
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
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: Text('Cancelar'),
        ),
        TextButton(
          onPressed: _isLoading ? null : _deleteClass,
          style: TextButton.styleFrom(foregroundColor: context.colors.error),
          child: Text('Eliminar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateClass,
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

  Future<void> _updateClass() async {
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final horarioProvider = Provider.of<HorarioProvider>(context, listen: false);
    final colors = context.colors;

    try {
      final token = authProvider.accessToken;
      if (token == null) return;

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

      if (success && mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Clase actualizada correctamente')),
        );
      } else if (mounted) {
        final errorMessage = horarioProvider.errorMessage ?? 'Error al actualizar clase';
        
        // Verificar si es un error de conflicto usando el ConflictError del provider
        if (horarioProvider.conflictError != null) {
          _showConflictDialog(horarioProvider.conflictError!, 'actualizar');
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool?> _showDeleteConfirmationDialog() async {
    const errorColor = Colors.red;

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar esta clase?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: errorColor),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteClass() async {
    final confirmed = await _showDeleteConfirmationDialog();

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final horarioProvider = Provider.of<HorarioProvider>(context, listen: false);
    final colors = context.colors;

    try {
      final token = authProvider.accessToken;
      if (token == null) return;

      final success = await horarioProvider.deleteHorario(token, widget.horario.id);

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Clase eliminada correctamente')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(horarioProvider.errorMessage ?? 'Error al eliminar clase'),
            backgroundColor: colors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: colors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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