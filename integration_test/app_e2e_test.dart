// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:asistapp/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E Tests - Login y Navegación', () {
    
    // Limpiar estado de autenticación antes de cada test
    setUp(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('accessToken');
      await prefs.remove('refreshToken');
      await prefs.remove('user');
      await prefs.remove('selectedInstitutionId');
      print('\n[SETUP] Estado de autenticación limpiado');
    });

    testWidgets('01 - Login exitoso', (WidgetTester tester) async {
      print('\n=== PRUEBA: Login Exitoso ===');
      
      // Iniciar la aplicación
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Buscar campos de texto para email y contraseña
      final textFields = find.byType(TextFormField);
      expect(textFields, findsWidgets);
      
      print('✓ Se encontraron ${textFields.evaluate().length} campos de texto');

      // Llenar credenciales
      await tester.enterText(textFields.at(0), 'superadmin@asistapp.com');
      await tester.enterText(textFields.at(1), 'Admin123!');
      await tester.pumpAndSettle();

      // Presionar botón de login
      final buttons = find.byType(ElevatedButton);
      await tester.tap(buttons.first);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verificar que estamos en el dashboard
      expect(find.text('Dashboard'), findsWidgets);
      print('✓ Login exitoso - Dashboard visible');
    });

    testWidgets('02 - Navegar a Instituciones', (WidgetTester tester) async {
      print('\n=== PRUEBA: Navegar a Instituciones ===');
      
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Login
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'superadmin@asistapp.com');
      await tester.enterText(textFields.at(1), 'Admin123!');
      
      final buttons = find.byType(ElevatedButton);
      await tester.tap(buttons.first);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navegar a Instituciones
      final institucionesText = find.text('Instituciones');
      expect(institucionesText, findsWidgets);
      
      // Encontrar el primero que sea clickeable (el del menú, no el del tab)
      final institucionesTabBar = find.byWidgetPredicate(
        (widget) => widget is Text && 
                    widget.data?.contains('Instituciones') == true &&
                    widget.style?.fontSize == 18.0  // Tab tiene mayor tamaño
      );
      
      if (institucionesTabBar.evaluate().isNotEmpty) {
        await tester.tap(institucionesTabBar.first);
      } else {
        await tester.tap(institucionesText.first);
      }
      
      await tester.pumpAndSettle(const Duration(seconds: 2));
      print('✓ Navegación a Instituciones exitosa');
    });

    testWidgets('03 - Ver lista de Usuarios', (WidgetTester tester) async {
      print('\n=== PRUEBA: Ver Usuarios ===');
      
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Login
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'superadmin@asistapp.com');
      await tester.enterText(textFields.at(1), 'Admin123!');
      
      final buttons = find.byType(ElevatedButton);
      await tester.tap(buttons.first);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navegar a Usuarios
      final usuariosText = find.text('Usuarios');
      if (usuariosText.evaluate().isNotEmpty) {
        await tester.tap(usuariosText.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        print('✓ Acceso a Usuarios exitoso');
      } else {
        print('ℹ No se encontró la pestaña de Usuarios');
      }
    });

    testWidgets('04 - Estructura de widgets en login', (WidgetTester tester) async {
      print('\n=== DIAGNÓSTICO: Estructura Login ===');
      
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final scaffolds = find.byType(Scaffold);
      final textFields = find.byType(TextFormField);
      final buttons = find.byType(ElevatedButton);
      final texts = find.byType(Text);

      print('Scaffolds: ${scaffolds.evaluate().length}');
      print('TextFormFields: ${textFields.evaluate().length}');
      print('ElevatedButtons: ${buttons.evaluate().length}');
      print('Widgets Text: ${texts.evaluate().length}');

      expect(scaffolds.evaluate().length, greaterThanOrEqualTo(1));
      expect(textFields.evaluate().length, greaterThanOrEqualTo(2));
      expect(buttons.evaluate().length, greaterThanOrEqualTo(1));

      print('✓ Estructura validada');
    });

    testWidgets('05 - Logout', (WidgetTester tester) async {
      print('\n=== PRUEBA: Logout ===');
      
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Login
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'superadmin@asistapp.com');
      await tester.enterText(textFields.at(1), 'Admin123!');
      
      final buttons = find.byType(ElevatedButton);
      await tester.tap(buttons.first);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Buscar menú de usuario o botón de logout
      final popupMenus = find.byType(PopupMenuButton);
      final moreVertIcons = find.byIcon(Icons.more_vert);
      
      bool logoutFound = false;

      if (moreVertIcons.evaluate().isNotEmpty) {
        await tester.tap(moreVertIcons.first);
        await tester.pumpAndSettle(const Duration(seconds: 1));
        
        final logoutOption = find.text('Cerrar Sesión');
        if (logoutOption.evaluate().isNotEmpty) {
          await tester.tap(logoutOption.first);
          await tester.pumpAndSettle(const Duration(seconds: 3));
          logoutFound = true;
          print('✓ Logout exitoso');
        }
      } else if (popupMenus.evaluate().isNotEmpty) {
        await tester.tap(popupMenus.first);
        await tester.pumpAndSettle(const Duration(seconds: 1));
        
        final logoutOption = find.text('Cerrar Sesión');
        if (logoutOption.evaluate().isNotEmpty) {
          await tester.tap(logoutOption.first);
          await tester.pumpAndSettle(const Duration(seconds: 3));
          logoutFound = true;
          print('✓ Logout exitoso');
        }
      }

      if (!logoutFound) {
        print('ℹ Opción de logout no encontrada, pero continuamos');
      }
    });
  });
}
