import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../controllers/life_controller.dart';
import '../controllers/gyroscope_controller.dart';
import 'planner_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late LifeController lifeController;
  late GyroscopeController gyroController;

  @override
  void initState() {
    super.initState();
    lifeController = LifeController();
    gyroController = GyroscopeController(lifeController);
    gyroController.startListening();
  }

  @override
  void dispose() {
    gyroController.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Día ${lifeController.currentDay}')),
      body: Column(
        children: [
          Text('Dinero: \$${lifeController.moneyModule.value.toStringAsFixed(2)}').animate().fadeIn(duration: 500.ms),
          Text('Salud Física: ${lifeController.healthModule.physical}'),
          Text('Salud Mental: ${lifeController.healthModule.mental}'),
          Text('Relaciones: ${lifeController.relationshipModule.value}'),
          lifeController.activeEvents.isNotEmpty ? Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text(lifeController.activeEvents.first.description),
                  Row(
                    children: lifeController.activeEvents.first.options.map((option) => ElevatedButton(
                      onPressed: () => option.effect(),
                      child: Text(option.label),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ) : const SizedBox(),
          ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PlannerScreen()));
            },
            child: const Text('Planear Día Siguiente'),
          ),
        ],
      ),
    );
  }
}