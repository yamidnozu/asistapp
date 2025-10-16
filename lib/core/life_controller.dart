import '../data/models.dart';
import '../modules/money_module.dart';
import '../modules/health_module.dart';
import '../modules/relationship_module.dart';
import '../modules/project_module.dart';
import '../core/event_engine.dart';
import '../core/time_keeper.dart';
import '../core/calendar_system.dart';
import '../data/goal.dart';
import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';

class LifeController {
  final MoneyModule _money = MoneyModule();
  final HealthModule _health = HealthModule();
  final RelationshipModule _rel = RelationshipModule();
  final ProjectModule _proj = ProjectModule();
  final EventEngine? eventEngine;

  late TimeKeeper timeKeeper;
  late ValueNotifier<GameTime> timeNotifier;
  late Box lifeBox;
  late List<String> narrativeHistory;

  PlayerState state = PlayerState();
  DayState currentPlan = DayState(1, []);

  LifeController({this.eventEngine}) {
    timeKeeper = TimeKeeper();
    timeNotifier = timeKeeper.timeNotifier;
    timeKeeper.start();
    lifeBox = Hive.box('life');
    narrativeHistory = [];
    loadState();
  }

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

    // Cambios de reputación por acciones
    state.reputation = (state.reputation + (worked ? 2 : -1)).clamp(0, 100);

    final event = await eventEngine?.maybeSpawn(state);

    state.day += 1;
    currentPlan = DayState(state.day, []); // limpia plan para el siguiente

    // Chequear metas fallidas
    for (var goal in state.goals) {
      if (!goal.completed && goal.deadlineDay < state.day) {
        state.mental.value = (state.mental.value - 5).clamp(0, 100);
        state.reputation = (state.reputation - 2).clamp(0, 100);
      }
    }

    // Economía semanal
    if (CalendarSystem.weekdayName(state.day) == 'Domingo') {
      processWeeklyEconomy();
    }

    saveState();

    return event;
  }

  void processWeeklyEconomy() {
    // Pago de salario
    double salary = 400.0;
    if (state.reputation > 70) salary += 50;
    if (state.physical.value > 80 && state.mental.value > 80) salary += 40;
    state.money += salary;

    // Deducciones
    const double rent = 300.0;
    const double food = 100.0;
    const double transport = 50.0;
    final double totalDeductions = rent + food + transport;
    state.money -= totalDeductions;
  }

  void rewindOneDay() {
    // Demo: retroceso simple con penalización
    state.day = (state.day - 1).clamp(1, 99999);
    state.mental.value = (state.mental.value - 4).clamp(0, 100);
    state.physical.value = (state.physical.value - 2).clamp(0, 100);
  }

  void addGoal(Goal goal) {
    state.goals.add(goal);
  }

  void updateGoalProgress(String id, double newProgress) {
    final goal = state.goals.firstWhere((g) => g.id == id);
    final wasCompleted = goal.completed;
    goal.progress = newProgress.clamp(0.0, 1.0);
    if (goal.progress >= 1.0 && !wasCompleted) {
      goal.completed = true;
      state.mental.value = (state.mental.value + 10).clamp(0, 100);
      state.reputation = (state.reputation + 5).clamp(0, 100);
    }
  }

  void saveState() {
    lifeBox.put('day', state.day);
    lifeBox.put('money', state.money);
    lifeBox.put('physical', state.physical.value);
    lifeBox.put('mental', state.mental.value);
    lifeBox.put('reputation', state.reputation);
    lifeBox.put('goals', state.goals.map((g) => g.toJson()).toList());
    lifeBox.put('relationships', state.relations);
    lifeBox.put('currentDay', timeKeeper.currentDay);
    lifeBox.put('hour', timeKeeper.hour);
    lifeBox.put('minutes', timeKeeper.minutes);
    lifeBox.put('narrativeHistory', narrativeHistory);
  }

  void loadState() {
    state.day = lifeBox.get('day', defaultValue: 1);
    state.money = lifeBox.get('money', defaultValue: 1000.0);
    state.physical.value = lifeBox.get('physical', defaultValue: 100.0);
    state.mental.value = lifeBox.get('mental', defaultValue: 100.0);
    state.reputation = lifeBox.get('reputation', defaultValue: 50);
    state.goals = (lifeBox.get('goals', defaultValue: []) as List).map((g) => Goal.fromJson(g)).toList();
    state.relations = Map<String, double>.from(lifeBox.get('relationships', defaultValue: {}));
    timeKeeper.currentDay = lifeBox.get('currentDay', defaultValue: 1);
    timeKeeper.hour = lifeBox.get('hour', defaultValue: 6);
    timeKeeper.minutes = lifeBox.get('minutes', defaultValue: 0);
    narrativeHistory = List<String>.from(lifeBox.get('narrativeHistory', defaultValue: []));
  }

  String exportToJSON() {
    return '''
{
  "day": ${state.day},
  "money": ${state.money},
  "physical": ${state.physical.value},
  "mental": ${state.mental.value},
  "reputation": ${state.reputation},
  "goals": ${state.goals.map((g) => g.toJson()).toList()},
  "relationships": ${state.relations}
}
''';
  }
}