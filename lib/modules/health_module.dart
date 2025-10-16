import '../data/models.dart';
import 'dart:math';

class HealthModule {
  void applyDaily(PlayerState s, List<PlanEntry> plan) {
    // descanso mejora; trabajo intenso o social nocturno resta
    final didRest = plan.any((p) => p.action == 'rest');
    final didGym  = plan.any((p) => p.action == 'exercise');
    final lateSocial = plan.any((p) => p.block == TimeBlock.night && p.action == 'social');

    s.physical.value += didRest ? 4 : -2;
    if (didGym) s.physical.value += 3;
    if (lateSocial) s.physical.value -= 2;

    // mental
    final didProject = plan.any((p) => p.action.startsWith('project:'));
    final overwork = plan.where((p) => p.action == 'work').length >= 2;
    s.mental.value += (didProject ? 2 : 0) + (didRest ? 3 : -3) + (overwork ? -4 : 0);

    // eventos simples por hábitos
    if (Random().nextDouble() < 0.08 && !didRest) {
      // micro evento: migraña leve
      s.mental.value -= 3;
      s.physical.value -= 1;
    }

    // clamp
    s.physical.value = s.physical.value.clamp(0, 100);
    s.mental.value   = s.mental.value.clamp(0, 100);
  }
}