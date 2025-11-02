// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:asistapp/main.dart' as app;

// --- FUNCIONES AUXILIARES ---

/// Realiza el login como Super Admin
Future<void> loginAsAdmin(WidgetTester tester) async {
  print('\n--- PASO 1: Iniciando Sesión como Super Admin ---');
  
  // Esperar a que la app se cargue completamente
  await tester.pumpAndSettle(const Duration(seconds: 3));

  // Buscar campos usando byType (más robusto que Keys)
  final emailField = find.byType(TextFormField).at(0);
  final passwordField = find.byType(TextFormField).at(1);
  final loginButton = find.byType(ElevatedButton).first;

  print('✓ Campos de login encontrados');

  await tester.enterText(emailField, 'superadmin@asistapp.com');
  await tester.enterText(passwordField, 'Admin123!');
  await tester.pumpAndSettle();

  await tester.tap(loginButton);
  await tester.pumpAndSettle(const Duration(seconds: 5));

  // Verificar que hemos llegado al Dashboard
  // Verificar que se cargó el dashboard (puede haber múltiples widgets con "Instituciones")
  expect(find.text('Instituciones'), findsWidgets, reason: 'No se cargó el dashboard después del login');
  print('✓ Login como Super Admin exitoso.');
}

/// Navega a la sección de Instituciones
Future<void> navigateToInstitutions(WidgetTester tester) async {
  print('Navegando a Instituciones...');
  await tester.tap(find.text('Instituciones'));
  await tester.pumpAndSettle(const Duration(seconds: 2));
  print('✓ Navegación a Instituciones completada.');
}

