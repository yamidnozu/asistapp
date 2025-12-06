// ignore_for_file: avoid_print
/// TEST SIMPLE - Solo verifica que la app inicia correctamente
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:asistapp/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App inicia y muestra pantalla de login', (tester) async {
    print('\n═══════════════════════════════════════════════════════════════');
    print('🧪 TEST SIMPLE: Verificar inicio de app');
    print('═══════════════════════════════════════════════════════════════');

    // Iniciar app
    app.main();
    print('  📱 App.main() ejecutado');
    
    // Esperar a que cargue
    await tester.pumpAndSettle(const Duration(seconds: 15));
    print('  ⏳ pumpAndSettle completado');

    // Verificar que llegamos a la pantalla de login
    final emailField = find.byKey(const Key('emailField'));
    final passwordField = find.byKey(const Key('passwordField'));
    final loginButton = find.byKey(const Key('loginButton'));
    
    print('  📍 Buscando campos de login...');
    print('     - emailField encontrado: ${emailField.evaluate().isNotEmpty}');
    print('     - passwordField encontrado: ${passwordField.evaluate().isNotEmpty}');
    print('     - loginButton encontrado: ${loginButton.evaluate().isNotEmpty}');

    expect(emailField, findsOneWidget, reason: 'Debe encontrar el campo de email');
    expect(passwordField, findsOneWidget, reason: 'Debe encontrar el campo de password');
    expect(loginButton, findsOneWidget, reason: 'Debe encontrar el botón de login');

    print('\n✅ Test simple completado exitosamente!');
    print('═══════════════════════════════════════════════════════════════\n');
  });
}
