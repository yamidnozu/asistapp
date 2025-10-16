import 'package:flutter/widgets.dart';
import '../theme.dart';
import '../primitives/glass_container.dart';
import '../../data/models.dart';

class TimeBlockWidget extends StatelessWidget {
  const TimeBlockWidget({
    super.key,
    required this.block,
    required this.currentAction,
    required this.onDrop,
  });

  final TimeBlock block;
  final String? currentAction;
  final void Function(String action) onDrop;

  String get label => switch (block) {
    TimeBlock.morning => 'Mañana',
    TimeBlock.afternoon => 'Tarde',
    TimeBlock.night => 'Noche',
  };

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onWillAccept: (_) => true,
      onAccept: onDrop,
      builder: (context, _, __) {
        return GlassContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: ChronoTheme.baseText.copyWith(fontSize: 18)),
              const SizedBox(height: 10),
              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0x11000000),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    currentAction == null ? 'Arrastra una actividad aquí' : currentAction!,
                    style: ChronoTheme.baseText,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}