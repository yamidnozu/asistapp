// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:asistapp/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Limpia el estado de autenticación
  Future<void> clearAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
    await prefs.remove('user');
    await prefs.remove('selectedInstitutionId');
  }

  /// Login genérico
  Future<void> loginAs(WidgetTester tester, String email, String password) async {
    print('[LOGIN] Iniciando sesión con: $email');
    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(0), email);
    await tester.enterText(textFields.at(1), password);
    await tester.pumpAndSettle();
    final buttons = find.byType(ElevatedButton);
    await tester.tap(buttons.first);
    await tester.pumpAndSettle(const Duration(seconds: 5));
    print('✅ Login completado');
  }

  /// Logout
  Future<void> performLogout(WidgetTester tester) async {
    final logoutButton = find.byIcon(Icons.logout);
    if (logoutButton.evaluate().isNotEmpty) {
      await tester.tap(logoutButton.first);
      await tester.pumpAndSettle(const Duration(seconds: 3));
    }
    print('✅ Logout completado');
  }

  /// Navegar a sección
  Future<bool> navigateTo(WidgetTester tester, String sectionName) async {
    final navButton = find.text(sectionName);
    if (navButton.evaluate().isNotEmpty) {
      await tester.tap(navButton.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      return true;
    }
    return false;
  }

  group('🔐 Autenticación', () {
    setUp(() async => await clearAuthState());

    testWidgets('Flujo 1: Login exitoso', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      await loginAs(tester, 'superadmin@asistapp.com', 'Admin123!');
      expect(find.textContaining('Dashboard'), findsWidgets);
      await performLogout(tester);
    });

    testWidgets('Flujo 2: Login fallido', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      await loginAs(tester, 'superadmin@asistapp.com', 'WrongPass!');
      expect(find.textContaining('error'), findsWidgets);
    });
  });

  group('🏫 Instituciones', () {
    setUp(() async => await clearAuthState());

    testWidgets('Flujo 4: Listar instituciones', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      await loginAs(tester, 'superadmin@asistapp.com', 'Admin123!');
      await navigateTo(tester, 'Instituciones');
      expect(find.byType(Card), findsWidgets);
      await performLogout(tester);
    });
  });
}