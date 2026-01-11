import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:asistapp/main.dart' as app;
import 'dart:io' show Platform;
import 'package:flutter/services.dart';

const CREDS_ACUDI = {'email': 'maria.mendoza@email.com', 'pass': 'Acu123!'};

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  Future<void> settle(WidgetTester tester) async {
    await tester.pumpAndSettle(const Duration(milliseconds: 1000));
    await Future.delayed(const Duration(milliseconds: 2000));
  }

  Future<void> ensureVisible(WidgetTester tester, Finder finder) async {
    final scrollable = find.byType(Scrollable).first;
    if (scrollable.evaluate().isNotEmpty) {
      try {
        await tester.scrollUntilVisible(finder, 100.0, scrollable: scrollable);
      } catch (_) {}
    }
  }

  testWidgets('📸 CAPTURA FINAL ACUDIENTE (ULTRARROBUSTO)',
      (WidgetTester tester) async {
    app.main();
    await Future.delayed(const Duration(seconds: 15)); // Espera inicial MASIVA
    await tester.pumpAndSettle();

    if (Platform.isAndroid) {
      try {
        await binding.convertFlutterSurfaceToImage();
      } catch (_) {}
    }

    // Logout
    if (find.text('Iniciar Sesión').evaluate().isEmpty) {
      print('    Logout...');
      // Ocultar teclado por si acaso
      await tester.tapAt(const Offset(0, 0));
      await settle(tester);

      final logoutIcon = find.byIcon(Icons.logout);
      if (logoutIcon.evaluate().isNotEmpty)
        await tester.tap(logoutIcon);
      else {
        final menu = find.byTooltip('Open navigation menu');
        if (menu.evaluate().isNotEmpty) {
          await tester.tap(menu);
          await settle(tester);
          if (find.text('Cerrar Sesión').evaluate().isNotEmpty)
            await tester.tap(find.text('Cerrar Sesión'));
          else if (find.text('Cerrar sesión').evaluate().isNotEmpty)
            await tester.tap(find.text('Cerrar sesión'));
        }
      }
      await settle(tester);
      if (find.text('Cerrar sesión').evaluate().isNotEmpty)
        await tester.tap(find.text('Cerrar sesión').last);
      await settle(tester);
    }

    if (find.text('Iniciar Sesión').evaluate().isEmpty) {
      // Force restart app state logic via tap corner?
      print('⚠️ Logout falló, intentando continuar igual...');
    }

    // Login
    print('    Login Acudiente...');

    // Ensure fields visible
    await ensureVisible(tester, find.byKey(const Key('emailField')));

    final emailField = find.byKey(const Key('emailField'));
    await tester.tap(emailField);
    await tester.enterText(emailField, CREDS_ACUDI['email']!);

    final passField = find.byKey(const Key('passwordField'));
    await tester.tap(passField);
    await tester.enterText(passField, CREDS_ACUDI['pass']!);

    await tester.tapAt(const Offset(0, 0)); // Cerrar teclado
    await settle(tester);
    await Future.delayed(const Duration(seconds: 2));

    final btn = find.text('Iniciar Sesión');
    await ensureVisible(tester, btn);
    await settle(tester);
    await tester.tap(btn);

    print('    Esperando carga dashboard...');
    await Future.delayed(const Duration(seconds: 10)); // Espera POST-LOGIN
    await tester.pumpAndSettle();

    // Validación Contexto
    if (find.text('Mis Hijos').evaluate().isEmpty) {
      print('    ⚠️ No veo "Mis Hijos". Dump UI:');
      debugDumpApp();
      throw Exception('❌ No se cargó el dashboard de Acudiente');
    }

    // 1. Dashboard
    await binding.takeScreenshot('acudiente_dashboard');
    print('📸 [GUARDADO] acudiente_dashboard.png');

    // 2. Detalle
    final card = find.byType(Card).first;
    if (card.evaluate().isNotEmpty) {
      await tester.tap(card);
      await Future.delayed(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('estudiante_detail');
      print('📸 [GUARDADO] estudiante_detail.png');

      await tester.tap(find.byTooltip('Back'));
      await settle(tester);
    }

    // 3. Settings
    final menu = find.byTooltip('Open navigation menu');
    bool settingsFound = false;

    if (menu.evaluate().isNotEmpty) {
      await tester.tap(menu);
      await settle(tester);
      if (find.text('Ajustes').evaluate().isNotEmpty) {
        await tester.tap(find.text('Ajustes'));
        settingsFound = true;
      }
    }

    if (settingsFound) {
      await settle(tester);
      await binding.takeScreenshot('settings_screen');
      print('📸 [GUARDADO] settings_screen.png');
    }
  }); // test
}
