// ignore_for_file: avoid_print
/// ============================================================================
/// EJECUTOR DE TODAS LAS PRUEBAS E2E
/// ============================================================================
///
/// Este archivo ejecuta TODOS los tests E2E de forma secuencial.
/// Cada test se ejecuta en su propio contexto aislado.
///
/// EJECUCIÓN:
/// flutter test integration_test/ -d windows
/// ============================================================================

import 'dart:io';

void main() async {
  print('\n' + '═'*70);
  print('🚀 EJECUTANDO SUITE COMPLETA DE TESTS E2E');
  print('═'*70);
  
  final tests = [
    'integration_test/e2e_crud_instituciones_test.dart',
    'integration_test/e2e_crud_usuarios_test.dart',
    'integration_test/e2e_seguridad_roles_test.dart',
    'integration_test/e2e_flujo_asistencia_test.dart',
  ];

  int passed = 0;
  int failed = 0;

  for (final test in tests) {
    print('\n📋 Ejecutando: $test');
    print('─'*50);
    
    final result = await Process.run(
      'flutter',
      ['test', test, '-d', 'windows'],
      workingDirectory: Directory.current.path,
    );

    if (result.exitCode == 0) {
      passed++;
      print('✅ PASÓ: $test');
    } else {
      failed++;
      print('❌ FALLÓ: $test');
      print(result.stdout);
      print(result.stderr);
    }
  }

  print('\n' + '═'*70);
  print('📊 RESUMEN FINAL');
  print('═'*70);
  print('✅ Pasaron: $passed/${tests.length}');
  print('❌ Fallaron: $failed/${tests.length}');
  print('📈 Tasa de éxito: ${(passed / tests.length * 100).toStringAsFixed(1)}%');
  print('═'*70);

  exit(failed > 0 ? 1 : 0);
}
