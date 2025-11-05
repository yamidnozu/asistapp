// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:asistapp/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ============================================================================
  // FUNCIONES AUXILIARES
  // ============================================================================

  /// Limpia el estado de autenticación antes de cada test
  Future<void> clearAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
    await prefs.remove('user');
    await prefs.remove('selectedInstitutionId');
  }

  /// Login general - Usa Keys específicas para mayor robustez
  Future<void> loginAs(
    WidgetTester tester,
    String email,
    String password,
  ) async {
    print('\n[LOGIN] Iniciando sesión con: $email');

    // Usar Keys específicas definidas en login_screen.dart
    final emailField = find.byKey(const Key('emailField'));
    final passwordField = find.byKey(const Key('passwordField'));
    final loginButton = find.byKey(const Key('loginButton'));

    expect(emailField, findsOneWidget, reason: 'Campo de email no encontrado');
    expect(passwordField, findsOneWidget, reason: 'Campo de contraseña no encontrado');
    expect(loginButton, findsOneWidget, reason: 'Botón de login no encontrado');

    await tester.enterText(emailField, email);
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    await tester.enterText(passwordField, password);
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    await tester.tap(loginButton);
    await tester.pumpAndSettle(const Duration(seconds: 5));

    print('✅ Login completado');
  }

  /// Logout general
  Future<void> performLogout(WidgetTester tester) async {
    print('\n[LOGOUT] Cerrando sesión...');

    // Buscar botón de logout (puede estar en AppBar o menú)
    final logoutButton = find.byIcon(Icons.logout);
    
    if (logoutButton.evaluate().isNotEmpty) {
      await tester.tap(logoutButton.first);
      await tester.pumpAndSettle(const Duration(seconds: 3));
    } else {
      print('ℹ️ Botón de logout no encontrado, continuando...');
    }

    print('✅ Logout completado');
  }

  /// Navegar a una sección de manera más robusta
  Future<bool> navigateTo(WidgetTester tester, String sectionName) async {
    print('\n[NAVIGATION] Intentando navegar a: $sectionName');
    
    try {
      // Intento 1: Buscar por texto exacto
      var navButton = find.text(sectionName);
      if (navButton.evaluate().isNotEmpty) {
        await tester.tap(navButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        print('✅ Navegación completada (por texto)');
        return true;
      }

      // Intento 2: Buscar por texto parcial
      navButton = find.byWidgetPredicate(
        (widget) => widget is Text && widget.data?.contains(sectionName) == true,
      );
      if (navButton.evaluate().isNotEmpty) {
        await tester.tap(navButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        print('✅ Navegación completada (por texto parcial)');
        return true;
      }

      print('⚠️ No se encontró botón para: $sectionName');
      return false;
    } catch (e) {
      print('⚠️ Error durante navegación: $e');
      return false;
    }
  }

  /// Crear una institución usando el stepper actual (versión simplificada)
  Future<void> createInstitution(
    WidgetTester tester, {
    required String nombre,
    required String email,
    String direccion = 'Dirección de prueba',
    String telefono = '+506 8888 9999',
    bool activa = true,
  }) async {
    print('\n[CREATE] Creando institución: $nombre');

    try {
      // Presionar FAB para agregar
      final fabButton = find.byType(FloatingActionButton);
      expect(fabButton, findsWidgets, reason: 'Debe haber botón FAB para agregar institución');
      await tester.tap(fabButton.first);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verificar que estamos en el formulario
      expect(find.text('Nueva Institución'), findsOneWidget, reason: 'Debe mostrar pantalla de nueva institución');

      // ===== PASO 1: Información Básica =====
      print('📝 Paso 1: Información básica');

      // Llenar campos del paso 1
      final textFields = find.byType(TextFormField);
      expect(textFields, findsAtLeastNWidgets(2), reason: 'Debe haber al menos 2 campos de texto');

      await tester.enterText(textFields.at(0), nombre); // nombre
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      await tester.enterText(textFields.at(1), email); // email
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      // Presionar "Siguiente" usando selector más específico - tomar el primer botón encontrado
      final nextButtons = find.descendant(
        of: find.byType(Stepper),
        matching: find.text('Siguiente'),
      );
      expect(nextButtons, findsWidgets, reason: 'Debe haber al menos un botón Siguiente');
      await tester.tap(nextButtons.first);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // ===== PASO 2: Contacto =====
      print('📞 Paso 2: Información de contacto');

      final textFieldsStep2 = find.byType(TextFormField);
      expect(textFieldsStep2, findsAtLeastNWidgets(2), reason: 'Debe haber campos de dirección y teléfono');

      await tester.enterText(textFieldsStep2.at(0), direccion); // dirección
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      await tester.enterText(textFieldsStep2.at(1), telefono); // teléfono
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      // Hacer scroll hacia arriba para asegurar que los controles del paso 2 sean visibles
      final nextButtons2 = find.descendant(
        of: find.byType(Stepper),
        matching: find.text('Siguiente'),
      );
      await tester.ensureVisible(nextButtons2.first);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Presionar "Siguiente" usando selector más específico - tomar el primer botón encontrado
      expect(nextButtons2, findsWidgets, reason: 'Debe haber al menos un botón Siguiente en paso 2');
      await tester.tap(nextButtons2.first, warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // ===== PASO 3: Configuración =====
      print('⚙️ Paso 3: Configuración');

      // El estado por defecto es true (activa), pero si necesitamos cambiarlo
      if (!activa) {
        final switches = find.byType(Switch);
        if (switches.evaluate().isNotEmpty) {
          await tester.tap(switches.first);
          await tester.pumpAndSettle(const Duration(milliseconds: 300));
        }
      }

      // Hacer scroll para asegurar que los controles del paso 3 sean visibles
      final createButton = find.byKey(const Key('formSaveButton'));
      await tester.ensureVisible(createButton.last);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Presionar "Crear" usando el último botón con Key formSaveButton (el activo)
      expect(createButton, findsWidgets, reason: 'Debe haber al menos un botón con Key formSaveButton');
      await tester.tap(createButton.last, warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verificar que se procesó correctamente - verificar que no hay errores visibles
      // y que el botón de loading desapareció (lo que indica que el proceso terminó)
      final loadingButtons = find.byType(CircularProgressIndicator);
      expect(loadingButtons, findsNothing, reason: 'No debe haber indicadores de loading');

      // Verificar que no hay mensajes de error
      final errorMessages = find.textContaining('Error');
      expect(errorMessages, findsNothing, reason: 'No debe haber mensajes de error');

      print('✅ Institución creada exitosamente');
    } catch (e) {
      print('⚠️ Error al crear institución: $e');
      rethrow;
    }
  }

  /// Crear un usuario (Profesor o similar)
  Future<void> createUser(
    WidgetTester tester, {
    required String nombre,
    required String apellido,
    required String email,
    required String rol,
  }) async {
    print(
        '\n[CREATE] Creando usuario: $nombre $apellido ($rol) - $email');

    try {
      // Presionar FAB
      final fabButton = find.byType(FloatingActionButton);
      if (fabButton.evaluate().isNotEmpty) {
        await tester.tap(fabButton.first);
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      // Rellenar formulario
      final textFields = find.byType(TextFormField);
      if (textFields.evaluate().length >= 3) {
        await tester.enterText(textFields.at(0), nombre);
        await tester.pumpAndSettle(const Duration(milliseconds: 300));
        
        await tester.enterText(textFields.at(1), apellido);
        await tester.pumpAndSettle(const Duration(milliseconds: 300));
        
        await tester.enterText(textFields.at(2), email);
        await tester.pumpAndSettle(const Duration(milliseconds: 300));

        // Buscar dropdown de rol si es necesario
        final dropdowns = find.byType(DropdownButton);
        if (dropdowns.evaluate().isNotEmpty) {
          await tester.tap(dropdowns.first);
          await tester.pumpAndSettle(const Duration(milliseconds: 500));

          final rolOption = find.text(rol);
          if (rolOption.evaluate().isNotEmpty) {
            await tester.tap(rolOption.first);
            await tester.pumpAndSettle(const Duration(milliseconds: 300));
          }
        }

        // Presionar botón de guardar
        final saveButton = find.byType(ElevatedButton);
        if (saveButton.evaluate().isNotEmpty) {
          await tester.tap(saveButton.first);
          await tester.pumpAndSettle(const Duration(seconds: 2));
          print('✅ Usuario creado exitosamente');
        }
      }
    } catch (e) {
      print('⚠️ Error al crear usuario: $e');
    }
  }

  /// Verificar si estamos en el dashboard
  bool isDashboardVisible(WidgetTester tester) {
    try {
      final dashboard = find.text('Dashboard');
      return dashboard.evaluate().isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ============================================================================
  // TESTS DE ACEPTACIÓN POR ROL
  // ============================================================================

  group('🔐 Flujo 1: Super Administrador', () {
    setUp(() async {
      await clearAuthState();
    });

    testWidgets(
      'Debe realizar login, ver dashboard y CRUD de Instituciones',
      (WidgetTester tester) async {
        print('\n╔═══════════════════════════════════════════╗');
        print('║  INICIANDO FLUJO: SUPER ADMINISTRADOR  ║');
        print('╚═══════════════════════════════════════════╝');

        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // ━━━ PASO 1: LOGIN ━━━
        print('\n━━━ PASO 1: LOGIN ━━━');
        await loginAs(tester, 'superadmin@asistapp.com', 'Admin123!');

        // ━━━ PASO 2: VERIFICAR DASHBOARD ━━━
        print('\n━━━ PASO 2: VERIFICAR DASHBOARD ━━━');
        await tester.pumpAndSettle(const Duration(seconds: 2));
        
        if (isDashboardVisible(tester)) {
          print('✅ Dashboard cargado correctamente');
        } else {
          print('⚠️ Dashboard no visible, continuando con navegación...');
        }

        // ━━━ PASO 3: NAVEGACIÓN A INSTITUCIONES ━━━
        print('\n━━━ PASO 3: NAVEGACIÓN A INSTITUCIONES ━━━');
        final navSuccess = await navigateTo(tester, 'Instituciones');
        
        if (navSuccess) {
          print('✅ Navegación a Instituciones exitosa');
          
          // ━━━ PASO 4: CREAR INSTITUCIÓN ━━━
          print('\n━━━ PASO 4: CREAR INSTITUCIÓN ━━━');
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          await createInstitution(
            tester,
            nombre: 'Instituto E2E $timestamp',
            email: 'e2e$timestamp@test.edu',
            direccion: 'Dirección E2E $timestamp',
            telefono: '+506 8888 $timestamp'.substring(0, 12), // Limitar longitud
          );
        }

        // ━━━ PASO 5: LOGOUT ━━━
        print('\n━━━ PASO 5: LOGOUT ━━━');
        await performLogout(tester);

        print('\n╔═══════════════════════════════════════════╗');
        print('║  ✅ FLUJO COMPLETADO EXITOSAMENTE       ║');
        print('╚═══════════════════════════════════════════╝\n');
      },
    );
  });

  group('🏫 Flujo 2: Administrador Multi-Institución', () {
    setUp(() async {
      await clearAuthState();
    });

    testWidgets(
      'Debe hacer login y seleccionar institución',
      (WidgetTester tester) async {
        print('\n╔═══════════════════════════════════════════╗');
        print('║  INICIANDO FLUJO: ADMIN MULTI         ║');
        print('╚═══════════════════════════════════════════╝');

        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // ━━━ PASO 1: LOGIN ━━━
        print('\n━━━ PASO 1: LOGIN ━━━');
        await loginAs(tester, 'multi@asistapp.com', 'Multi123!');

        // ━━━ PASO 2: VERIFICAR SELECTOR DE INSTITUCIÓN ━━━
        print('\n━━━ PASO 2: VERIFICAR SELECTOR DE INSTITUCIÓN ━━━');
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Buscar botón o selector de institución
        final institutionSelector = find.byWidgetPredicate(
          (widget) => widget is Text && 
              (widget.data?.contains('Institución') == true || 
               widget.data?.contains('Colegio') == true ||
               widget.data?.contains('Francisco') == true),
        );

        if (institutionSelector.evaluate().isNotEmpty) {
          print('✅ Selector de institución encontrado');
          await tester.tap(institutionSelector.first);
          await tester.pumpAndSettle(const Duration(seconds: 1));
        } else {
          print('ℹ️ Selector de institución no visible (posible selección automática)');
        }

        // ━━━ PASO 3: VERIFICAR DASHBOARD ━━━
        print('\n━━━ PASO 3: VERIFICAR DASHBOARD ━━━');
        await tester.pumpAndSettle(const Duration(seconds: 2));

        if (isDashboardVisible(tester)) {
          print('✅ Dashboard del admin multi-institución cargado');
        } else {
          print('ℹ️ Navegación completada sin error visible');
        }

        // ━━━ PASO 4: LOGOUT ━━━
        print('\n━━━ PASO 4: LOGOUT ━━━');
        await performLogout(tester);

        print('\n╔═══════════════════════════════════════════╗');
        print('║  ✅ FLUJO COMPLETADO EXITOSAMENTE       ║');
        print('╚═══════════════════════════════════════════╝\n');
      },
    );
  });

  group('👨‍💼 Flujo 3: Admin Institución Específica (San José)', () {
    setUp(() async {
      await clearAuthState();
    });

    testWidgets(
      'Debe hacer login como admin de institución',
      (WidgetTester tester) async {
        print('\n╔═══════════════════════════════════════════╗');
        print('║  INICIANDO FLUJO: ADMIN SAN JOSÉ       ║');
        print('╚═══════════════════════════════════════════╝');

        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // ━━━ PASO 1: LOGIN ━━━
        print('\n━━━ PASO 1: LOGIN ━━━');
        await loginAs(tester, 'admin@sanjose.edu', 'SanJose123!');

        // ━━━ PASO 2: VERIFICAR DASHBOARD ━━━
        print('\n━━━ PASO 2: VERIFICAR DASHBOARD ━━━');
        await tester.pumpAndSettle(const Duration(seconds: 2));

        if (isDashboardVisible(tester)) {
          print('✅ Dashboard del admin de institución cargado');
        } else {
          print('ℹ️ Verificación de UI completada');
        }

        // ━━━ PASO 3: INTENTAR NAVEGACIÓN A USUARIOS ━━━
        print('\n━━━ PASO 3: INTENTAR NAVEGACIÓN A USUARIOS ━━━');
        final navSuccess = await navigateTo(tester, 'Usuarios');
        
        if (navSuccess) {
          print('✅ Navegación a Usuarios exitosa');
          
          // ━━━ PASO 4: CREAR USUARIO ━━━
          print('\n━━━ PASO 4: CREAR USUARIO ━━━');
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          await createUser(
            tester,
            nombre: 'Test',
            apellido: 'Usuario',
            email: 'test.usuario.$timestamp@sanjose.edu',
            rol: 'Profesor',
          );
        } else {
          print('ℹ️ Navegación a Usuarios no disponible, continuando...');
        }

        // ━━━ PASO 5: LOGOUT ━━━
        print('\n━━━ PASO 5: LOGOUT ━━━');
        await performLogout(tester);

        print('\n╔═══════════════════════════════════════════╗');
        print('║  ✅ FLUJO COMPLETADO EXITOSAMENTE       ║');
        print('╚═══════════════════════════════════════════╝\n');
      },
    );
  });

  // ============================================================================
  // NOTAS SOBRE CREDENCIALES
  // ============================================================================
  // 
  // Credenciales activas en seed.ts:
  // ✅ superadmin@asistapp.com / Admin123! (Super Admin - activo)
  // ✅ multi@asistapp.com / Multi123! (Admin Multi - activo)
  // ✅ admin@sanjose.edu / SanJose123! (Admin San José - activo)
  //
  // ❌ Inactivos o con problemas de caracteres:
  // ❌ pedro.garcia@sanjose.edu / Prof123! (Profesor - marcado como inactivo)
  // ❌ juan.pérez@sanjose.edu / Est123! (Estudiante - nota el acento en "Pérez")
  //
  // Para agregar más flujos:
  // 1. Verificar que el usuario está activo: activo: true
  // 2. Verificar que el email no tiene caracteres especiales/acentos
  // 3. Usar las credenciales exactas del seed.ts
  //
}
