import 'package:flutter/material.dart';
import 'package:asistapp/widgets/test_multi_hora_widget.dart';

class TestMultiHoraScreen extends StatelessWidget {
  const TestMultiHoraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prueba Multi-Hora'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: TestMultiHoraWidget(),
      ),
    );
  }
}