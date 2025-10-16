import 'package:flutter/material.dart';
import '../controllers/life_controller.dart';

class SummaryScreen extends StatelessWidget {
  final LifeController lifeController;

  const SummaryScreen({super.key, required this.lifeController});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resumen Diario')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cambios en Dinero: +\$${lifeController.moneyModule.salary - lifeController.moneyModule.expenses}'),
            Text('Salud Física: ${lifeController.healthModule.physical}'),
            Text('Salud Mental: ${lifeController.healthModule.mental}'),
            const Text('“Dormiste mal y bajó tu energía.”'), // Placeholder
            ElevatedButton(
              onPressed: () {
                lifeController.nextDay();
                Navigator.pop(context);
              },
              child: const Text('Continuar al Siguiente Día'),
            ),
          ],
        ),
      ),
    );
  }
}