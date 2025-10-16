import 'package:flutter/widgets.dart';
import '../theme.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key, required this.lines, required this.onContinue});
  final List<String> lines;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ChronoTheme.background,
      padding: const EdgeInsets.fromLTRB(16, 64, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Resumen del día', style: ChronoTheme.baseText.copyWith(fontSize: 22)),
          const SizedBox(height: 14),
          ...lines.map((l) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text('• $l', style: ChronoTheme.baseText),
          )),
          const Spacer(),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: onContinue,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: ChronoTheme.ok, borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Continuar', style: ChronoTheme.baseText.copyWith(color: const Color(0xFF071018))),
              ),
            ),
          )
        ],
      ),
    );
  }
}