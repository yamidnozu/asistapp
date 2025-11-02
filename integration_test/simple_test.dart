// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:asistapp/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Pruebas E2E Simplificadas', () {
    
    // Limpiar estado de autenticación antes de cada test
    setUp(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('accessToken');
      await prefs.remove('refreshToken');
      await prefs.remove('user');
      await prefs.remove('selectedInstitutionId');
      print('\n[SETUP] Estado de autenticación limpiado');
    });

    testWidgets('Prueba básica de carga de aplicación', (WidgetTester tester) async {
      print('\n=== PRUEBA: Carga de Aplicación ===');
      
      // Iniciar la aplicación
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      print('✓ Aplicación cargada');

      // Verificar que estamos en la pantalla de login
      final loginTitle = find.byKey(const Key('appTitle'));
      
      if (loginTitle.evaluate().isEmpty) {
        print('✗ No se encontró la pantalla de login');
        print('Buscando alternativas...');
        
        // Buscar por texto
        final byText = find.text('AsistApp');
        if (byText.evaluate().isNotEmpty) {
          print('✓ Encontrado por texto: AsistApp');
        } else {
          print('✗ No se encontró AsistApp');
        }
      } else {
        print('✓ Pantalla de login encontrada');
      }

      // Buscar campos de email por tipo
      final textFormFields = find.byType(TextFormField);
      print('TextFormFields encontrados: ${textFormFields.evaluate().length}');

      if (textFormFields.evaluate().isNotEmpty) {
        print('✓ Se encontraron campos de entrada de texto');
        
        // Intentar login usando byType
        final fields = find.byType(TextFormField);
        
        if (fields.evaluate().length >= 2) {
          // Asumir que el primer campo es email y el segundo es contraseña
          print('Ingresando credenciales...');
          
          await tester.enterText(fields.at(0), 'superadmin@asistapp.com');
          await tester.enterText(fields.at(1), 'Admin123!');
          await tester.pumpAndSettle();

          // Buscar y presionar botón de login
          final buttons = find.byType(ElevatedButton);
          if (buttons.evaluate().isNotEmpty) {
            await tester.tap(buttons.first);
            await tester.pumpAndSettle(const Duration(seconds: 5));

            print('✓ Intento de login realizado');
            
            // Verificar si se llegó al dashboard
            final institutionText = find.text('Instituciones');
            if (institutionText.evaluate().isNotEmpty) {
              print('✓ ¡Login exitoso! Se cargó el dashboard');
            } else {
              print('✗ No se cargó el dashboard');
              print('Verificar credenciales en la base de datos');
            }
          }
        }
      } else {
        print('✗ No se encontraron campos de entrada');
      }

      print('=== FIN DE PRUEBA ===\n');
    });

    testWidgets('Prueba de diagnóstico de widgets', (WidgetTester tester) async {
      print('\n=== DIAGNÓSTICO: Estructura de Widgets ===');
      
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      print('Buscando widgets principales...');
      
      // Buscar por tipo
      final scaffolds = find.byType(Scaffold);
      print('Scaffolds: ${scaffolds.evaluate().length}');

      final textFields = find.byType(TextFormField);
      print('TextFormFields: ${textFields.evaluate().length}');

      final buttons = find.byType(ElevatedButton);
      print('ElevatedButtons: ${buttons.evaluate().length}');

      final outlineButtons = find.byType(OutlinedButton);
      print('OutlinedButtons: ${outlineButtons.evaluate().length}');

      // Buscar por texto comunes
      final textWidgets = find.byType(Text);
      print('Text widgets: ${textWidgets.evaluate().length}');

      // Listar algunos textos encontrados
      print('\nTextos encontrados (primeros 5):');
      var count = 0;
      for (var element in textWidgets.evaluate()) {
        if (count >= 5) break;
        final widget = element.widget as Text;
        if (widget.data != null) {
          print('  - ${widget.data}');
          count++;
        }
      }

      print('=== FIN DE DIAGNÓSTICO ===\n');
    });
  });
}
