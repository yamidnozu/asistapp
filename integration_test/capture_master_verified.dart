import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:asistapp/main.dart' as app;
import 'dart:io' show Platform;
import 'package:flutter/services.dart';

// --- CONFIGURACIÓN DE CREDENCIALES ---
const CREDS_SUPER = {'email': 'superadmin@asistapp.com', 'pass': 'Admin123!'};
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
      await settle(tester, 3000); // Espera larga
      if (finder.evaluate().isEmpty) {
        // Debug dump text
        print('    ⚠️ Texto visible en pantalla:');
        // find.byType(Text).evaluate().take(10).forEach((e) => print('      "${(e.widget as Text).data}"'));
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
    await tester.enterText(emailField, email);

    final passField = find.byKey(const Key('passwordField'));
    await tester.tap(passField);
    await tester.enterText(passField, password);

    await tester.tapAt(const Offset(0, 0)); // Cerrar teclado
    await settle(tester, 1000);

    // Usar ensureVisible para el botón
    final btn = find.text('Iniciar Sesión');
    await ensureVisible(tester, btn);
    await tester.tap(btn);

    await settle(tester, 5000); // Esperar dashboard
  }

  Future<void> navTo(WidgetTester tester, String menuText) async {
    print('    📍 Navegando a menú: $menuText');
    final s = find.byType(SingleChildScrollView);

    if (find.text(menuText).evaluate().isNotEmpty) {
      await tester.tap(find.text(menuText).last);
      await settle(tester, 2000);
      return;
    }
    if (s.evaluate().isNotEmpty) {
      await tester.drag(s.first, const Offset(0, -500));
      await settle(tester);
      if (find.text(menuText).evaluate().isNotEmpty) {
        await tester.tap(find.text(menuText).last);
        await settle(tester, 2000);
        return;
      }
      await tester.drag(s.first, const Offset(0, 500));
      await settle(tester);
      if (find.text(menuText).evaluate().isNotEmpty) {
        await tester.tap(find.text(menuText).last);
        await settle(tester, 2000);
        return;
      }
    }
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
    final back = find.byTooltip('Back');
    if (back.evaluate().isNotEmpty)
      await tester.tap(back);
    else
      await tester.tap(find.byType(BackButton));
    await settle(tester, 2000);
  }

  testWidgets('📸 CAPTURA MAESTRA VERIFICADA V2', (WidgetTester tester) async {
    app.main();
    await settle(tester, 5000);

    // 1. LOGIN
    print('\n🟦 1. LOGIN SCREEN');
    if (find.text('Iniciar Sesión').evaluate().isEmpty) await doLogout(tester);
    await validate(tester, 'Login Screen', find.byKey(const Key('emailField')));
    await capture(tester, 'login_screen');

    // 2. SUPER ADMIN
    print('\n🟦 2. SUPER ADMIN FLOW');
    await doLogin(tester, CREDS_SUPER['email']!, CREDS_SUPER['pass']!);

    // Validador más flexible: busca parte del saludo O el título del dashboard
    bool onDashboard = find.textContaining('Hola').evaluate().isNotEmpty ||
        find.text('Instituciones').evaluate().isNotEmpty;
    if (!onDashboard) throw Exception('❌ No estamos en Super Admin Dashboard');
    print('    ✅ Dashboard Super Admin confirmado.');
    await capture(tester, 'super_admin_dashboard');

    await navTo(tester, 'Instituciones');
    await validate(tester, 'Lista Instituciones', find.text('Instituciones'));
    await capture(tester, 'institutions_list');

    final fab = find.byType(FloatingActionButton);
    if (fab.evaluate().isNotEmpty) {
      await tester.tap(fab);
      await settle(tester);
      if (find.text('Nueva Institución').evaluate().isNotEmpty ||
          find.byType(TextFormField).evaluate().isNotEmpty) {
        await capture(tester, 'institution_form');
        await goBack(tester);
      }
    }
    await doLogout(tester);

    // 3. ADMIN
    print('\n🟦 3. ADMIN FLOW');
    await doLogin(tester, CREDS_ADMIN['email']!, CREDS_ADMIN['pass']!);
    await validate(tester, 'Admin Dashboard', find.text('Grupos'));
    await capture(tester, 'admin_dashboard');

    await navTo(tester, 'Grupos');
    await validate(tester, 'Gestión Grupos', find.text('Gestión de Grupos'));
    await capture(tester, 'grupos_screen');
    if (find.byType(FloatingActionButton).evaluate().isNotEmpty) {
      await tester.tap(find.byType(FloatingActionButton));
      await settle(tester);
      await capture(tester, 'grupo_form');
      await tester.tap(find.text('Cancelar'));
      await settle(tester);
    }
    await goBack(tester);

    await navTo(tester, 'Horarios');
    await validate(tester, 'Gestión Horarios', find.text('Horarios'));
    await capture(tester, 'horarios_screen');
    // Dialog creación
    await tester.tapAt(const Offset(200, 400)); // Tap en medio del calendario
    await settle(tester);
    if (find.text('Nueva Clase').evaluate().isNotEmpty ||
        find.text('Crear Clase').evaluate().isNotEmpty) {
      await capture(tester, 'horario_form'); // Reemplaza la idea anterior
      await tester.tap(find.text('Cancelar')); // O cerrar dialog
      await settle(tester);
    }
    await goBack(tester);

    await navTo(tester, 'Materias');
    await validate(
        tester, 'Gestión Materias', find.text('Gestión de Materias'));
    await capture(tester, 'materias_screen');
    if (find.byType(FloatingActionButton).evaluate().isNotEmpty) {
      await tester.tap(find.byType(FloatingActionButton));
      await settle(tester);
      await capture(tester, 'materia_form');
      await tester.tap(find.text('Cancelar'));
      await settle(tester);
    }
    await goBack(tester);

    await navTo(tester, 'Períodos');
    await settle(tester);
    await capture(tester, 'periodos_screen');
    await goBack(tester);

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
      if (find.text('Nuevo Usuario').evaluate().isNotEmpty) {
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
    final claseCard = find.byIcon(Icons.class_).first;
    if (claseCard.evaluate().isNotEmpty) {
      await tester.tap(claseCard);
      await settle(tester, 3000);
      await capture(tester, 'attendance_screen');
      final editIcon = find.byIcon(Icons.edit).first;
      if (editIcon.evaluate().isNotEmpty) {
        await tester.tap(editIcon);
        await settle(tester);
        await capture(tester, 'edit_attendance_dialog');
        await tester.tapAt(const Offset(10, 10));
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
    final notifIcon = find.byIcon(Icons.notifications_outlined).first;
    if (notifIcon.evaluate().isNotEmpty) {
      await tester.tap(notifIcon);
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
    final childCard = find.byType(Card).first;
    if (childCard.evaluate().isNotEmpty) {
      await tester.tap(childCard);
      await settle(tester);
      await capture(tester, 'estudiante_detail');
      await goBack(tester);
    }
    await navTo(tester, 'Ajustes');
    await capture(tester, 'settings_screen');
    await doLogout(tester);
  });
}
