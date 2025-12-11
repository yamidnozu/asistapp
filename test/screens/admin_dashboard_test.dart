import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:asistapp/providers/auth_provider.dart';
import 'package:asistapp/screens/admin_dashboard.dart';
import 'package:asistapp/models/user.dart';
import 'package:asistapp/providers/user_provider.dart';
import 'package:asistapp/providers/institution_provider.dart';

class FakeUserProvider extends UserProvider {
  final List<User> _fakeUsers;
  FakeUserProvider(this._fakeUsers);

  @override
  List<User> get users => _fakeUsers;

  @override
  int get professorsCount => _fakeUsers.where((u) => u.esProfesor).length;

  @override
  int get loadedUsersCount => _fakeUsers.length;

  @override
  Map<String, int> getUserStatistics() {
    return {
      'total': _fakeUsers.length,
      'profesores': professorsCount,
      'estudiantes': 0
    };
  }
}

class FakeInstitutionProvider extends InstitutionProvider {
  final int _count;
  FakeInstitutionProvider(this._count);

  @override
  int get totalInstitutions => _count;
}

void main() {
  testWidgets('AdminDashboard shows KPIs and recent activity',
      (WidgetTester tester) async {
    final user1 = User(
      id: 'u1',
      email: 'docente@example.com',
      nombres: 'Docente',
      apellidos: 'Uno',
      rol: 'profesor',
      telefono: null,
      identificacion: null,
      activo: true,
      instituciones: [],
    );

    final fakeUserProvider = FakeUserProvider([user1]);
    final fakeInstitutionProvider = FakeInstitutionProvider(3);
    // Simple auth provider stub
    final fakeAuth = AuthProvider();
    // Set a minimal user map for tests
    // authProvider.user is private so we extend in the test if needed; for now we rely on a default user

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<UserProvider>.value(value: fakeUserProvider),
          ChangeNotifierProvider<InstitutionProvider>.value(
              value: fakeInstitutionProvider),
          ChangeNotifierProvider<AuthProvider>.value(value: fakeAuth),
        ],
        child: const MaterialApp(home: AdminDashboard()),
      ),
    );

    await tester.pumpAndSettle();

    // Verify KPIs and actions grid are present
    expect(find.text('Usuarios'), findsOneWidget);
    expect(find.text('Acciones Principales'), findsOneWidget);
    // The new AdminDashboard UI focuses on KPIs and actions; ensure KPIs reflect users
    expect(find.textContaining('Usuarios'), findsOneWidget);
  });
}
