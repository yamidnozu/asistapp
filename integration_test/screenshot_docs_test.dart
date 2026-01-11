// ignore_for_file: avoid_print
/// ============================================================================
/// 📸 SCREENSHOTS PARA DOCUMENTACIÓN - Test E2E con capturas automáticas
/// ============================================================================
///
/// Este test recorre las pantallas principales de AsistApp capturando
/// screenshots para el manual de usuario.
///
/// EJECUCIÓN:
/// cd /c/Proyectos/DemoLife && flutter test integration_test/screenshot_docs_test.dart -d emulator-5554 -r expanded --no-pub
///
/// Las imágenes se guardan mediante el framework de integration_test
///
/// ============================================================================

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:asistapp/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Lista de screenshots capturados (nombre -> descripción)
  final Map<String, String> capturedScreenshots = {};

  /// Contador de screenshots
  int screenshotCount = 0;

  /// Flag para saber si ya convertimos la superficie
  bool surfaceConverted = false;

  /// Credenciales de prueba (del seed)
  const superAdminEmail = 'superadmin@asistapp.com';
  const superAdminPassword = 'Admin123!';
  const adminEmail = 'admin@sanjose.edu';
  const adminPassword = 'SanJose123!';
  const profesorEmail = 'juan.perez@sanjose.edu';
  const profesorPassword = 'Prof123!';
  const estudianteEmail = 'santiago.mendoza@sanjose.edu';
  const estudiantePassword = 'Est123!';
  const acudienteEmail = 'maria.mendoza@email.com';
  const acudientePassword = 'Acu123!';

  /// Helper para capturar screenshot
  Future<void> capture(
      WidgetTester tester, String name, String description) async {
    try {
      screenshotCount++;

      // En Android, necesitamos convertir la superficie primero
      if (!surfaceConverted && Platform.isAndroid) {
        try {
          await binding.convertFlutterSurfaceToImage();
          surfaceConverted = true;
          print('📱 Superficie convertida para screenshots Android');
        } catch (e) {
          print('⚠️ Error convirtiendo superficie: $e');
        }
      }

      // Esperar a que la UI esté estable
      await tester.pump(const Duration(milliseconds: 500));

      // Capturar screenshot
      await binding.takeScreenshot(name);

      capturedScreenshots[name] = description;
      print('📸 [$screenshotCount] $name.png - $description');
    } catch (e) {
      print('⚠️ Error capturando "$name": $e');
    }
  }

  /// Limpiar sesión
  Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (_) {}
  }

  /// Esperar sin colgar
  Future<void> pumpFor(WidgetTester tester, Duration duration) async {
    final steps = (duration.inMilliseconds / 100).ceil();
    for (int i = 0; i < steps; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Esperar a que se estabilice
  Future<void> settle(WidgetTester tester) async {
    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (!tester.binding.hasScheduledFrame) return;
    }
  }

  /// Esperar widget
  Future<bool> waitFor(WidgetTester tester, Finder finder,
      {int maxWait = 30}) async {
    for (int i = 0; i < maxWait; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      if (finder.evaluate().isNotEmpty) return true;
    }
    return false;
  }

  /// Hacer login
  Future<bool> doLogin(
      WidgetTester tester, String email, String password) async {
    if (!await waitFor(tester, find.byKey(const Key('emailField')))) {
      return false;
    }

    await settle(tester);

    final emailField = find.byKey(const Key('emailField'));
    final passwordField = find.byKey(const Key('passwordField'));
    final loginButton = find.byKey(const Key('loginButton'));

    // Encontrar TextField real
    final realEmail = find
            .descendant(of: emailField, matching: find.byType(TextField))
            .evaluate()
            .isNotEmpty
        ? find
            .descendant(of: emailField, matching: find.byType(TextField))
            .first
        : emailField;

    final realPass = find
            .descendant(of: passwordField, matching: find.byType(TextField))
            .evaluate()
            .isNotEmpty
        ? find
            .descendant(of: passwordField, matching: find.byType(TextField))
            .first
        : passwordField;

    // Limpiar campos primero
    await tester.enterText(realEmail, '');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(realEmail, email);
    await tester.pump(const Duration(milliseconds: 200));

    await tester.enterText(realPass, '');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(realPass, password);
    await tester.pump(const Duration(milliseconds: 200));

    // Dismiss keyboard
    await tester.tapAt(const Offset(0, 0));
    await settle(tester);

    await tester.ensureVisible(loginButton);
    await settle(tester);
    await tester.tap(loginButton);

    await pumpFor(tester, const Duration(seconds: 5));
    await settle(tester);

    return find.byKey(const Key('emailField')).evaluate().isEmpty;
  }

  /// Hacer logout
  Future<bool> doLogout(WidgetTester tester) async {
    // Volver al dashboard
    for (int i = 0; i < 5; i++) {
      final back = find.byIcon(Icons.arrow_back);
      if (back.evaluate().isNotEmpty) {
        await tester.tap(back.first);
        await settle(tester);
        await pumpFor(tester, const Duration(milliseconds: 500));
      } else {
        break;
      }
    }

    // Buscar logout
    final logoutIcon = find.byIcon(Icons.logout);
    if (logoutIcon.evaluate().isNotEmpty) {
      await tester.tap(logoutIcon.first);
      await settle(tester);
      await pumpFor(tester, const Duration(seconds: 1));

      final confirmBtn = find.text('Cerrar sesión');
      if (confirmBtn.evaluate().isNotEmpty) {
        await tester.tap(confirmBtn.last);
        await pumpFor(tester, const Duration(seconds: 2));
      }
    }

    await clearSession();
    app.main();
    await pumpFor(tester, const Duration(seconds: 3));
    return await waitFor(tester, find.byKey(const Key('emailField')));
  }

  /// Navegar a una sección
  Future<bool> navigateTo(WidgetTester tester, String section) async {
    // Buscar por InkWell con texto
    final allInkWells = find.byType(InkWell);
    for (int i = 0; i < allInkWells.evaluate().length; i++) {
      final widget = allInkWells.at(i);
      final textFinder =
          find.descendant(of: widget, matching: find.byType(Text));
      for (final textWidget in textFinder.evaluate()) {
        final text = (textWidget.widget as Text).data ?? '';
        if (text.toLowerCase().contains(section.toLowerCase())) {
          await tester.ensureVisible(widget);
          await settle(tester);
          await tester.tap(widget);
          await settle(tester);
          await pumpFor(tester, const Duration(seconds: 1));
          return true;
        }
      }
    }

    // Por texto directo
    var nav = find.textContaining(section);
    if (nav.evaluate().isNotEmpty) {
      await tester.ensureVisible(nav.first);
      await settle(tester);
      await tester.tap(nav.first);
      await settle(tester);
      await pumpFor(tester, const Duration(seconds: 1));
      return true;
    }

    return false;
  }

  /// Volver atrás
  Future<void> goBack(WidgetTester tester) async {
    final back = find.byIcon(Icons.arrow_back);
    if (back.evaluate().isNotEmpty) {
      await tester.tap(back.first);
      await settle(tester);
      await pumpFor(tester, const Duration(milliseconds: 500));
    }
  }

  // ==========================================================================
  // TEST PRINCIPAL DE CAPTURAS
  // ==========================================================================

  testWidgets('📸 Capturar screenshots para documentación',
      (WidgetTester tester) async {
    print('\n${'=' * 70}');
    print('📸 INICIANDO CAPTURA DE SCREENSHOTS PARA DOCUMENTACIÓN');
    print('${'=' * 70}\n');

    // Inicializar app
    await clearSession();
    app.main();
    await tester.pump();
    await waitFor(tester, find.byKey(const Key('emailField')), maxWait: 60);
    await pumpFor(tester, const Duration(seconds: 1));

    // ========================================================================
    // 1. PANTALLA DE LOGIN
    // ========================================================================
    print('\n📍 Capturando pantallas de LOGIN...\n');

    await capture(tester, 'login_screen', 'Pantalla de inicio de sesión');

    // ========================================================================
    // 2. SUPER ADMIN
    // ========================================================================
    print('\n📍 Capturando pantallas de SUPER ADMIN...\n');

    bool loginOk = await doLogin(tester, superAdminEmail, superAdminPassword);
    if (!loginOk) {
      print('❌ No se pudo hacer login como Super Admin');
      return;
    }
    await pumpFor(tester, const Duration(seconds: 1));

    await capture(
        tester, 'super_admin_dashboard', 'Dashboard del Super Administrador');

    // Navegar a Instituciones
    if (await navigateTo(tester, 'Instituciones')) {
      await pumpFor(tester, const Duration(seconds: 1));
      await capture(tester, 'institutions_list', 'Lista de instituciones');

      // Abrir formulario de crear institución
      final fab = find.byType(FloatingActionButton);
      if (fab.evaluate().isNotEmpty) {
        await tester.tap(fab.first);
        await settle(tester);
        await pumpFor(tester, const Duration(seconds: 1));
        await capture(tester, 'institution_form',
            'Formulario de creación de institución');
        await goBack(tester);
      }

      await goBack(tester);
    }

    // Navegar a Usuarios
    if (await navigateTo(tester, 'Usuarios')) {
      await pumpFor(tester, const Duration(seconds: 1));
      await capture(
          tester, 'users_list_superadmin', 'Lista de usuarios (Super Admin)');
      await goBack(tester);
    }

    // Ir a Ajustes
    final settingsIcon = find.byIcon(Icons.settings);
    if (settingsIcon.evaluate().isNotEmpty) {
      await tester.tap(settingsIcon.first);
      await settle(tester);
      await pumpFor(tester, const Duration(seconds: 1));
      await capture(tester, 'settings_screen', 'Pantalla de ajustes');
      await goBack(tester);
    }

    await doLogout(tester);

    // ========================================================================
    // 3. ADMIN DE INSTITUCIÓN
    // ========================================================================
    print('\n📍 Capturando pantallas de ADMIN INSTITUCIÓN...\n');

    loginOk = await doLogin(tester, adminEmail, adminPassword);
    if (!loginOk) {
      print('❌ No se pudo hacer login como Admin');
    } else {
      await pumpFor(tester, const Duration(seconds: 1));
      await capture(tester, 'admin_dashboard',
          'Dashboard del Administrador de Institución');

      // Usuarios
      if (await navigateTo(tester, 'Usuarios')) {
        await pumpFor(tester, const Duration(seconds: 1));
        await capture(tester, 'users_list_admin', 'Lista de usuarios (Admin)');
        await goBack(tester);
      }

      // Grupos
      if (await navigateTo(tester, 'Grupos')) {
        await pumpFor(tester, const Duration(seconds: 1));
        await capture(tester, 'grupos_list', 'Lista de grupos');

        // Tap en primer grupo si existe
        final listTiles = find.byType(ListTile);
        if (listTiles.evaluate().length > 1) {
          await tester.tap(listTiles.at(1));
          await settle(tester);
          await pumpFor(tester, const Duration(seconds: 1));
          await capture(tester, 'grupo_detail', 'Detalle del grupo');
          await goBack(tester);
        }

        await goBack(tester);
      }

      // Horarios
      if (await navigateTo(tester, 'Horarios')) {
        await pumpFor(tester, const Duration(seconds: 1));
        await capture(tester, 'horarios_screen', 'Gestión de horarios');
        await goBack(tester);
      }

      // Materias
      if (await navigateTo(tester, 'Materias')) {
        await pumpFor(tester, const Duration(seconds: 1));
        await capture(tester, 'materias_list', 'Lista de materias');
        await goBack(tester);
      }

      await doLogout(tester);
    }

    // ========================================================================
    // 4. PROFESOR
    // ========================================================================
    print('\n📍 Capturando pantallas de PROFESOR...\n');

    loginOk = await doLogin(tester, profesorEmail, profesorPassword);
    if (!loginOk) {
      print('❌ No se pudo hacer login como Profesor');
    } else {
      await pumpFor(tester, const Duration(seconds: 1));
      await capture(tester, 'teacher_dashboard',
          'Dashboard del profesor con clases del día');

      // Ver si hay clases disponibles para tocar
      final cards = find.byType(Card);
      if (cards.evaluate().length > 1) {
        await tester.tap(cards.at(1));
        await settle(tester);
        await pumpFor(tester, const Duration(seconds: 2));
        await capture(
            tester, 'attendance_screen', 'Pantalla de toma de asistencia');
        await goBack(tester);
      }

      await doLogout(tester);
    }

    // ========================================================================
    // 5. ESTUDIANTE
    // ========================================================================
    print('\n📍 Capturando pantallas de ESTUDIANTE...\n');

    loginOk = await doLogin(tester, estudianteEmail, estudiantePassword);
    if (!loginOk) {
      print('❌ No se pudo hacer login como Estudiante');
    } else {
      await pumpFor(tester, const Duration(seconds: 1));
      await capture(tester, 'student_dashboard', 'Dashboard del estudiante');

      // Mi Código QR
      if (await navigateTo(tester, 'Código QR') ||
          await navigateTo(tester, 'Mi QR')) {
        await pumpFor(tester, const Duration(seconds: 1));
        await capture(
            tester, 'my_qr_code', 'Código QR personal del estudiante');
        await goBack(tester);
      }

      // Mi Horario
      if (await navigateTo(tester, 'Horario') ||
          await navigateTo(tester, 'Mi Horario')) {
        await pumpFor(tester, const Duration(seconds: 1));
        await capture(tester, 'student_schedule', 'Horario del estudiante');
        await goBack(tester);
      }

      // Mi Asistencia
      if (await navigateTo(tester, 'Asistencia') ||
          await navigateTo(tester, 'Mi Asistencia')) {
        await pumpFor(tester, const Duration(seconds: 1));
        await capture(tester, 'student_attendance',
            'Historial de asistencia del estudiante');
        await goBack(tester);
      }

      await doLogout(tester);
    }

    // ========================================================================
    // 6. ACUDIENTE
    // ========================================================================
    print('\n📍 Capturando pantallas de ACUDIENTE...\n');

    loginOk = await doLogin(tester, acudienteEmail, acudientePassword);
    if (!loginOk) {
      print('❌ No se pudo hacer login como Acudiente');
    } else {
      await pumpFor(tester, const Duration(seconds: 2));
      await capture(tester, 'acudiente_dashboard',
          'Dashboard del acudiente con resumen de hijos');

      // Tap en tarjeta de hijo
      final cards = find.byType(Card);
      if (cards.evaluate().length > 1) {
        await tester.tap(cards.at(1));
        await settle(tester);
        await pumpFor(tester, const Duration(seconds: 1));
        await capture(tester, 'estudiante_detail',
            'Detalle del estudiante (vista acudiente)');
        await goBack(tester);
      }

      // Notificaciones
      final notifIcon = find.byIcon(Icons.notifications_outlined);
      if (notifIcon.evaluate().isNotEmpty) {
        await tester.tap(notifIcon.first);
        await settle(tester);
        await pumpFor(tester, const Duration(seconds: 1));
        await capture(
            tester, 'notificaciones_screen', 'Centro de notificaciones');
        await goBack(tester);
      }

      await doLogout(tester);
    }

    // ========================================================================
    // REPORTE FINAL
    // ========================================================================
    print('\n${'=' * 70}');
    print('📊 CAPTURA DE SCREENSHOTS COMPLETADA');
    print('${'=' * 70}');
    print('Total de capturas: $screenshotCount');
    print('');
    print('📸 Screenshots capturados:');
    for (final entry in capturedScreenshots.entries) {
      print('   • ${entry.key}.png - ${entry.value}');
    }
    print('');
    print('📁 Los screenshots se guardan automáticamente por Flutter.');
    print('   Para Android: Buscar en el dispositivo/emulador');
    print('   Para Desktop: build/integration_test_screenshots/');
    print('');
    print('💡 Para copiar al manual, ejecutar después:');
    print('   adb pull /sdcard/screenshots/ docs/images/');
    print('${'=' * 70}\n');
  });
}
