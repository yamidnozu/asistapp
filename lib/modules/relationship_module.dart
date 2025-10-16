import '../data/models.dart';

class RelationshipModule {
  void applyDaily(PlayerState s, List<PlanEntry> plan) {
    final social = plan.any((p) => p.action == 'social');
    for (final key in s.relations.keys) {
      s.relations[key] = (s.relations[key]! + (social ? 3 : -1)).clamp(0, 100);
    }
  }
}