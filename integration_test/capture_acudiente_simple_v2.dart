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
    await tester.pumpAndSettle();
    await Future.delayed(Duration(milliseconds: 2000));
  }

  testWidgets('📸 CAPTURA SIMPLE ACUDIENTE V2', (WidgetTester tester) async {
    app.main();
    await settle(tester);

    if (Platform.isAndroid) {
      try {
        await binding.convertFlutterSurfaceToImage();
      } catch (_) {}
    }

    // Logout si es necesario
    if (find.text('Iniciar Sesión').evaluate().isEmpty) {
      final logoutIcon = find.byIcon(Icons.logout);
      if (logoutIcon.evaluate().isNotEmpty)
        await tester.tap(logoutIcon);
      else {
        await tester.tapAt(const Offset(380, 50)); // corner
        await settle(tester);
        if (find.text('Cerrar sesión').evaluate().isNotEmpty)
          await tester.tap(find.text('Cerrar sesión'));
      }
      await settle(tester);
      if (find.text('Cerrar sesión').evaluate().isNotEmpty)
        await tester.tap(find.text('Cerrar sesión').last);
      await settle(tester);
    }

    // Login
    final emailField = find.byKey(const Key('emailField'));
    await tester.tap(emailField);
    await tester.enterText(emailField, CREDS_ACUDI['email']!);

    final passField = find.byKey(const Key('passwordField'));
    await tester.tap(passField);
    await tester.enterText(passField, CREDS_ACUDI['pass']!);

    await tester.tapAt(const Offset(0, 0));
    await settle(tester);

    await tester.tap(find.text('Iniciar Sesión'));
    await settle(tester);
    await Future.delayed(Duration(seconds: 5));

    await settle(tester);
    await binding.takeScreenshot('acudiente_dashboard');
    print('📸 [GUARDADO] acudiente_dashboard.png');

    final card = find.byType(Card).first;
    if (card.evaluate().isNotEmpty) {
      await tester.tap(card);
      await settle(tester);
      await binding.takeScreenshot('estudiante_detail');
      print('📸 [GUARDADO] estudiante_detail.png');
      await tester.tap(find.byTooltip('Back'));
      await settle(tester);
    }

    final menu = find.byTooltip('Open navigation menu');
    if (menu.evaluate().isNotEmpty) {
      await tester.tap(menu);
      await settle(tester);
      await binding.takeScreenshot('settings_screen');
      print('📸 [GUARDADO] settings_screen.png');
    }
  });
}
