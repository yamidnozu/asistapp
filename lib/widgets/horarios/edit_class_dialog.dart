import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/horario.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/horario_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/academic/horario_service.dart';
import '../../theme/theme_extensions.dart';
import '../components/index.dart';

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
    // Si la hora fin existente no está en las horas disponibles, usar la primera disponible o null
    final horasDisponibles = _getHorasFinDisponibles(widget.horario.horaInicio);
    _selectedHoraFin = horasDisponibles.contains(widget.horario.horaFin)
        ? widget.horario.horaFin
        : (horasDisponibles.isNotEmpty ? horasDisponibles.first : null);
  }

  @override
  Widget build(BuildContext context) {
    final textStyles = context.textStyles;
    final spacing = context.spacing;
    final colors = context.colors;

    final horasDisponibles = _getHorasFinDisponibles(widget.horario.horaInicio);
    return ClarityFormDialog(
      title: Text('Editar Clase', style: textStyles.headlineMedium),
      formKey: _formKey,
      onSave: _updateClass,
      saveLabel: 'Actualizar',
      cancelLabel: 'Cancelar',
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(spacing.md),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(spacing.borderRadius),
                border: Border.all(color: colors.borderLight),
              ),
              child: Column(
                children: [
                  Text(
                    'Horario: ${widget.horario.horaInicio} - ${_selectedHoraFin ?? (horasDisponibles.contains(widget.horario.horaFin) ? widget.horario.horaFin : (horasDisponibles.isNotEmpty ? horasDisponibles.first : '—'))}',
                    style: textStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text('Día: ${widget.horario.diaSemanaNombre}',
                      style: textStyles.bodyMedium),
                  Text('Grupo: ${widget.horario.grupo.nombre}',
                      style: textStyles.bodyMedium),
                  Text('Materia: ${widget.horario.materia.nombre}',
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
                  hintText: 'Selecciona la hora de fin'),
              items: _getHorasFinDisponibles(widget.horario.horaInicio)
                  .map((hora) => DropdownMenuItem<String>(
                      value: hora,
                      child: Text(hora,
                          overflow: TextOverflow.ellipsis, maxLines: 1)))
                  .toList(),
              validator: (value) => (value == null || value.isEmpty)
                  ? 'La hora de fin es requerida'
                  : null,
              onChanged: (hora) => setState(() => _selectedHoraFin = hora),
            ),
            SizedBox(height: spacing.md),
            Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                // Buscar el profesor en la lista actual de profesores
                User? selectedProfesorFromList;
                if (_selectedProfesor != null) {
                  final found = userProvider.professors
                      .where((p) => p.id == _selectedProfesor!.id)
                      .toList();
                  if (found.isNotEmpty) {
                    selectedProfesorFromList = found.first;
                  }
                  // Si no se encuentra, dejamos selectedProfesorFromList como null
                  // para evitar el error del DropdownButton
                }

                return DropdownButtonFormField<User?>(
                  isExpanded: true,
                  value:
                      selectedProfesorFromList, // Será null si no se encuentra en la lista
                  decoration: InputDecoration(
                    labelText: 'Profesor',
                    hintText: _selectedProfesor != null &&
                            selectedProfesorFromList == null
                        ? 'Profesor actual: ${_selectedProfesor!.nombres} (no disponible)'
                        : 'Selecciona un profesor',
                  ),
                  items: [
                    const DropdownMenuItem<User?>(
                        value: null, child: Text('Sin profesor')),
                    ...userProvider.professors.map((profesor) {
                      return DropdownMenuItem<User?>(
                        value: profesor,
                        child: Text('${profesor.nombres} ${profesor.apellidos}',
                            overflow: TextOverflow.ellipsis, maxLines: 1),
                      );
                    }),
                  ],
                  onChanged: (profesor) =>
                      setState(() => _selectedProfesor = profesor),
                );
              },
            ),
            SizedBox(height: spacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _onDeletePressed,
                style: TextButton.styleFrom(foregroundColor: colors.error),
                child: const Text('Eliminar'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _onDeletePressed() async {
    final confirmed = await _showDeleteConfirmationDialog();
    if (confirmed != true) return;

    final success = await _deleteClass();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clase eliminada correctamente')));
      Navigator.of(context).pop(true);
    }
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
      if (minutos == 24 * 60) {
        horasDisponibles.add('24:00');
      } else {
        horasDisponibles.add(
            '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}');
      }
    }
    return horasDisponibles;
  }

  Future<bool> _updateClass() async {
    if (!_formKey.currentState!.validate()) return false;
    final messenger = ScaffoldMessenger.of(context);
    final colors = context.colors;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final horarioProvider =
          Provider.of<HorarioProvider>(context, listen: false);
      final token = authProvider.accessToken;
      if (token == null) return false;

      final success = await horarioProvider.updateHorario(
        token,
        widget.horario.id,
        UpdateHorarioRequest(
          profesorId: _selectedProfesor?.id,
          diaSemana: widget.horario.diaSemana,
          horaInicio: widget.horario.horaInicio,
          horaFin: _selectedHoraFin ?? widget.horario.horaFin,
        ),
      );

      if (success) {
        messenger.showSnackBar(
            const SnackBar(content: Text('Clase actualizada correctamente')));
        return true;
      }
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: colors.error));
    }
    return false;
  }

  Future<bool?> _showDeleteConfirmationDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content:
            const Text('¿Estás seguro de que quieres eliminar esta clase?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<bool> _deleteClass() async {
    final messenger = ScaffoldMessenger.of(context);
    final colors = context.colors;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final horarioProvider =
          Provider.of<HorarioProvider>(context, listen: false);
      final token = authProvider.accessToken;
      if (token == null) return false;

      final success =
          await horarioProvider.deleteHorario(token, widget.horario.id);
      if (!mounted) return false;
      if (success) {
        messenger.showSnackBar(
            const SnackBar(content: Text('Clase eliminada correctamente')));
        return true;
      } else {
        messenger.showSnackBar(SnackBar(
            content:
                Text(horarioProvider.errorMessage ?? 'Error al eliminar clase'),
            backgroundColor: colors.error));
      }
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: colors.error));
    }
    return false;
  }
}
