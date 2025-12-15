import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/conflict_error.dart';
import '../../models/grupo.dart';
import '../../models/materia.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/horario_provider.dart';
import '../../providers/materia_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/academic/horario_service.dart';
import '../../theme/theme_extensions.dart';
import '../components/index.dart';

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
    // Selecciona por defecto la hora fin calculada (2 horas) si está disponible,
    // en caso contrario usar la primera hora disponible o null.
    final horasDisponibles = _getHorasFinDisponibles(widget.horaInicio);
    final defaultHoraFin = _getHoraFin(widget.horaInicio);
    _selectedHoraFin = horasDisponibles.contains(defaultHoraFin)
        ? defaultHoraFin
        : (horasDisponibles.isNotEmpty ? horasDisponibles.first : null);
  }

  @override
  Widget build(BuildContext context) {
    final textStyles = context.textStyles;
    final spacing = context.spacing;
    final horasDisponibles = _getHorasFinDisponibles(widget.horaInicio);

    return ClarityFormDialog(
      title: Text('Crear Clase', style: textStyles.headlineMedium),
      formKey: _formKey,
      onSave: _createClass,
      saveLabel: 'Crear Clase',
      cancelLabel: 'Cancelar',
      children: [
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
                'Horario: ${widget.horaInicio} - ${_selectedHoraFin ?? (horasDisponibles.isNotEmpty ? _getHoraFin(widget.horaInicio) : '—')}',
                style:
                    textStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              ),
              Text('Día: ${_getDiaNombre(widget.diaSemana)}',
                  style: textStyles.bodyMedium),
              Text('Grupo: ${widget.grupo.nombre}',
                  style: textStyles.bodyMedium),
            ],
          ),
        ),
        SizedBox(height: spacing.lg),
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: _selectedHoraFin,
          decoration: const InputDecoration(
            labelText: 'Hora de Fin',
            hintText: 'Selecciona la hora de fin',
          ),
          items: _getHorasFinDisponibles(widget.horaInicio)
              .map((hora) => DropdownMenuItem<String>(
                  value: hora,
                  child:
                      Text(hora, overflow: TextOverflow.ellipsis, maxLines: 1)))
              .toList(),
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
        Consumer<MateriaProvider>(
          builder: (context, materiaProvider, child) {
            return DropdownButtonFormField<Materia>(
              isExpanded: true,
              value: _selectedMateria,
              decoration: const InputDecoration(
                labelText: 'Materia',
                hintText: 'Selecciona una materia',
              ),
              items: materiaProvider.materias
                  .map((materia) => DropdownMenuItem<Materia>(
                      value: materia,
                      child: Text(materia.nombre,
                          overflow: TextOverflow.ellipsis, maxLines: 1)))
                  .toList(),
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
        Consumer2<UserProvider, HorarioProvider>(
          builder: (context, userProvider, horarioProvider, child) {
            final profesoresDisponibles =
                horarioProvider.getProfesoresDisponibles(
              userProvider.professors,
              widget.diaSemana,
              widget.horaInicio,
              _selectedHoraFin ?? _getHoraFin(widget.horaInicio),
            );

            User? selectedProfesorFromList;
            if (_selectedProfesor != null) {
              selectedProfesorFromList = profesoresDisponibles.firstWhere(
                (p) => p.id == _selectedProfesor!.id,
                orElse: () => _selectedProfesor!,
              );
            }

            return DropdownButtonFormField<User>(
              isExpanded: true,
              value: selectedProfesorFromList,
              decoration: InputDecoration(
                labelText: 'Profesor',
                hintText: 'Selecciona un profesor',
                helperText: profesoresDisponibles.length <
                        userProvider.professors.length
                    ? '${profesoresDisponibles.length} disponibles'
                    : null,
              ),
              items: profesoresDisponibles.map((profesor) {
                return DropdownMenuItem<User>(
                  value: profesor,
                  child: Text('${profesor.nombres} ${profesor.apellidos}',
                      overflow: TextOverflow.ellipsis, maxLines: 1),
                );
              }).toList(),
              validator: (value) {
                if (value == null) {
                  return 'El profesor es requerido';
                }
                return null;
              },
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
    if (_selectedProfesor == null) return false;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final horarioProvider =
        Provider.of<HorarioProvider>(context, listen: false);
    final colors = context.colors;

    try {
      final token = authProvider.accessToken;
      if (token == null) return false;

      final periodoId = widget.grupo.periodoId;

      final success = await horarioProvider.createHorario(
        token,
        CreateHorarioRequest(
          periodoId: periodoId!,
          grupoId: widget.grupo.id,
          materiaId: _selectedMateria!.id,
          profesorId: _selectedProfesor!.id,
          diaSemana: widget.diaSemana,
          horaInicio: widget.horaInicio,
          horaFin: _selectedHoraFin ?? _getHoraFin(widget.horaInicio),
          institucionId: authProvider.selectedInstitutionId!,
        ),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Clase creada correctamente')));
        return true;
      } else if (mounted) {
        final errorMessage =
            horarioProvider.errorMessage ?? 'Error al crear clase';
        if (horarioProvider.conflictError != null) {
          _showConflictDialog(horarioProvider.conflictError!, 'crear');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(errorMessage), backgroundColor: colors.error),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: colors.error),
        );
      }
    }

    return false;
  }

  String _getHoraFin(String horaInicio) {
    final parts = horaInicio.split(':');
    final hour = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    // Por defecto 1 hora después
    final totalMinutos = hour * 60 + minutes + 60;
    final nextHour = (totalMinutos ~/ 60) % 24;
    final nextMinutes = totalMinutos % 60;
    return '${nextHour.toString().padLeft(2, '0')}:${nextMinutes.toString().padLeft(2, '0')}';
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
    final parts = horaInicio.split(':');
    final hourInicio = int.parse(parts[0]);
    final minutesInicio = int.parse(parts[1]);
    final horasDisponibles = <String>[];

    // Generar intervalos de 30 minutos desde horaInicio+30min hasta 24:00
    int totalMinutosInicio = hourInicio * 60 + minutesInicio;

    for (int minutos = totalMinutosInicio + 30;
        minutos <= 24 * 60;
        minutos += 30) {
      final h = (minutos ~/ 60) % 24;
      final m = minutos % 60;
      // Si es exactamente 24:00 (1440 min), mostrar como 24:00
      if (minutos == 24 * 60) {
        horasDisponibles.add('24:00');
      } else {
        horasDisponibles.add(
            '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}');
      }
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
            if (conflictError.conflictingHorarioIds.isNotEmpty) ...[
              SizedBox(height: spacing.md),
              Text('Horarios en conflicto:',
                  style: textStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600)),
              SizedBox(height: spacing.sm),
              ...conflictError.conflictingHorarioIds.map((id) => Text('- $id',
                  style: textStyles.bodySmall
                      .copyWith(color: colors.textSecondary))),
            ],
            SizedBox(height: spacing.md),
            Text('Sugerencias para resolver el conflicto:',
                style: textStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600)),
            SizedBox(height: spacing.sm),
            ...conflictError.suggestions.map((suggestion) => Text(
                  '• $suggestion',
                  style: textStyles.bodySmall
                      .copyWith(color: colors.textSecondary),
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Revisar Horarios'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
            ),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}
