import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:asistapp/providers/auth_provider.dart';
import 'package:asistapp/providers/horario_provider.dart';
import 'package:asistapp/providers/grupo_provider.dart';
import 'package:asistapp/providers/materia_provider.dart';
import 'package:asistapp/providers/user_provider.dart';
import '../../services/academic_service.dart' as academic_service;

class TestMultiHoraWidget extends StatefulWidget {
  const TestMultiHoraWidget({super.key});

  @override
  State<TestMultiHoraWidget> createState() => _TestMultiHoraWidgetState();
}

class _TestMultiHoraWidgetState extends State<TestMultiHoraWidget> {
  String _testResult = 'Esperando resultados...';

  @override
  void initState() {
    super.initState();
    _runTests();
  }

  Future<void> _runTests() async {
    setState(() => _testResult = 'Ejecutando pruebas...\n');

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final horarioProvider = Provider.of<HorarioProvider>(context, listen: false);
      final grupoProvider = Provider.of<GrupoProvider>(context, listen: false);
      final materiaProvider = Provider.of<MateriaProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Verificar que tenemos datos básicos
      setState(() => _testResult += '✓ Verificando providers...\n');

      if (authProvider.accessToken == null) {
        setState(() => _testResult += '❌ No hay token de autenticación\n');
        return;
      }

      if (grupoProvider.grupos.isEmpty) {
        setState(() => _testResult += '❌ No hay grupos disponibles\n');
        return;
      }

      if (materiaProvider.materias.isEmpty) {
        setState(() => _testResult += '❌ No hay materias disponibles\n');
        return;
      }

      setState(() => _testResult += '✓ Providers configurados correctamente\n');

      // Seleccionar primer grupo disponible
      final testGrupo = grupoProvider.grupos.first;
      setState(() => _testResult += '✓ Grupo de prueba: ${testGrupo.nombre}\n');

      // Cargar horarios del grupo
      await horarioProvider.loadHorariosByGrupo(authProvider.accessToken!, testGrupo.id);
      setState(() => _testResult += '✓ Horarios cargados: ${horarioProvider.horarios.length}\n');

      // Verificar que podemos crear una clase de 2 horas
      final testMateria = materiaProvider.materias.first;
      final testProfesor = userProvider.professors.isNotEmpty ? userProvider.professors.first : null;

      setState(() => _testResult += '✓ Preparando creación de clase multi-hora...\n');

      // Intentar crear clase de 2 horas (10:00-12:00)
      final success = await horarioProvider.createHorario(
        authProvider.accessToken!,
        academic_service.CreateHorarioRequest(
          periodoId: testGrupo.periodoId,
          grupoId: testGrupo.id,
          materiaId: testMateria.id,
          profesorId: testProfesor?.id,
          diaSemana: 1, // Lunes
          horaInicio: '10:00',
          horaFin: '12:00',
        ),
      );

      if (success) {
        setState(() => _testResult += '✅ Clase multi-hora creada exitosamente\n');

        // Recargar horarios para verificar visualización
        await horarioProvider.loadHorariosByGrupo(authProvider.accessToken!, testGrupo.id);
        final horariosDespues = horarioProvider.horarios;

        // Buscar la clase que acabamos de crear
        final claseCreada = horariosDespues.where(
          (h) => h.materiaId == testMateria.id && h.horaInicio == '10:00'
        ).firstOrNull;

        if (claseCreada != null) {
          setState(() => _testResult += '✅ Clase encontrada en la lista\n');
          setState(() => _testResult += '   - Duración: ${claseCreada.horaInicio} - ${claseCreada.horaFin}\n');
          setState(() => _testResult += '   - Altura esperada: 120px (2 horas)\n');
        } else {
          setState(() => _testResult += '❌ Clase no encontrada después de crear\n');
        }
      } else {
        final error = horarioProvider.errorMessage ?? 'Error desconocido';
        setState(() => _testResult += '❌ Error al crear clase: $error\n');

        // Si es conflicto, es esperado (puede haber clases existentes)
        if (error.contains('conflicto') || error.contains('Conflict')) {
          setState(() => _testResult += 'ℹ️ Conflicto detectado (esperado si ya hay clases)\n');
        }
      }

      setState(() => _testResult += '\n🎉 Pruebas completadas\n');

    } catch (e) {
      setState(() => _testResult += '❌ Error durante las pruebas: $e\n');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Multi-Hora'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Resultados de Pruebas Multi-Hora',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  _testResult,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _runTests,
                child: const Text('Ejecutar Pruebas Nuevamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}