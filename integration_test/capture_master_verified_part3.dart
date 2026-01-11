import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:asistapp/main.dart' as app;
import 'dart:io' show Platform;
import 'package:flutter/services.dart';

const CREDS_ADMIN = {'email': 'admin@sanjose.edu', 'pass': 'SanJose123!'};
const CREDS_PROFE = {'email': 'juan.perez@sanjose.edu', 'pass': 'Prof123!'};
const CREDS_ESTUD = {
  'email': 'santiago.mendoza@sanjose.edu',
  'pass': 'Est123!'
};
const CREDS_ACUDI = {'email': 'maria.mendoza@email.com', 'pass': 'Acu123!'};

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  bool surfaceConverted = false;

  Future<void> settle(WidgetTester tester, [int ms = 1000]) async {
    await tester.pumpAndSettle();
    await Future.delayed(Duration(milliseconds: ms));
  }

  Future<void> ensureVisible(WidgetTester tester, Finder finder) async {
    final scrollable = find.byType(Scrollable).first;
    if (scrollable.evaluate().isNotEmpty) {
      try {
        await tester.scrollUntilVisible(finder, 50.0, scrollable: scrollable);
      } catch (_) {}
    }
  }

  Future<void> capture(WidgetTester tester, String name) async {
    try {
      if (!surfaceConverted && Platform.isAndroid) {
        try {
          await binding.convertFlutterSurfaceToImage();
          surfaceConverted = true;
        } catch (_) {}
      }
      await settle(tester, 1500);
      await binding.takeScreenshot(name);
      print('    📸 [GUARDADO] $name.png');
    } catch (e) {
      print('    ⚠️ Error guardando $name: $e');
    }
  }

  Future<void> validate(
      WidgetTester tester, String screenInfo, Finder finder) async {
    print('    🔍 Validando contexto: $screenInfo...');
    if (finder.evaluate().isEmpty) {
      await settle(tester, 3000);
      if (finder.evaluate().isEmpty) {
        throw Exception(
            '❌ ERROR DE CONTEXTO: Se esperaba estar en "$screenInfo" pero no se encontró el elemento validador.');
      }
    }
    print('    ✅ Contexto validado: $screenInfo.');
  }

  Future<void> doLogout(WidgetTester tester) async {
    print('    🚪 Logout...');
    if (find.text('Iniciar Sesión').evaluate().isNotEmpty) return;

    final logoutIcon = find.byIcon(Icons.logout);
    if (logoutIcon.evaluate().isNotEmpty)
      await tester.tap(logoutIcon);
    else {
      final menu = find.byTooltip('Open navigation menu');
      if (menu.evaluate().isNotEmpty) await tester.tap(menu);
      await settle(tester);
      if (find.text('Cerrar Sesión').evaluate().isNotEmpty)
        await tester.tap(find.text('Cerrar Sesión'));
      else if (find.text('Cerrar sesión').evaluate().isNotEmpty)
        await tester.tap(find.text('Cerrar sesión'));
    }
    await settle(tester);
    if (find.text('Cerrar sesión').evaluate().isNotEmpty)
      await tester.tap(find.text('Cerrar sesión').last);
    await settle(tester, 2000);
  }

  Future<void> doLogin(
      WidgetTester tester, String email, String password) async {
    print('    🔑 Login con $email');
    if (find.text('Iniciar Sesión').evaluate().isEmpty) await doLogout(tester);
    await validate(tester, 'Pantalla Login', find.text('Iniciar Sesión'));

    final emailField = find.byKey(const Key('emailField'));
    await tester.tap(emailField);
    await tester.enterText(emailField, '');
    await tester.enterText(emailField, email);

    final passField = find.byKey(const Key('passwordField'));
    await tester.tap(passField);
    await tester.enterText(passField, password);

    await tester.tapAt(const Offset(0, 0));
    await settle(tester, 1000);

    final btn = find.text('Iniciar Sesión');
    await ensureVisible(tester, btn);
    await tester.tap(btn);

    await settle(tester, 5000);
  }

  Future<void> navTo(WidgetTester tester, String menuText) async {
    print('    📍 Navegando a menú: $menuText');
    final s = find.byType(SingleChildScrollView);

    // Intento 1: Directo
    if (find.text(menuText).evaluate().isNotEmpty) {
      await tester.tap(find.text(menuText).last);
      await settle(tester, 2000);
      return;
    }
    // Intento 2: Scroll Abajo Fuerte
    if (s.evaluate().isNotEmpty) {
      await tester.drag(s.first, const Offset(0, -800)); // Más fuerte
      await settle(tester);
      if (find.text(menuText).evaluate().isNotEmpty) {
        await tester.tap(find.text(menuText).last);
        await settle(tester, 2000);
        return;
      }
      // Intento 3: Scroll Arriba Fuerte
      await tester.drag(s.first, const Offset(0, 800));
      await settle(tester);
      if (find.text(menuText).evaluate().isNotEmpty) {
        await tester.tap(find.text(menuText).last);
        await settle(tester, 2000);
        return;
      }
    }
    // Intento 4: Drawer
    final menuBtn = find.byTooltip('Open navigation menu');
    if (menuBtn.evaluate().isNotEmpty) {
      await tester.tap(menuBtn);
      await settle(tester);
      if (find.text(menuText).evaluate().isNotEmpty) {
        await tester.tap(find.text(menuText));
        await settle(tester, 2000);
        return;
      }
      await tester.tapAt(const Offset(300, 300));
    }
    print('    ⚠️ Advertencia: No se pudo navegar a $menuText');
  }

  Future<void> goBack(WidgetTester tester) async {
    try {
      if (find.text('Cancelar').evaluate().isNotEmpty) {
        await tester.tap(find.text('Cancelar').last);
        await settle(tester, 1000);
        return;
      }
      if (find.text('Cerrar').evaluate().isNotEmpty) {
        await tester.tap(find.text('Cerrar').last);
        await settle(tester, 1000);
        return;
      }
      final back = find.byTooltip('Back');
      if (back.evaluate().isNotEmpty)
        await tester.tap(back);
      else if (find.byType(BackButton).evaluate().isNotEmpty)
        await tester.tap(find.byType(BackButton));
      else if (find.byIcon(Icons.arrow_back).evaluate().isNotEmpty)
        await tester.tap(find.byIcon(Icons.arrow_back));
      await settle(tester, 2000);
    } catch (_) {}
  }

  testWidgets('📸 CAPTURA MAESTRA PART 3 (ADMIN REST + OTHERS)',
      (WidgetTester tester) async {
    app.main();
    await settle(tester, 5000);
    if (find.text('Iniciar Sesión').evaluate().isEmpty) await doLogout(tester);

    // 3. ADMIN (Continuación)
    print('\n🟦 3. ADMIN FLOW (CONT)');
    await doLogin(tester, CREDS_ADMIN['email']!, CREDS_ADMIN['pass']!);

    // HORARIOS
    await navTo(tester, 'Horarios');
    await validate(tester, 'Gestión Horarios', find.text('Horarios'));
    await capture(tester, 'horarios_screen');
    await tester.tapAt(const Offset(200, 400)); // Dialog
    await settle(tester);
    if (find.text('Nueva Clase').evaluate().isNotEmpty ||
        find.text('Crear Clase').evaluate().isNotEmpty) {
      await capture(tester, 'horario_form');
      await goBack(tester);
    }
    await goBack(tester);

    // MATERIAS
    await navTo(tester, 'Materias');
    await validate(
        tester, 'Gestión Materias', find.text('Gestión de Materias'));
    await capture(tester, 'materias_screen');
    if (find.byType(FloatingActionButton).evaluate().isNotEmpty) {
      await tester.tap(find.byType(FloatingActionButton));
      await settle(tester);
      await capture(tester, 'materia_form');
      await goBack(tester);
    }
    await goBack(tester);

    // PERIODOS
    await navTo(tester, 'Períodos');
    await settle(tester);
    await capture(tester, 'periodos_screen');
    await goBack(tester);

    // USUARIOS
    await navTo(tester, 'Usuarios');
    await validate(tester, 'Gestión Usuarios',
        find.text('Gestión de Usuarios de la Institución'));
    await capture(tester, 'users_list');
    if (find.byType(FloatingActionButton).evaluate().isNotEmpty) {
      await tester.tap(find.byType(FloatingActionButton));
      await settle(tester);
      if (find.text('Crear Profesor').evaluate().isNotEmpty)
        await tester.tap(find.text('Crear Profesor'));
      else if (find.byIcon(Icons.school).evaluate().isNotEmpty)
        await tester.tap(find.byIcon(Icons.school));

      await settle(tester);
      if (find.text('Nuevo Usuario').evaluate().isNotEmpty ||
          find.byType(TextFormField).evaluate().isNotEmpty) {
        await capture(tester, 'user_form');
        await goBack(tester);
      }
    }
    await goBack(tester);
    await doLogout(tester);

    // 4. PROFESOR
    print('\n🟦 4. TEACHER FLOW');
    await doLogin(tester, CREDS_PROFE['email']!, CREDS_PROFE['pass']!);
    await validate(
        tester, 'Teacher Dashboard', find.text('Panel del Profesor'));
    await capture(tester, 'teacher_dashboard');
    if (find.byIcon(Icons.class_).evaluate().isNotEmpty) {
      await tester.tap(find.byIcon(Icons.class_).first);
      await settle(tester, 3000);
      await capture(tester, 'attendance_screen');
      if (find.byIcon(Icons.edit).evaluate().isNotEmpty) {
        await tester.tap(find.byIcon(Icons.edit).first);
        await settle(tester);
        await capture(tester, 'edit_attendance_dialog');
        await tester.tapAt(const Offset(10, 10)); // Tap fuera
        await settle(tester);
      }
      await goBack(tester);
    }
    await doLogout(tester);

    // 5. ESTUDIANTE
    print('\n🟦 5. STUDENT FLOW');
    await doLogin(tester, CREDS_ESTUD['email']!, CREDS_ESTUD['pass']!);
    await validate(
        tester, 'Student Dashboard', find.text('Panel del Estudiante'));
    await capture(tester, 'student_dashboard');
    await navTo(tester, 'Mi Código QR');
    await validate(tester, 'QR Screen', find.text('Mi Código QR'));
    await capture(tester, 'my_qr_code');
    await goBack(tester);
    await navTo(tester, 'Mi Horario');
    await capture(tester, 'student_schedule');
    await goBack(tester);
    if (find.byIcon(Icons.notifications_outlined).evaluate().isNotEmpty) {
      await tester.tap(find.byIcon(Icons.notifications_outlined).first);
      await settle(tester);
      await capture(tester, 'notificaciones_screen');
      await goBack(tester);
    }
    await doLogout(tester);

    // 6. ACUDIENTE
    print('\n🟦 6. ACUDIENTE FLOW');
    await doLogin(tester, CREDS_ACUDI['email']!, CREDS_ACUDI['pass']!);
    await validate(tester, 'Acudiente Dashboard', find.text('Mis Hijos'));
    await capture(tester, 'acudiente_dashboard');
    if (find.byType(Card).evaluate().isNotEmpty) {
      await tester.tap(find.byType(Card).first);
      await settle(tester);
      await capture(tester, 'estudiante_detail');
      await goBack(tester);
    }
    await navTo(tester, 'Ajustes');
    await capture(tester, 'settings_screen');
    await doLogout(tester);
  });
}
