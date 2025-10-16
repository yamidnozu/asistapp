import '../data/models.dart';

class ProjectModule {
  void applyDaily(PlayerState s, List<PlanEntry> plan) {
    for (final p in s.projects) {
      final worked = plan.any((e) => e.action == 'project:${p.id}');
      if (worked) {
        p.progress += 0.06; // ~16 días de trabajo para 100%
        if (p.progress >= 1.0) {
          p.stage = (p.stage + 1).clamp(0, 3);
          p.progress = 0.0;
          if (p.stage == 2) {
            // lanzamiento → generar ingreso extra basal
            s.money += 50;
          }
        }
      } else {
        // decay suave si lo abandonas
        p.progress = (p.progress - 0.01).clamp(0.0, 1.0);
      }
    }
  }
}