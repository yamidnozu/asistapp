import '../models/module.dart';

class ReputationModule extends Module {
  @override
  void update() {
    // Placeholder
    value += 0.1;
    history.add(value);
  }
}