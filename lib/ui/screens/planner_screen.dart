import 'package:flutter/widgets.dart';
import '../theme.dart';
import '../primitives/glass_container.dart';
import '../widgets/time_block.dart';
import '../../data/models.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({
    super.key,
    required this.initialPlan,
    required this.onSave,
  });
  final List<PlanEntry> initialPlan;
  final void Function(List<PlanEntry>) onSave;

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  final Map<TimeBlock, String?> plan = { for (var b in TimeBlock.values) b: null };
  final activities = const ['work', 'rest', 'social', 'exercise', 'invest', 'project:new_idea'];

  @override
  void initState() {
    super.initState();
    for (final p in widget.initialPlan) {
      plan[p.block] = p.action;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ChronoTheme.background,
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      child: Column(
        children: [
          Text('Planear día', style: ChronoTheme.baseText.copyWith(fontSize: 22)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: TimeBlockWidget(block: TimeBlock.morning, currentAction: plan[TimeBlock.morning], onDrop: (a){ setState(()=> plan[TimeBlock.morning]=a); })),
              const SizedBox(width: 12),
              Expanded(child: TimeBlockWidget(block: TimeBlock.afternoon, currentAction: plan[TimeBlock.afternoon], onDrop: (a){ setState(()=> plan[TimeBlock.afternoon]=a); })),
              const SizedBox(width: 12),
              Expanded(child: TimeBlockWidget(block: TimeBlock.night, currentAction: plan[TimeBlock.night], onDrop: (a){ setState(()=> plan[TimeBlock.night]=a); })),
            ],
          ),
          const SizedBox(height: 16),
          GlassContainer(
            child: Wrap(
              spacing: 8, runSpacing: 8,
              children: activities.map((a) => Draggable<String>(
                data: a,
                feedback: _chip(a, opacity: 0.7),
                child: _chip(a),
              )).toList(),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              final result = <PlanEntry>[];
              plan.forEach((b, a) { if (a != null) result.add(PlanEntry(b, a!)); });
              widget.onSave(result);
              Navigator.of(context).pop();
            },
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: ChronoTheme.accent, borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Guardar plan', style: ChronoTheme.baseText.copyWith(color: const Color(0xFF071018))),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _chip(String a, {double opacity = 1}) {
    return Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0x22FFFFFF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x33FFFFFF)),
        ),
        child: Text(a, style: ChronoTheme.baseText),
      ),
    );
  }
}