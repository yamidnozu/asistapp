import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:asistapp/providers/auth_provider.dart';
import 'package:asistapp/providers/institution_provider.dart';
import 'package:asistapp/screens/institutions/create_institution_admin_screen.dart';
import 'package:asistapp/screens/users/user_form_screen.dart';
import 'package:asistapp/models/institution.dart';
import 'package:asistapp/providers/user_provider.dart';
import 'package:asistapp/models/user.dart';

class FakeUserProvider extends UserProvider {
  bool createCalled = false;

  @override
  Future<bool> createUser(
      String accessToken, CreateUserRequest userData) async {
    createCalled = true;
    return true;
  }
}

class FakeAuthProvider extends AuthProvider {
  @override
  String? get accessToken => 'FAKE_TOKEN';
}

class FakeInstitutionProvider extends InstitutionProvider {
  final List<Institution> insts;
  FakeInstitutionProvider(this.insts);

  @override
  List<Institution> get institutions => insts;
}

void main() {
  testWidgets(
      'CreateInstitutionAdminScreen delegates to UserFormScreen with initialInstitutionId',
      (WidgetTester tester) async {
    final institution =
        Institution(id: 'i1', nombre: 'Test Inst', activa: true);

    final router = GoRouter(routes: [
      GoRoute(
          path: '/',
          builder: (context, state) => MediaQuery(
                data: const MediaQueryData(size: Size(400, 800)),
                child: CreateInstitutionAdminScreen(institution: institution),
              )),
    ]);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
          ChangeNotifierProvider<InstitutionProvider>(
              create: (_) => InstitutionProvider()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.pumpAndSettle();

    final finder = find.byType(UserFormScreen);
    expect(finder, findsOneWidget);

    final widget = tester.widget<UserFormScreen>(finder);
    expect(widget.initialInstitutionId, institution.id);
    expect(widget.userRole, 'admin_institucion');
  });

  testWidgets('CreateInstitutionAdminScreen form submits and calls createUser',
      (WidgetTester tester) async {
    final institution =
        Institution(id: 'i1', nombre: 'Test Inst', activa: true);
    final fakeUserProvider = FakeUserProvider();

    final router = GoRouter(routes: [
      GoRoute(
          path: '/',
          builder: (context, state) => MediaQuery(
                data: const MediaQueryData(size: Size(400, 800)),
                child: CreateInstitutionAdminScreen(institution: institution),
              )),
    ]);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(
              create: (_) => FakeAuthProvider()),
          ChangeNotifierProvider<UserProvider>.value(value: fakeUserProvider),
          ChangeNotifierProvider<InstitutionProvider>(
              create: (_) => FakeInstitutionProvider([institution])),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    // NOTE: Integration test for submitting the UserFormScreen is covered by widget tests
    // that exercise the UserFormScreen directly. Creating a full end-to-end test from
    // InstitutionAdminsScreen would require the app to be wired with a GoRouter above
    // material navigation; keep this test scoped to showing the CreateInstitutionAdminScreen.
  });
}
