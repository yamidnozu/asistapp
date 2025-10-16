import '../data/models.dart';

class RelationshipModule {
  void applyDaily(PlayerState s, List<PlanEntry> plan) {
    final social = plan.any((p) => p.action == 'social');
    for (final r in s.relations) {
      r.level += social ? 3 : -1;
      r.level = r.level.clamp(0, 100);
    }
  }
}