/// Crea una nueva institución
Future<void> createInstitution(
  WidgetTester tester,
  String name,
  String code,
  String email,
) async {
  print('Creando institución: $name...');
  
  // Encontrar y presionar el botón de agregar (FloatingActionButton)
  final addButton = find.byType(FloatingActionButton);
  if (addButton.evaluate().isNotEmpty) {
    await tester.tap(addButton.first);
  } else {
    // Alternativa: buscar por icono
    final addByIcon = find.byIcon(Icons.add);
    expect(addByIcon, findsWidgets, reason: 'No se encontró el botón de agregar');
    await tester.tap(addByIcon.first);
  }
  
  await tester.pumpAndSettle(const Duration(seconds: 1));

  // Rellenar el formulario - buscar TextFormFields por posición
  final textFields = find.byType(TextFormField);
  if (textFields.evaluate().length >= 3) {
    await tester.enterText(textFields.at(0), name);
    await tester.enterText(textFields.at(1), code);
    await tester.enterText(textFields.at(2), email);
  }
  
  await tester.pumpAndSettle();

  // Guardar - buscar ElevatedButton
  final saveButton = find.byType(ElevatedButton);
  if (saveButton.evaluate().isNotEmpty) {
    await tester.tap(saveButton.first);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  // Verificar creación
  expect(find.text(name), findsOneWidget, reason: 'La institución no fue creada');
  print('✓ Institución creada exitosamente.');
}

/// Actualiza una institución existente
Future<void> updateInstitution(
  WidgetTester tester,
  String currentName,
  String newName,
) async {
  print('Actualizando institución: $currentName -> $newName...');

  // Encontrar la tarjeta de la institución por texto
  final institutionCard = find.byWidgetPredicate(
    (widget) => widget is Card && 
        find.descendant(of: find.byWidget(widget), matching: find.text(currentName)).evaluate().isNotEmpty
  );
  
  if (institutionCard.evaluate().isNotEmpty) {
    await tester.tap(institutionCard.first);
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }

  // Modificar el nombre en el primer TextFormField
  final textFields = find.byType(TextFormField);
  if (textFields.evaluate().isNotEmpty) {
    // Limpiar y escribir nuevo nombre
    await tester.enterText(textFields.first, newName);
    await tester.pumpAndSettle();
  }

  // Guardar cambios
  final saveButton = find.byType(ElevatedButton);
  if (saveButton.evaluate().isNotEmpty) {
    await tester.tap(saveButton.first);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  // Verificar actualización
  expect(find.text(newName), findsOneWidget, reason: 'La institución no fue actualizada');
  print('✓ Institución actualizada exitosamente.');
}

/// Elimina una institución
Future<void> deleteInstitution(WidgetTester tester, String institutionName) async {
  print('Eliminando institución: $institutionName...');

  // Encontrar el menú de opciones (IconButton con more_vert)
  final moreIcons = find.byIcon(Icons.more_vert);
  if (moreIcons.evaluate().isNotEmpty) {
    await tester.tap(moreIcons.first);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Presionar eliminar
    final deleteOption = find.text('Eliminar');
    if (deleteOption.evaluate().isNotEmpty) {
      await tester.tap(deleteOption.first);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Confirmar eliminación en el diálogo
      final confirmDelete = find.byWidgetPredicate(
        (widget) => widget is TextButton && 
            find.descendant(of: find.byWidget(widget), matching: find.text('Eliminar')).evaluate().isNotEmpty
      );
      
      if (confirmDelete.evaluate().isNotEmpty) {
        await tester.tap(confirmDelete.last);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }
    }
  }

  // Verificar eliminación
  expect(find.text(institutionName), findsNothing, reason: 'La institución no fue eliminada');
  print('✓ Institución eliminada exitosamente.');
}

/// Navega a la sección de Usuarios
Future<void> navigateToUsers(WidgetTester tester) async {
  print('Navegando a Usuarios...');
  final usuariosText = find.text('Usuarios');
  if (usuariosText.evaluate().isNotEmpty) {
    await tester.tap(usuariosText.first);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }
  print('✓ Navegación a Usuarios completada.');
}

/// Crea un nuevo usuario (profesor)
Future<void> createUser(
  WidgetTester tester,
  String nombres,
  String apellidos,
  String email,
  String identificacion,
) async {
  print('Creando usuario: $nombres $apellidos...');

  // Presionar el FAB para agregar
  final fabButton = find.byType(FloatingActionButton);
  if (fabButton.evaluate().isNotEmpty) {
    await tester.tap(fabButton.first);
  } else {
    final addIcon = find.byIcon(Icons.add);
    if (addIcon.evaluate().isNotEmpty) {
      await tester.tap(addIcon.first);
    }
  }
  
  await tester.pumpAndSettle(const Duration(seconds: 1));

  // Presionar el botón de crear profesor (si existe un diálogo)
  final profesorButton = find.byIcon(Icons.school);
  if (profesorButton.evaluate().isNotEmpty) {
    await tester.tap(profesorButton.first);
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }

  // Rellenar formulario - buscar TextFormFields por posición
  final textFields = find.byType(TextFormField);
  if (textFields.evaluate().length >= 4) {
    await tester.enterText(textFields.at(0), nombres);
    await tester.enterText(textFields.at(1), apellidos);
    await tester.enterText(textFields.at(2), email);
    await tester.enterText(textFields.at(3), identificacion);
  }
  
  await tester.pumpAndSettle();

  // Guardar
  final saveButton = find.byType(ElevatedButton);
  if (saveButton.evaluate().isNotEmpty) {
    await tester.tap(saveButton.first);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  // Verificar creación
  expect(find.text(nombres), findsWidgets, reason: 'El usuario no fue creado');
  print('✓ Usuario creado exitosamente.');
}

/// Elimina un usuario
Future<void> deleteUser(WidgetTester tester, String fullName) async {
  print('Eliminando usuario: $fullName...');

  // Encontrar el menú de opciones
  final moreIcons = find.byIcon(Icons.more_vert);
  if (moreIcons.evaluate().isNotEmpty) {
    await tester.tap(moreIcons.first);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Presionar eliminar
    final deleteOption = find.text('Eliminar');
    if (deleteOption.evaluate().isNotEmpty) {
      await tester.tap(deleteOption.first);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Confirmar eliminación
      final confirmDelete = find.byWidgetPredicate(
        (widget) => widget is TextButton && 
            find.descendant(of: find.byWidget(widget), matching: find.text('Eliminar')).evaluate().isNotEmpty
      );
      
      if (confirmDelete.evaluate().isNotEmpty) {
        await tester.tap(confirmDelete.last);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }
    }
  }

  // Verificar eliminación
  expect(find.text(fullName), findsNothing, reason: 'El usuario no fue eliminado');
  print('✓ Usuario eliminado exitosamente.');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Flujo completo End-to-End como Super Administrador', () {
    
    testWidgets('Debe realizar login, CRUD de Instituciones, CRUD de Usuarios y logout', 
      (WidgetTester tester) async {
      
      // Inicia la aplicación
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 1. LOGIN
      await loginAsAdmin(tester);

      // 2. CRUD DE INSTITUCIONES
      print('\n--- PASO 2: Realizando CRUD de Instituciones ---');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final institutionName = 'Institución E2E Test';
      final institutionCode = 'IE2E-$timestamp';
      final institutionEmail = 'e2e.test.$timestamp@institution.edu';
      final updatedInstitutionName = '$institutionName (Actualizada)';

      await navigateToInstitutions(tester);

      // Crear institución
      await createInstitution(tester, institutionName, institutionCode, institutionEmail);

      // Actualizar institución
      await updateInstitution(tester, institutionName, updatedInstitutionName);

      // Eliminar institución
      await deleteInstitution(tester, updatedInstitutionName);

      print('✓ CRUD de Instituciones completado.');

      // 3. CRUD DE USUARIOS
      print('\n--- PASO 3: Realizando CRUD de Usuarios (Profesor) ---');
      final profesorNombre = 'Profesor';
      final profesorApellido = 'E2E Test';
      final profesorEmail = 'profesor.e2e.$timestamp@test.edu';
      final profesorId = 'ID-$timestamp';

      await navigateToUsers(tester);

      // Crear usuario
      await createUser(tester, profesorNombre, profesorApellido, profesorEmail, profesorId);

      // Eliminar usuario
      final fullName = '$profesorNombre $profesorApellido';
      await deleteUser(tester, fullName);

      print('✓ CRUD de Usuarios completado.');

      print('\n🎉🎉🎉 ¡Flujo completo verificado con éxito! 🎉🎉🎉\n');
    });
  });
}
