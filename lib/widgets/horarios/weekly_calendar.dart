import 'package:flutter/material.dart';

import '../../models/horario.dart';
import '../../providers/horario_provider.dart';
import '../../theme/theme_extensions.dart';

typedef OnHorarioTap = void Function(Horario horario);
typedef OnEmptyCellTap = void Function(String hora, int diaSemana);

class WeeklyCalendar extends StatelessWidget {
  final HorarioProvider horarioProvider;
  final List<String> horas;
  final List<String> diasSemana;
  final List<int> diasSemanaValues;
  final OnEmptyCellTap onEmptyCellTap;
  final OnHorarioTap onHorarioTap;

  const WeeklyCalendar({
    super.key,
    required this.horarioProvider,
    required this.horas,
    required this.diasSemana,
    required this.diasSemanaValues,
    required this.onEmptyCellTap,
    required this.onHorarioTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final hourColumnWidth = isMobile ? 60.0 : 80.0;
        final cellHeight = isMobile ? 70.0 : 80.0;

  final spacing = context.spacing;

  return SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(spacing.borderRadius),
              border: Border.all(color: context.colors.borderLight),
            ),
            child: Column(
              children: [
                _buildHeader(context, cellHeight, hourColumnWidth),
                const Divider(height: 0),
                ...horas.map((hora) => _buildHourRow(
                      context,
                      hora,
                      cellHeight: cellHeight,
                      hourColumnWidth: hourColumnWidth,
                      isMobile: isMobile,
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, double cellHeight, double hourColumnWidth) {
    final spacing = context.spacing;

    return Row(
      children: [
        SizedBox(width: hourColumnWidth, height: cellHeight),
        ...diasSemana.map((dia) => Expanded(
              child: Container(
                height: cellHeight,
                padding: EdgeInsets.symmetric(
                  vertical: spacing.md / 2,
                  horizontal: spacing.md / 2,
                ),
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: context.colors.borderLight)),
                ),
                child: Center(
                  child: Text(
                    dia,
                    style: context.textStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.colors.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildHourRow(
    BuildContext context,
    String hora, {
    required double hourColumnWidth,
    required double cellHeight,
    required bool isMobile,
  }) {
    return SizedBox(
      height: cellHeight,
      child: Row(
        children: [
          Container(
            width: hourColumnWidth,
            height: cellHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: context.colors.borderLight),
                right: BorderSide(color: context.colors.borderLight),
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                hora,
                style: context.textStyles.bodySmall.copyWith(
                  color: context.colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          ...List.generate(diasSemana.length, (index) {
            final diaSemana = diasSemanaValues[index];
            return Expanded(
              child: _buildScheduleCell(
                context,
                hora,
                diaSemana,
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
    BuildContext context,
    String hora,
    int diaSemana, {
    required double cellHeight,
    required bool isMobile,
  }) {
    final horarios = horarioProvider.horariosDelGrupoSeleccionado;

    if (_estaCeldaOcupada(hora, diaSemana, horarios)) {
      return Container(
        height: cellHeight,
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: context.colors.borderLight),
            top: BorderSide(color: context.colors.borderLight),
          ),
            color: context.colors.surface.withValues(alpha: 0.3),
        ),
      );
    }

    Horario? horarioExistente;
    for (final horario in horarios) {
      if (horario.diaSemana == diaSemana && horario.horaInicio == hora) {
        horarioExistente = horario;
        break;
      }
    }

    if (horarioExistente != null) {
      final horarioConcreto = horarioExistente;
      final duracionHoras = _calcularDuracionEnHoras(horarioConcreto.horaInicio, horarioConcreto.horaFin);
      final alturaTotal = cellHeight * duracionHoras;
      return InkWell(
        onTap: () => onHorarioTap(horarioConcreto),
        child: Container(
          height: alturaTotal,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: context.colors.borderLight),
              top: BorderSide(color: context.colors.borderLight),
            ),
            color: _getMateriaColor(context, horarioExistente.materia.nombre),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? context.spacing.xs : context.spacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  horarioExistente.materia.nombre,
                  style: context.textStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.colors.white,
                    fontSize: isMobile ? 11 : 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (horarioExistente.profesor != null) ...[
                  SizedBox(height: isMobile ? context.spacing.xs : context.spacing.sm),
                  Text(
                    '${horarioExistente.profesor!.nombres.split(' ').first} ${horarioExistente.profesor!.apellidos.split(' ').first}',
                    style: context.textStyles.bodySmall.copyWith(
                      color: context.colors.white.withValues(alpha: 0.9),
                      fontSize: isMobile ? 9 : 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                SizedBox(height: isMobile ? context.spacing.xs : context.spacing.sm),
                Text(
                  '${horarioExistente.horaInicio} - ${horarioExistente.horaFin}',
                    style: context.textStyles.bodySmall.copyWith(
                      color: context.colors.white.withValues(alpha: 0.8),
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

    return InkWell(
      onTap: () => onEmptyCellTap(hora, diaSemana),
      child: Container(
        height: cellHeight,
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: context.colors.borderLight),
            top: BorderSide(color: context.colors.borderLight),
          ),
        ),
        child: Center(
            child: Icon(
              Icons.add,
              size: isMobile ? 16 : 20,
              color: context.colors.primary.withValues(alpha: 0.5),
            ),
        ),
      ),
    );
  }
}

bool _estaCeldaOcupada(String hora, int diaSemana, List<Horario> horarios) {
  for (final horario in horarios) {
    if (horario.diaSemana == diaSemana) {
      if (horario.horaInicio == hora) continue;
      final horaInicioInt = _horaToInt(horario.horaInicio);
      final horaFinInt = _horaToInt(horario.horaFin);
      final horaActualInt = _horaToInt(hora);
      if (horaInicioInt < horaActualInt && horaFinInt > horaActualInt) {
        return true;
      }
    }
  }
  return false;
}

int _horaToInt(String hora) {
  final parts = hora.split(':');
  final hours = int.parse(parts[0]);
  final minutes = int.parse(parts[1]);
  return hours * 60 + minutes;
}

double _calcularDuracionEnHoras(String horaInicio, String horaFin) {
  final inicioInt = _horaToInt(horaInicio);
  final finInt = _horaToInt(horaFin);
  return (finInt - inicioInt) / 60.0;
}

Color _getMateriaColor(BuildContext context, String materiaNombre) {
  final hash = materiaNombre.hashCode;
  final index = hash % 5;
  switch (index) {
    case 0:
      return context.colors.primary;
    case 1:
      return context.colors.secondary;
    case 2:
      return Colors.green;
    case 3:
      return Colors.orange;
    case 4:
      return Colors.purple;
    default:
      return context.colors.primary;
  }
}
