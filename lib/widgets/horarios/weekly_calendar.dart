import 'package:flutter/material.dart';

import '../../models/horario.dart';
import '../../providers/horario_provider.dart';
import '../../theme/theme_extensions.dart';

typedef OnHorarioTap = void Function(Horario horario);
typedef OnEmptyCellTap = void Function(String hora, int diaSemana);

/// Paleta de colores vibrantes y muy diferenciados para las materias
const List<Color> _materiaColors = [
  Color(0xFF3B82F6), // Azul brillante
  Color(0xFFEF4444), // Rojo
  Color(0xFF10B981), // Verde esmeralda
  Color(0xFFF59E0B), // Naranja/Ámbar
  Color(0xFF8B5CF6), // Púrpura
  Color(0xFFEC4899), // Rosa
  Color(0xFF06B6D4), // Cyan
  Color(0xFF84CC16), // Lima
  Color(0xFFF97316), // Naranja intenso
  Color(0xFF6366F1), // Índigo
  Color(0xFF14B8A6), // Teal
  Color(0xFFE11D48), // Rosa/Rojo
  Color(0xFF0EA5E9), // Azul cielo
  Color(0xFFA855F7), // Violeta
  Color(0xFF22C55E), // Verde
  Color(0xFFEAB308), // Amarillo
];

