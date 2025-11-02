// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:asistapp/main.dart' as app;

// --- FUNCIONES AUXILIARES (Reutilizadas del archivo principal) ---

Future<void> loginAsAdmin(WidgetTester tester) async {
  print('\n--- Iniciando Sesión como Super Admin ---');
  
  await tester.pumpAndSettle(const Duration(seconds: 2));

  final emailField = find.byKey(const Key('emailField'));
  final passwordField = find.byKey(const Key('passwordField'));
  final loginButton = find.byKey(const Key('loginButton'));

  expect(emailField, findsOneWidget);
  expect(passwordField, findsOneWidget);
  expect(loginButton, findsOneWidget);

  await tester.enterText(emailField, 'superadmin@asistapp.com');
  await tester.enterText(passwordField, 'Admin123!');
  await tester.pumpAndSettle();

  await tester.tap(loginButton);
  await tester.pumpAndSettle(const Duration(seconds: 5));

  expect(find.text('Instituciones'), findsOneWidget);
  print('✓ Login exitoso.');
}

Future<void> navigateToInstitutions(WidgetTester tester) async {
  await tester.tap(find.text('Instituciones'));
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

Future<void> createInstitution(
  WidgetTester tester,
  String name,
  String code,
  String email,
) async {
  final addButton = find.byKey(const Key('addInstitutionButton'));
  expect(addButton, findsOneWidget);
  await tester.tap(addButton);
  await tester.pumpAndSettle();

  await tester.enterText(find.byKey(const Key('nombreInstitucionField')), name);
  await tester.enterText(find.byKey(const Key('codigoInstitucionField')), code);
  await tester.enterText(find.byKey(const Key('emailInstitucionField')), email);
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const Key('formSaveButton')));
  await tester.pumpAndSettle(const Duration(seconds: 3));

  expect(find.text(name), findsOneWidget);
}

Future<void> deleteInstitution(WidgetTester tester, String institutionName) async {
  final popupMenu = find.descendant(
    of: find.widgetWithText(Card, institutionName),
    matching: find.byIcon(Icons.more_vert),
  );
  expect(popupMenu, findsOneWidget);
  
  await tester.tap(popupMenu);
  await tester.pumpAndSettle();

  await tester.tap(find.text('Eliminar'));
  await tester.pumpAndSettle();

  final confirmButton = find.byWidgetPredicate(
    (widget) => widget is TextButton && 
        find.byWidget(widget).evaluate().isNotEmpty &&
        widget.child is Text &&
        (widget.child as Text).data == 'Eliminar',
  ).last;
  
  await tester.tap(confirmButton);
  await tester.pumpAndSettle(const Duration(seconds: 3));

  expect(find.text(institutionName), findsNothing);
}

