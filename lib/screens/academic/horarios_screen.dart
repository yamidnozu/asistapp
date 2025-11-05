import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/grupo_provider.dart';
import '../../providers/materia_provider.dart';
import '../../providers/horario_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/academic_service.dart' as academic_service;
import '../../theme/theme_extensions.dart';
import '../../models/grupo.dart';
import '../../models/materia.dart';
import '../../models/user.dart';

class HorariosScreen extends StatefulWidget {
  const HorariosScreen({super.key});

  @override
  State<HorariosScreen> createState() => _HorariosScreenState();
}

class _HorariosScreenState extends State<HorariosScreen> {
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

    final token = authProvider.accessToken;
    final institutionId = authProvider.selectedInstitutionId;

    if (token != null && institutionId != null) {
      try {
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
              backgroundColor: context.colors.error,
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
            // Selector de Grupo
            Text(
              'Seleccionar Grupo',
              style: textStyles.headlineSmall,
            ),
            SizedBox(height: spacing.md),
            Consumer<GrupoProvider>(
              builder: (context, grupoProvider, child) {
                if (grupoProvider.isLoading) {
                  return const CircularProgressIndicator();
                }

                return DropdownButtonFormField<Grupo>(
                  value: _selectedGrupo,
                  decoration: InputDecoration(
                    labelText: 'Grupo',
                    hintText: 'Selecciona un grupo',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(spacing.borderRadius),
                    ),
                  ),
                  items: grupoProvider.grupos.map((grupo) {
                    return DropdownMenuItem<Grupo>(
                      value: grupo,
                      child: Text('${grupo.nombre} - ${grupo.grado}'),
                    );
                  }).toList(),
                  onChanged: (grupo) {
                    setState(() => _selectedGrupo = grupo);
                    if (grupo != null) {
                      _loadHorariosForGrupo(grupo.id);
                    }
                  },
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
              _buildWeeklyCalendar(),
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

  Widget _buildWeeklyCalendar() {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final spacing = context.spacing;

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
              // Columna de horas (vacía en header)
              SizedBox(width: 80),
              // Días de la semana
              ..._diasSemana.map((dia) => Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: spacing.md),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: colors.borderLight),
                    ),
                  ),
                  child: Text(
                    dia,
                    style: textStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )),
            ],
          ),
          Divider(height: 0),

          // Filas de horas
          ..._horas.map((hora) => _buildHourRow(hora)),
        ],
      ),
    );
  }

  Widget _buildHourRow(String hora) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    return Row(
      children: [
        // Columna de hora
        Container(
          width: 80,
          padding: EdgeInsets.symmetric(vertical: spacing.sm, horizontal: spacing.xs),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: colors.borderLight),
            ),
          ),
          child: Text(
            hora,
            style: textStyles.bodySmall.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        // Celdas de días
        ...List.generate(_diasSemana.length, (index) {
          final diaSemana = _diasSemanaValues[index];
          return Expanded(
            child: _buildScheduleCell(hora, diaSemana),
          );
        }),
      ],
    );
  }

  Widget _buildScheduleCell(String hora, int diaSemana) {
    final colors = context.colors;

    // Aquí deberíamos verificar si hay una clase programada
    // Por ahora, solo mostramos celdas vacías clickeables

    return InkWell(
      onTap: () => _showCreateClassDialog(hora, diaSemana),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: colors.borderLight),
            top: BorderSide(color: colors.borderLight),
          ),
        ),
        child: Container(
          color: colors.background.withValues(alpha: 0.5),
          child: Center(
            child: Icon(
              Icons.add,
              color: colors.textDisabled,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadHorariosForGrupo(String grupoId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final horarioProvider = Provider.of<HorarioProvider>(context, listen: false);

    final token = authProvider.accessToken;
    if (token != null) {
      try {
        await horarioProvider.loadHorariosByGrupo(token, grupoId);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error cargando horarios: $e'),
              backgroundColor: context.colors.error,
            ),
          );
        }
      }
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
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final textStyles = context.textStyles;
    final spacing = context.spacing;

    return AlertDialog(
      title: Text('Crear Clase', style: textStyles.headlineMedium),
      content: Form(
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
                    'Horario: ${widget.horaInicio} - ${_getHoraFin(widget.horaInicio)}',
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
            Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                return DropdownButtonFormField<User>(
                  value: _selectedProfesor,
                  decoration: InputDecoration(
                    labelText: 'Profesor (opcional)',
                    hintText: 'Selecciona un profesor',
                  ),
                  items: userProvider.professors.map((profesor) {
                    return DropdownMenuItem<User>(
                      value: profesor,
                      child: Text('${profesor.nombres} ${profesor.apellidos}'),
                    );
                  }).toList(),
                  onChanged: (profesor) {
                    setState(() => _selectedProfesor = profesor);
                  },
                );
              },
            ),
          ],
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

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final horarioProvider = Provider.of<HorarioProvider>(context, listen: false);

      final token = authProvider.accessToken;
      if (token == null) return;

      // TODO: Obtener periodo académico activo
      const periodoId = '550e8400-e29b-41d4-a716-446655440000'; // ID por defecto

      final success = await horarioProvider.createHorario(
        token,
        academic_service.CreateHorarioRequest(
          periodoId: periodoId,
          grupoId: widget.grupo.id,
          materiaId: _selectedMateria!.id,
          profesorId: _selectedProfesor?.id,
          diaSemana: widget.diaSemana,
          horaInicio: widget.horaInicio,
          horaFin: _getHoraFin(widget.horaInicio),
        ),
      );

      if (success && mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Clase creada correctamente')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(horarioProvider.errorMessage ?? 'Error al crear clase'),
            backgroundColor: context.colors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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
}