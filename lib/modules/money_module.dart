import '../data/models.dart';
import 'dart:math';

class MoneyModule {
  void applyDaily(PlayerState s) {
    // gastos base
    s.money -= 15; // comida/transporte simple

    // salario si trabajó
    final worked = s.projects.any((p) => p.name == '_WORK_FLAG_'); // simple flag
    if (worked) s.money += 60;

    // inversiones (retornos + ruido por riesgo)
    for (final inv in s.investments.where((i) => i.active)) {
      final vol = (Random().nextDouble() - 0.5) * inv.risk * 0.02; // +-1% * riesgo/2
      final daily = inv.principal * (inv.dailyReturn + vol);
      s.money += daily;
      inv.principal += daily;
      if (inv.principal <= 50) inv.active = false;
    }
  }
}