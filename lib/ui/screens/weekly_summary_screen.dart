import 'package:flutter/widgets.dart';
import '../theme.dart';
import '../primitives/glass_container.dart';
import '../../core/life_controller.dart';
import '../../data/goal.dart';

class WeeklySummaryScreen extends StatelessWidget {
  final int week;
  final double balance;
  final double healthAvg;
  final double stressAvg;
  final int reputation;
  final List<Goal> goals;
  final String narrative;

  const WeeklySummaryScreen({
    super.key,
    required this.week,
    required this.balance,
    required this.healthAvg,
    required this.stressAvg,
    required this.reputation,
    required this.goals,
    required this.narrative,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ChronoTheme.background,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text('Resumen Semana $week', style: ChronoTheme.baseText.copyWith(fontSize: 24)),
          const SizedBox(height: 16),
          GlassContainer(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(narrative, style: ChronoTheme.baseText.copyWith(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 16),
          _summaryItem('Financiero', 'Balance: \$${balance.toStringAsFixed(2)}'),
          _summaryItem('Salud Física', '${healthAvg.toStringAsFixed(0)}% promedio'),
          _summaryItem('Estrés Mental', '${stressAvg.toStringAsFixed(0)}% promedio'),
          _summaryItem('Reputación', '$reputation/100'),
          const SizedBox(height: 16),
          Text('Metas:', style: ChronoTheme.baseText.copyWith(fontSize: 18)),
          ...goals.map((g) => _goalItem(g)),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: ChronoTheme.glass(),
              child: Text('Continuar', style: ChronoTheme.baseText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: ChronoTheme.baseText),
          Text(value, style: ChronoTheme.baseText.copyWith(color: ChronoTheme.textDim)),
        ],
      ),
    );
  }

  Widget _goalItem(Goal g) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(g.title, style: ChronoTheme.baseText),
          const Spacer(),
          Text('${(g.progress * 100).toInt()}%', style: ChronoTheme.baseText),
          if (g.completed) Text(' ✓', style: ChronoTheme.baseText.copyWith(color: ChronoTheme.ok)),
        ],
      ),
    );
  }
}