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

  testWidgets('📸 CAPTURA FINAL ACUDIENTE (RETRY)',
      (WidgetTester tester) async {
    app.main();
    // Espera larga inicial para estabilizar Firebase/Emulador
    await Future.delayed(const Duration(seconds: 10));
    await tester.pumpAndSettle();

    if (Platform.isAndroid) {
      try {
        await binding.convertFlutterSurfaceToImage();
      } catch (_) {}
    }

    // Logout robusto si es necesario
    if (find.text('Iniciar Sesión').evaluate().isEmpty) {
      print('    Ensuring Logout...');
      final logoutIcon = find.byIcon(Icons.logout);
      if (logoutIcon.evaluate().isNotEmpty)
        await tester.tap(logoutIcon);
      else {
        // Menú hamburguesa si está en mobile
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

    // Login Acudiente
    print('    Login Acudiente...');
    final emailField = find.byKey(const Key('emailField'));
    await tester.tap(emailField);
    await tester.enterText(emailField, CREDS_ACUDI['email']!);

    final passField = find.byKey(const Key('passwordField'));
    await tester.tap(passField);
    await tester.enterText(passField, CREDS_ACUDI['pass']!);

    await tester.tapAt(const Offset(0, 0)); // Cerrar teclado
    await settle(tester);

    await tester.tap(find.text('Iniciar Sesión'));
    await Future.delayed(
        const Duration(seconds: 8)); // Espera generosa post-login
    await tester.pumpAndSettle();

    // Validación Contexto (Zero Trust)
    if (find.text('Mis Hijos').evaluate().isEmpty) {
      throw Exception(
          '❌ No se cargó el dashboard de Acudiente (No veo "Mis Hijos")');
    }

    // 1. Dashboard
    await binding.takeScreenshot('acudiente_dashboard');
    print('📸 [GUARDADO] acudiente_dashboard.png');

    // 2. Detalle Estudiante
    final card = find.byType(Card).first;
    if (card.evaluate().isNotEmpty) {
      await tester.tap(card);
      await settle(tester);
      if (find.text('Estadísticas').evaluate().isNotEmpty ||
          find.text('Historial').evaluate().isNotEmpty) {
        await binding.takeScreenshot('estudiante_detail');
        print('📸 [GUARDADO] estudiante_detail.png');
      }
      await tester.tap(find.byTooltip('Back'));
      await settle(tester);
    }

    // 3. Settings (Ajustes)
    // Buscar en drawer o icono
    final menu = find.byTooltip('Open navigation menu');
    bool settingsFound = false;

    if (menu.evaluate().isNotEmpty) {
      await tester.tap(menu);
      await settle(tester);
      if (find.text('Ajustes').evaluate().isNotEmpty) {
        await tester.tap(find.text('Ajustes'));
        settingsFound = true;
      }
    } else if (find.byIcon(Icons.settings).evaluate().isNotEmpty) {
      await tester.tap(find.byIcon(Icons.settings));
      settingsFound = true;
    }

    if (settingsFound) {
      await settle(tester);
      await binding.takeScreenshot('settings_screen');
      print('📸 [GUARDADO] settings_screen.png');

      // Logout desde settings (botón rojo Cerrar Sesión)
      // Ajustes suele tener botón de cerrar sesión
      // No hacemos nada, el test termina.
    } else {
      print('⚠️ No encontré acceso a Ajustes para captura');
    }
  });
}