/// Mapa para almacenar los colores asignados a cada materia
final Map<String, Color> _materiaColorMap = {};

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
        final hourColumnWidth = isMobile ? 55.0 : 75.0;
        // Altura por cada slot de 30 min - más alto para ver mejor los bloques
        final cellHeight = isMobile ? 25.0 : 30.0;

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
                _buildCalendarBody(
                    context, cellHeight, hourColumnWidth, isMobile),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
      BuildContext context, double cellHeight, double hourColumnWidth) {
    final spacing = context.spacing;

    return Row(
      children: [
        SizedBox(width: hourColumnWidth, height: cellHeight),
        ...diasSemana.map((dia) => Expanded(
              child: Container(
                height: cellHeight,
                padding: EdgeInsets.symmetric(
                  vertical: spacing.sm / 2,
                  horizontal: spacing.sm / 2,
                ),
                decoration: BoxDecoration(
                  border: Border(
                      left: BorderSide(color: context.colors.borderLight)),
                ),
                child: Center(
                  child: Text(
                    dia,
                    style: context.textStyles.bodySmall.copyWith(
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

  Widget _buildCalendarBody(BuildContext context, double cellHeight,
      double hourColumnWidth, bool isMobile) {
    final horarios = horarioProvider.horariosDelGrupoSeleccionado;
    final totalHeight = cellHeight * horas.length;

    return SizedBox(
      height: totalHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Columna de horas
          SizedBox(
            width: hourColumnWidth,
            child: Column(
              children: horas
                  .map((hora) => _buildHourLabel(
                      context, hora, cellHeight, hourColumnWidth))
                  .toList(),
            ),
          ),
          // Columnas de días con Stack para bloques
          ...List.generate(diasSemana.length, (dayIndex) {
            final diaSemana = diasSemanaValues[dayIndex];
            return Expanded(
              child: _buildDayColumn(
                  context, diaSemana, horarios, cellHeight, isMobile),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHourLabel(BuildContext context, String hora, double cellHeight,
      double hourColumnWidth) {
    // Solo mostrar label completo para horas enteras
    final isFullHour = hora.endsWith(':00');

    return Container(
      width: hourColumnWidth,
      height: cellHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: context.colors.borderLight,
            width: isFullHour ? 1.0 : 0.5,
          ),
          right: BorderSide(color: context.colors.borderLight),
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          isFullHour ? hora : '',
          style: context.textStyles.bodySmall.copyWith(
            color: context.colors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildDayColumn(BuildContext context, int diaSemana,
      List<Horario> horarios, double cellHeight, bool isMobile) {
    final horariosDelDia =
        horarios.where((h) => h.diaSemana == diaSemana).toList();

    return Stack(
      children: [
        // Grid de celdas vacías (background)
        Column(
          children: horas.asMap().entries.map((entry) {
            final hora = entry.value;
            final isFullHour = hora.endsWith(':00');

            final estaOcupada = _estaCeldaOcupadaPorBloquePrevio(
                hora, diaSemana, horariosDelDia);

            return InkWell(
              onTap: estaOcupada ? null : () => onEmptyCellTap(hora, diaSemana),
              child: Container(
                height: cellHeight,
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: context.colors.borderLight),
                    top: BorderSide(
                      color: context.colors.borderLight,
                      width: isFullHour ? 1.0 : 0.5,
                    ),
                  ),
                  color: estaOcupada ? Colors.transparent : null,
                ),
                child: estaOcupada
                    ? null
                    : Center(
                        child: Icon(
                          Icons.add,
                          size: isMobile ? 12 : 16,
                          color: context.colors.primary.withValues(alpha: 0.2),
                        ),
                      ),
              ),
            );
          }).toList(),
        ),
        // Bloques de horarios posicionados
        ...horariosDelDia.map((horario) {
          final startPosition = _getPositionForTime(horario.horaInicio);
          if (startPosition < 0) return const SizedBox.shrink();

          final duracionSlots =
              _calcularDuracionEnSlots(horario.horaInicio, horario.horaFin);
          final alturaBloque = cellHeight * duracionSlots;
          final topPosition = startPosition * cellHeight;

          return Positioned(
            top: topPosition,
            left: 2,
            right: 2,
            child: _buildHorarioBlock(context, horario, alturaBloque, isMobile),
          );
        }),
      ],
    );
  }

  Widget _buildHorarioBlock(
      BuildContext context, Horario horario, double altura, bool isMobile) {
    final color = _getMateriaColor(horario.materia.nombre);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onHorarioTap(horario),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: altura,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 2 : 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Nombre de la materia
                Text(
                  horario.materia.nombre,
                  style: context.textStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: isMobile ? 9 : 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // Profesor (si existe y hay espacio)
                if (horario.profesor != null && altura > 40) ...[
                  SizedBox(height: isMobile ? 1 : 2),
                  Text(
                    '${horario.profesor!.nombres.split(' ').first} ${horario.profesor!.apellidos.split(' ').first}',
                    style: context.textStyles.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: isMobile ? 7 : 9,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                // Horario
                if (altura > 60) ...[
                  const Spacer(),
                  Text(
                    '${horario.horaInicio} - ${horario.horaFin}',
                    style: context.textStyles.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: isMobile ? 7 : 9,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Calcula la posición (índice de slot) para una hora dada
  /// Soporta horas intermedias interpolando entre slots
  double _getPositionForTime(String hora) {
    // Primero buscar coincidencia exacta
    for (int i = 0; i < horas.length; i++) {
      if (horas[i] == hora) return i.toDouble();
    }

    // Si no hay coincidencia exacta, interpolar
    final horaMinutos = _horaToInt(hora);

    for (int i = 0; i < horas.length - 1; i++) {
      final slotActual = _horaToInt(horas[i]);
      final slotSiguiente = _horaToInt(horas[i + 1]);

      if (horaMinutos >= slotActual && horaMinutos < slotSiguiente) {
        // Calcular posición proporcional
        final fraccion =
            (horaMinutos - slotActual) / (slotSiguiente - slotActual);
        return i + fraccion;
      }
    }

    return -1;
  }

  bool _estaCeldaOcupadaPorBloquePrevio(
      String hora, int diaSemana, List<Horario> horarios) {
    final horaActualInt = _horaToInt(hora);

    for (final horario in horarios) {
      if (horario.diaSemana == diaSemana) {
        if (horario.horaInicio == hora) continue;

        final horaInicioInt = _horaToInt(horario.horaInicio);
        final horaFinInt = _horaToInt(horario.horaFin);

        if (horaInicioInt < horaActualInt && horaFinInt > horaActualInt) {
          return true;
        }
      }
    }
    return false;
  }

  /// Calcula duración en slots de 30 minutos
  double _calcularDuracionEnSlots(String horaInicio, String horaFin) {
    final inicioInt = _horaToInt(horaInicio);
    final finInt = _horaToInt(horaFin);
    // Cada slot es de 30 minutos
    return (finInt - inicioInt) / 30.0;
  }
}

int _horaToInt(String hora) {
  final parts = hora.split(':');
  final hours = int.parse(parts[0]);
  final minutes = int.parse(parts[1]);
  return hours * 60 + minutes;
}

Color _getMateriaColor(String materiaNombre) {
  if (_materiaColorMap.containsKey(materiaNombre)) {
    return _materiaColorMap[materiaNombre]!;
  }

  final colorIndex = _materiaColorMap.length % _materiaColors.length;
  final color = _materiaColors[colorIndex];
  _materiaColorMap[materiaNombre] = color;

  return color;
}
