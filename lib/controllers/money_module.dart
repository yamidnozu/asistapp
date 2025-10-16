import '../models/module.dart';
import '../models/investment.dart';

class MoneyModule extends Module {
  double salary = 2000.0;
  double expenses = 1500.0;
  List<Investment> investments = [];

  @override
  void update() {
    value += salary - expenses;
    for (var investment in investments) {
      investment.update();
      value += investment.returns;
    }
    history.add(value);
  }
}