import '../models/module.dart';

class HealthModule extends Module {
  double physical = 100.0;
  double mental = 100.0;
  List<String> conditions = [];

  @override
  void update() {
    // Simple decay
    physical -= 2;
    mental -= 1;
    if (physical < 50) conditions.add('fatigue');
    value = (physical + mental) / 2;
    history.add(value);
  }
}