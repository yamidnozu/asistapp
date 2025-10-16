import 'goal.dart';

class Stat {
  double value; // 0..100
  double trend; // -1..1
  List<double> history; // últimos 30
  Stat({this.value = 50, this.trend = 0, List<double>? history})
      : history = history ?? <double>[];
}

enum TimeBlock { morning, afternoon, night }

class PlanEntry {
  final TimeBlock block;
  final String action; // "work", "rest", "social", "invest", "project:<id>"
  PlanEntry(this.block, this.action);
}

class Investment {
  String id;
  String name;
  double principal;
  double dailyReturn; // e.g., 0.001 = 0.1% diario
  double risk;        // 0..1
  bool active;
  Investment({
    required this.id,
    required this.name,
    required this.principal,
    required this.dailyReturn,
    required this.risk,
    this.active = true,
  });
}

class Project {
  String id;
  String name;
  double progress; // 0..1
  int stage; // 0 idea, 1 dev, 2 launch, 3 mature
  double requiredFunds;
  Project({
    required this.id,
    required this.name,
    this.progress = 0,
    this.stage = 0,
    this.requiredFunds = 0,
  });
}

class Relationship {
  String name;
  double level; // 0..100
  Relationship(this.name, this.level);
}

class DayState {
  int day;
  List<PlanEntry> plan;
  DayState(this.day, this.plan);
}

class GameTime {
  final int hour;
  final int minute;
  const GameTime({required this.hour, required this.minute});
  String format() => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

class PlayerState {
  int day;
  double money;
  Stat physical;
  Stat mental;
  int reputation;
  Map<String, double> relations;
  List<Investment> investments;
  List<Project> projects;
  List<Goal> goals;
  PlayerState({
    this.day = 1,
    this.money = 500,
    Stat? physical,
    Stat? mental,
    this.reputation = 50,
    Map<String, double>? relations,
    List<Investment>? investments,
    List<Project>? projects,
    List<Goal>? goals,
  })  : physical = physical ?? Stat(value: 70),
        mental = mental ?? Stat(value: 70),
        relations = relations ?? {},
        investments = investments ?? [],
        projects = projects ?? [],
        goals = goals ?? [];
}