import 'package:flutter/widgets.dart';
import '../theme.dart';

class Indicator extends StatelessWidget {
  const Indicator({super.key, required this.label, required this.value, this.color});
  final String label;
  final double value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? ChronoTheme.accent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: ChronoTheme.baseText.copyWith(color: ChronoTheme.textDim)),
        const SizedBox(height: 6),
        Container(
          height: 6,
          decoration: BoxDecoration(color: const Color(0x22FFFFFF), borderRadius: BorderRadius.circular(6)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (value / 100).clamp(0, 1),
            child: Container(decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(6))),
          ),
        ),
        const SizedBox(height: 2),
        Text('${value.toStringAsFixed(0)}%', style: ChronoTheme.baseText),
      ],
    );
  }
}

class IndicatorsRow extends StatelessWidget {
  const IndicatorsRow({super.key, required this.money, required this.physical, required this.mental});
  final double money, physical, mental;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Indicator(label: 'Salud física', value: physical, color: ChronoTheme.ok)),
        const SizedBox(width: 12),
        Expanded(child: Indicator(label: 'Salud mental', value: mental, color: ChronoTheme.warn)),
        const SizedBox(width: 12),
        Expanded(child: Indicator(label: 'Dinero', value: (money / 20).clamp(0, 100).toDouble())),
      ],
    );
  }
}