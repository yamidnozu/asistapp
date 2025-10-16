import '../data/models.dart';
import '../modules/money_module.dart';
import '../modules/health_module.dart';
import '../modules/relationship_module.dart';
import '../modules/project_module.dart';
import '../core/event_engine.dart';

class LifeController {
  LifeController({this.eventEngine});

  final MoneyModule _money = MoneyModule();
  final HealthModule _health = HealthModule();
  final RelationshipModule _rel = RelationshipModule();
  final ProjectModule _proj = ProjectModule();
  final EventEngine? eventEngine;

  PlayerState state = PlayerState();
  DayState currentPlan = DayState(1, []);

  Future<EventResult?> simulateDay() async {
    final plan = currentPlan.plan;

    // Señal simple de "trabajo" para money (evita dependencias cruzadas fuertes)
    final worked = plan.any((p) => p.action == 'work');
    if (worked) {
      state.projects.removeWhere((p) => p.name == '_WORK_FLAG_');
      state.projects.add(Project(id: '_work', name: '_WORK_FLAG_'));
    } else {
      state.projects.removeWhere((p) => p.name == '_WORK_FLAG_');
    }

    _money.applyDaily(state);
    _health.applyDaily(state, plan);
    _rel.applyDaily(state, plan);
    _proj.applyDaily(state, plan);

    final event = await eventEngine?.maybeSpawn(state);

    state.day += 1;
    currentPlan = DayState(state.day, []); // limpia plan para el siguiente

    return event;
  }

  void rewindOneDay() {
    // Demo: retroceso simple con penalización
    state.day = (state.day - 1).clamp(1, 99999);
    state.mental.value = (state.mental.value - 4).clamp(0, 100);
    state.physical.value = (state.physical.value - 2).clamp(0, 100);
  }
}