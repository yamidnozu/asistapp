import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:asistapp/main.dart' as app;
import 'dart:io' show Platform;
import 'package:flutter/services.dart';

const CREDS = {'email': 'admin@sanjose.edu', 'pass': 'SanJose123!'};

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  Future<void> settle(WidgetTester tester) async {
    await tester.pumpAndSettle(const Duration(milliseconds: 1000));
  }

  testWidgets('📸 CAPTURA SETTINGS FINAL', (WidgetTester tester) async {
    app.main();
    await Future.delayed(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    if (Platform.isAndroid) {
      try {
        await binding.convertFlutterSurfaceToImage();
      } catch (_) {}
    }

    // Login Admin (Dashboard -> Settings es facil)
    if (find.text('Iniciar Sesión').evaluate().isNotEmpty) {
      final emailField = find.byKey(const Key('emailField'));
      await tester.tap(emailField);
      await tester.enterText(emailField, CREDS['email']!);

      final passField = find.byKey(const Key('passwordField'));
      await tester.tap(passField);
      await tester.enterText(passField, CREDS['pass']!);

      await tester.tapAt(const Offset(0, 0));
      await settle(tester);
      await tester.tap(find.text('Iniciar Sesión'));
      await Future.delayed(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    }

    // Ir a Settings
    print('    Navegando a Ajustes...');
    final menu = find.byTooltip('Open navigation menu');
    bool found = false;

    if (menu.evaluate().isNotEmpty) {
      await tester.tap(menu);
      await settle(tester);
      if (find.text('Ajustes').evaluate().isNotEmpty) {
        await tester.tap(find.text('Ajustes'));
        found = true;
      }
    }

    if (!found) {
      // Try scroll
      final s = find.byType(SingleChildScrollView); // Drawer scroll?
      if (s.evaluate().isNotEmpty) {
        await tester.drag(s.first, const Offset(0, -300));
        await settle(tester);
        if (find.text('Ajustes').evaluate().isNotEmpty) {
          await tester.tap(find.text('Ajustes'));
          found = true;
        }
      }
    }

    if (found) {
      await settle(tester);
      // Validar título
      if (find.text('Ajustes').evaluate().isNotEmpty ||
          find.text('Configuración').evaluate().isNotEmpty) {
        await binding.takeScreenshot('settings_screen');
        print('📸 [GUARDADO] settings_screen.png');
      }
    }
  });
}
