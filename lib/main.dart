import 'package:flutter/widgets.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WidgetsApp(
      title: 'Nueva App',
      color: const Color(0xFF000000),
      home: Container(
        color: const Color(0xFF000000),
        child: const Center(
          child: Text(
            'Nueva aplicación',
            style: TextStyle(color: Color(0xFFFFFFFF)),
          ),
        ),
      ),
    );
  }
}