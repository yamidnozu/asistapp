import 'package:hive/hive.dart';
import '../models/event.dart';
import '../models/project.dart';
import 'money_module.dart';
import 'health_module.dart';
import 'relationship_module.dart';
import 'reputation_module.dart';
import 'event_engine.dart';

class LifeController {
  int currentDay = 1;
  late Box lifeStateBox;
  late MoneyModule moneyModule;
  late HealthModule healthModule;
  late RelationshipModule relationshipModule;
  late ReputationModule reputationModule;
  late EventEngine eventEngine;
  List<Project> projects = [];
  List<Event> activeEvents = [];

  LifeController() {
    lifeStateBox = Hive.box('life_state');
    moneyModule = MoneyModule();
    healthModule = HealthModule();
    relationshipModule = RelationshipModule();
    reputationModule = ReputationModule();
    eventEngine = EventEngine();
    loadState();
  }

  void nextDay() {
    currentDay++;
    applyDailyChanges();
    generateEvents();
    saveState();
  }

  void rewindDay() {
    if (currentDay > 1) {
      currentDay--;
      // Apply rewind consequences
      healthModule.mental -= 10;
      healthModule.physical -= 5;
      loadState();
    }
  }

  void applyDailyChanges() {
    moneyModule.update();
    healthModule.update();
    relationshipModule.update();
    reputationModule.update();
    for (var project in projects) {
      project.progressDay();
    }
  }

  void generateEvents() {
    activeEvents.addAll(eventEngine.generateEvents());
  }

  void saveState() {
    lifeStateBox.put('currentDay', currentDay);
    lifeStateBox.put('money', moneyModule.value);
    lifeStateBox.put('health_physical', healthModule.physical);
    lifeStateBox.put('health_mental', healthModule.mental);
    // Save other states...
  }

  void loadState() {
    currentDay = lifeStateBox.get('currentDay', defaultValue: 1);
    moneyModule.value = lifeStateBox.get('money', defaultValue: 1000.0);
    healthModule.physical = lifeStateBox.get('health_physical', defaultValue: 100.0);
    healthModule.mental = lifeStateBox.get('health_mental', defaultValue: 100.0);
    // Load other states...
  }
}