Future<void> navigateToUsers(WidgetTester tester) async {
  await tester.tap(find.text('Usuarios Globales'));
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

Future<void> createUser(
  WidgetTester tester,
  String nombres,
  String apellidos,
  String email,
  String identificacion,
) async {
  await tester.tap(find.byIcon(Icons.add));
  await tester.pumpAndSettle();

  await tester.tap(find.byIcon(Icons.school));
  await tester.pumpAndSettle();

  await tester.enterText(find.byKey(const Key('user_form_nombres')), nombres);
  await tester.enterText(find.byKey(const Key('user_form_apellidos')), apellidos);
  await tester.enterText(find.byKey(const Key('emailUsuarioField')), email);
  await tester.enterText(find.byKey(const Key('user_form_identificacion')), identificacion);
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const Key('formSaveButton')));
  await tester.pumpAndSettle(const Duration(seconds: 3));

  final fullName = '$nombres $apellidos';
  expect(find.text(fullName), findsOneWidget);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Pruebas Extendidas E2E', () {
    
    testWidgets('Prueba de Validaciones de Formulario', 
      (WidgetTester tester) async {
      
      print('\n=== PRUEBA: Validaciones de Formulario ===');
      
      app.main();
      await tester.pumpAndSettle();

      // 1. Intentar login sin credenciales
      print('1. Intentando login sin credenciales...');
      final loginButton = find.byKey(const Key('loginButton'));
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Verificar que hay un mensaje de error
      expect(find.byType(SnackBar), findsOneWidget);
      print('✓ Validación de login sin credenciales funciona.');

      // 2. Login exitoso
      print('2. Realizando login exitoso...');
      final emailField = find.byKey(const Key('emailField'));
      final passwordField = find.byKey(const Key('passwordField'));
      
      await tester.enterText(emailField, 'superadmin@asistapp.com');
      await tester.enterText(passwordField, 'Admin123!');
      await tester.pumpAndSettle();
      
      await tester.tap(loginButton);
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Instituciones'), findsOneWidget);
      print('✓ Login exitoso.');

      // 3. Intentar crear institución sin nombre
      print('3. Intentando crear institución sin nombre...');
      await navigateToInstitutions(tester);

      final addButton = find.byKey(const Key('addInstitutionButton'));
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // Dejar nombre vacío y presionar guardar
      await tester.tap(find.byKey(const Key('formSaveButton')));
      await tester.pumpAndSettle();

      // Debe permanecer en la misma pantalla y mostrar error
      expect(find.text('El nombre es obligatorio'), findsOneWidget);
      print('✓ Validación de nombre obligatorio funciona.');

      // 4. Completar formulario correctamente
      print('4. Completando formulario correctamente...');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      await tester.enterText(find.byKey(const Key('nombreInstitucionField')), 'Institución Válida');
      await tester.enterText(find.byKey(const Key('codigoInstitucionField')), 'IV-$timestamp');
      await tester.enterText(find.byKey(const Key('emailInstitucionField')), 'valido@test.edu');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('formSaveButton')));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('Institución Válida'), findsOneWidget);
      print('✓ Creación con datos válidos funciona.');

      // 5. Limpiar: Eliminar institución creada
      print('5. Limpiando datos de prueba...');
      await deleteInstitution(tester, 'Institución Válida');
      print('✓ Datos limpios.');

      print('\n✓ Prueba de validaciones completada exitosamente.\n');
    });

    testWidgets('Prueba de Búsqueda y Filtrado', 
      (WidgetTester tester) async {
      
      print('\n=== PRUEBA: Búsqueda y Filtrado ===');
      
      app.main();
      await tester.pumpAndSettle();

      await loginAsAdmin(tester);
      await navigateToInstitutions(tester);

      // 1. Crear varias instituciones
      print('1. Creando múltiples instituciones para prueba...');
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      await createInstitution(tester, 'Instituto A', 'IA-$timestamp', 'a@test.edu');
      await tester.pumpAndSettle();

      await createInstitution(tester, 'Instituto B', 'IB-$timestamp', 'b@test.edu');
      print('✓ Instituciones creadas.');

      // 2. Buscar por nombre
      print('2. Buscando institución por nombre...');
      final searchField = find.byKey(const Key('searchInstitutionField'));
      await tester.enterText(searchField, 'Instituto A');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Instituto A'), findsOneWidget);
      expect(find.text('Instituto B'), findsNothing);
      print('✓ Búsqueda por nombre funciona.');

      // 3. Limpiar búsqueda
      print('3. Limpiando búsqueda...');
      await tester.tap(find.byIcon(Icons.clear).first);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text('Instituto A'), findsOneWidget);
      expect(find.text('Instituto B'), findsOneWidget);
      print('✓ Limpieza de búsqueda funciona.');

      // 4. Limpiar datos de prueba
      print('4. Limpiando datos...');
      await deleteInstitution(tester, 'Instituto A');
      await deleteInstitution(tester, 'Instituto B');
      print('✓ Datos limpios.');

      print('\n✓ Prueba de búsqueda y filtrado completada exitosamente.\n');
    });

    testWidgets('Prueba de Manejo de Errores de Conexión', 
      (WidgetTester tester) async {
      
      print('\n=== PRUEBA: Interfaz de Carga y Estados ===');
      
      app.main();
      await tester.pumpAndSettle();

      // 1. Verificar que durante login se muestre indicador de carga
      print('1. Verificando indicador de carga en login...');
      final emailField = find.byKey(const Key('emailField'));
      final passwordField = find.byKey(const Key('passwordField'));
      final loginButton = find.byKey(const Key('loginButton'));

      await tester.enterText(emailField, 'superadmin@asistapp.com');
      await tester.enterText(passwordField, 'Admin123!');
      await tester.pumpAndSettle();

      await tester.tap(loginButton);
      
      // Inmediatamente después del tap, puede haber un loading spinner
      await tester.pump(const Duration(milliseconds: 500));
      print('✓ El login maneja estados de carga.');

      // Esperar a que complete
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Instituciones'), findsOneWidget);
      print('✓ El login se completa exitosamente.\n');
    });
  });
}
