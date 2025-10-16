import 'package:flutter/material.dart';
import '../controllers/life_controller.dart';
import 'summary_screen.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  _PlannerScreenState createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  List<String> morning = [];
  List<String> afternoon = [];
  List<String> evening = [];
  List<String> activities = ['Trabajar', 'Ejercitarse', 'Descansar', 'Invertir', 'Socializar', 'Proyectos'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Planificador Diario')),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: buildTimeBlock('Mañana', morning)),
                Expanded(child: buildTimeBlock('Tarde', afternoon)),
                Expanded(child: buildTimeBlock('Noche', evening)),
              ],
            ),
          ),
          Wrap(
            children: activities.map((activity) => Draggable<String>(
              data: activity,
              child: Card(child: Padding(padding: const EdgeInsets.all(8.0), child: Text(activity))),
              feedback: Card(child: Padding(padding: const EdgeInsets.all(8.0), child: Text(activity))),
            )).toList(),
          ),
          ElevatedButton(onPressed: () {
            // Simulate next day
            Navigator.push(context, MaterialPageRoute(builder: (_) => SummaryScreen(lifeController: LifeController())));
          }, child: const Text('Guardar Plan')),
        ],
      ),
    );
  }

  Widget buildTimeBlock(String title, List<String> block) {
    return DragTarget<String>(
      onAccept: (activity) {
        setState(() {
          block.add(activity);
        });
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          margin: const EdgeInsets.all(8.0),
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(border: Border.all()),
          child: Column(
            children: [
              Text(title),
              ...block.map((act) => Text(act)).toList(),
            ],
          ),
        );
      },
    );
  }
}