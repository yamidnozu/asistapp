import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'controllers/life_controller.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('life_state');
  runApp(const ChronoLifeApp());
}

class ChronoLifeApp extends StatelessWidget {
  const ChronoLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChronoLife: Emergent Reality',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const DashboardScreen(),
    );
  }
}