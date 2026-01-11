import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:asistapp/main.dart' as app;
import 'dart:io' show Platform;
import 'package:flutter/services.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  bool surfaceConverted = false;

  Future<void> capture(WidgetTester tester, String name) async {
    try {
      if (!surfaceConverted && Platform.isAndroid) {
        try {
          await binding.convertFlutterSurfaceToImage();
          surfaceConverted = true;
        } catch (_) {}
      }
      // Esperar a que la UI esté quieta
      await tester.pumpAndSettle(const Duration(milliseconds: 1500));
      await binding.takeScreenshot(name);
      print('    📸 [CAPTURE] $name.png');
    } catch (e) {
      print('    ⚠️ Error capturando $name: $e');
    }
  }

  Future<void> settleFor(WidgetTester tester, Duration duration) async {
    await tester.pumpAndSettle();
    await Future.delayed(duration);
  }

  Future<void> doLogin(
      WidgetTester tester, String email, String password) async {
    print('    🔑 Login: $email');
    final emailField = find.byKey(const Key('emailField'));
    if (emailField.evaluate().isNotEmpty) {
      await tester.tap(emailField);
      await tester.enterText(emailField, '');
      await tester.pump();
      await tester.enterText(emailField, email);
      await tester.tap(find.byKey(const Key('passwordField')));
      await tester.enterText(find.byKey(const Key('passwordField')), password);
      await tester.tapAt(const Offset(0, 0)); // Ocultar teclado
      await settleFor(tester, const Duration(seconds: 1));
      await tester.tap(find.text('Iniciar Sesión'));
      await settleFor(tester, const Duration(seconds: 5));
    }
  }

  Future<void> doLogout(WidgetTester tester) async {
    print('    🚪 Logout...');
    if (find.text('Iniciar Sesión').evaluate().isNotEmpty) return;

    // Intentar salir
    final logoutIcon = find.byIcon(Icons.logout);
    if (logoutIcon.evaluate().isNotEmpty) {
      await tester.tap(logoutIcon);
    } else {
      // Menu drawer
      final menu = find.byTooltip('Open navigation menu');
      if (menu.evaluate().isNotEmpty) await tester.tap(menu);
      await settleFor(tester, const Duration(seconds: 1));
      if (find.text('Cerrar Sesión').evaluate().isNotEmpty)
        await tester.tap(find.text('Cerrar Sesión'));
    }

    await settleFor(tester, const Duration(seconds: 2));
    // Confirmar dialogo
    if (find.text('Cerrar sesión').evaluate().isNotEmpty)
      await tester.tap(find.text('Cerrar sesión').last);
    await settleFor(tester, const Duration(seconds: 3));
  }

  // Navegación robusta con scroll y validación
  Future<void> navToSection(
      WidgetTester tester, String menuText, String expectedAppBarTitle) async {
    print('    📍 Navegando a: $menuText');
    final s = find.byType(SingleChildScrollView);

    // 1. Buscar en pantalla actual
    if (find.text(menuText).evaluate().isNotEmpty) {
      await tester.tap(find.text(menuText).last);
    }
    // 2. Scroll abajo
    else if (s.evaluate().isNotEmpty) {
      await tester.drag(s.first, const Offset(0, -500));
      await settleFor(tester, const Duration(seconds: 1));
      if (find.text(menuText).evaluate().isNotEmpty) {
        await tester.tap(find.text(menuText).last);
      } else {
        // 3. Scroll arriba (reset)
        await tester.drag(s.first, const Offset(0, 500)); // subir
        await settleFor(tester, const Duration(seconds: 1));
        // Intentar de nuevo
        if (find.text(menuText).evaluate().isNotEmpty)
          await tester.tap(find.text(menuText).last);
      }
    }

    await settleFor(tester, const Duration(seconds: 3));

    // VALIDACIÓN ESTRICTA
    if (find.text(expectedAppBarTitle).evaluate().isEmpty) {
      // A veces el título está en un widget custom o AppBar
      // Intentamos ver si hay ALGÚN texto con ese título visible
      print(
          '    ⚠️ ADVERTENCIA: No veo el título "$expectedAppBarTitle". Pantalla actual podría ser incorrecta.');
      // Scroll un poco por si es una lista
      await tester.dragFrom(const Offset(200, 300), const Offset(0, 100));
    } else {
      print('    ✅ Confirmado en pantalla: $expectedAppBarTitle');
    }
  }

  testWidgets('📸 FIX BROKEN SCREENSHOTS', (WidgetTester tester) async {
    app.main();
    await settleFor(tester, const Duration(seconds: 4));
    if (find.text('Iniciar Sesión').evaluate().isEmpty) await doLogout(tester);

    // --- ADMIN FLOW (User Form, Grupos, Horarios) ---
    try {
      await doLogin(tester, 'admin@sanjose.edu', 'SanJose123!');
      await settleFor(tester, const Duration(seconds: 2));

      // 1. GRUPOS (Re-capture para asegurar)
      await navToSection(tester, 'Grupos', 'Gestión de Grupos');
      // Verificar que realmente es grupos (mirar si hay chip de grados o lista)
      if (find.text('Gestión de Grupos').evaluate().isNotEmpty) {
        await capture(tester, 'grupos_screen');
      }
      await tester.tap(find.byTooltip('Back')); // Volver al dashboard
      await settleFor(tester, const Duration(seconds: 2));

      // 2. HORARIOS (El problemático)
      await navToSection(tester, 'Horarios', 'Gestión de Horarios');
      if (find.text('Gestión de Horarios').evaluate().isNotEmpty) {
        await capture(tester, 'horarios_screen');
      }
      await tester.tap(find.byTooltip('Back'));
      await settleFor(tester, const Duration(seconds: 2));

      // 3. USUARIOS & FORM (Para admin)
      await navToSection(tester, 'Usuarios', 'Gestión de Usuarios');
      // Capture list (opcional, pero util para verificar)
      // await capture(tester, 'admin_users_list');

      // Entrar al formulario
      final fab = find.byType(FloatingActionButton);
      if (fab.evaluate().isNotEmpty) {
        await tester.tap(fab);
        await settleFor(tester, const Duration(seconds: 2));

        // Seleccionar tipo 'Profesor' si pide
        if (find.text('Profesor').evaluate().isNotEmpty)
          await tester.tap(find.text('Profesor'));
        else if (find.byIcon(Icons.person_add).evaluate().isNotEmpty)
          await tester.tap(find.byIcon(Icons.person_add).first);

        await settleFor(tester, const Duration(seconds: 2));
        // Llenar algo para que se vea real
        final inputs = find.byType(TextFormField);
        if (inputs.evaluate().isNotEmpty) {
          await tester.enterText(inputs.first, 'profe.nuevo@test.com');
          await capture(tester, 'user_form');
        } else {
          print('    ⚠️ No encontré inputs en el formulario de usuario');
        }
        // Cancelar/Volver
        await tester.tap(find.byType(BackButton));
      }
      await tester.tap(find.byType(BackButton)); // Volver a dashboard
      await doLogout(tester);
    } catch (e) {
      print('Admin Flow Error: $e');
      await doLogout(tester);
    }

    // --- SUPER ADMIN FLOW (Users List) ---
    try {
      await doLogin(tester, 'superadmin@asistapp.com', 'Admin123!');

      // Navegar a Usuarios
      await navToSection(tester, 'Usuarios', 'Gestión de Usuarios');
      if (find.text('Gestión de Usuarios').evaluate().isNotEmpty) {
        await capture(tester, 'users_list');
      }
      await doLogout(tester);
    } catch (e) {
      print('Super Admin Flow Error: $e');
    }
  });
}
