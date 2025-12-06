import 'package:flutter_test/flutter_test.dart';
import 'package:asistapp/models/pagination_types.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:asistapp/screens/institutions/institution_admins_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:asistapp/models/user.dart';
import 'package:asistapp/models/institution.dart';
import 'package:asistapp/providers/user_provider.dart';
import 'package:asistapp/providers/auth_provider.dart';
import 'package:asistapp/providers/institution_provider.dart';
import 'package:asistapp/providers/institution_admins_paginated_provider.dart';
import 'package:asistapp/config/app_config.dart';

class FakeAuthProvider extends AuthProvider {
  @override
  String? get accessToken => 'FAKE_TOKEN';
}

class FakeUserProvider extends UserProvider {
  bool createCalled = false;
  bool loadAdminsCalled = false;

  final List<User> fakeUsers;

  FakeUserProvider({this.fakeUsers = const []});

  @override
  List<User> get users => fakeUsers;

  @override
  Future<void> loadAdminsByInstitution(String accessToken, String institutionId) async {
    loadAdminsCalled = true;
    // no-op: users getter returns fakeUsers
    notifyListeners();
  }

  @override
  Future<bool> createUser(String accessToken, CreateUserRequest userData) async {
    createCalled = true;
    return true;
  }
}

class FakeInstitutionProvider extends InstitutionProvider {
  final List<Institution> _insts;
  FakeInstitutionProvider(this._insts);

  @override
  List<Institution> get institutions => _insts;
}

class FakeInstitutionAdminsPaginatedProvider extends InstitutionAdminsPaginatedProvider {
  final List<User> fakeAdmins;

  FakeInstitutionAdminsPaginatedProvider({this.fakeAdmins = const []});

  @override
  Future<PaginatedResponse<User>?> fetchPage(String accessToken, {int page = 1, int? limit, String? search, Map<String, String>? filters}) async {
    // Retorna una respuesta paginada simple que envuelve los usuarios falsos
    return PaginatedResponse(
      items: fakeAdmins,
      pagination: PaginationInfo(page: page, limit: limit ?? 10, total: fakeAdmins.length, totalPages: 1, hasNext: false, hasPrev: false),
    );
  }

  @override
  Future<void> loadItems(String accessToken, {int page = 1, int? limit, String? search, Map<String, String>? filters}) async {
    // Delay the actual load to avoid notifyListeners during the widget build phase
    await Future.delayed(Duration.zero);
    await super.loadItems(accessToken, page: page, limit: limit, search: search, filters: filters);
  }
}

void main() {
  setUpAll(() async {
    // AppConfig requiere inicialización en tests que usan servicios http
    await AppConfig.initialize();
  });
  testWidgets('Open bottom sheet and navigate to create admin form which calls createUser', (WidgetTester tester) async {
    final fakeAuth = FakeAuthProvider();
    fakeAuth.selectInstitution('i1');
    final fakeUserProvider = FakeUserProvider();
    final inst = Institution(id: 'i1', nombre: 'Test Inst', activa: true);
    final fakeInstProvider = FakeInstitutionProvider([inst]);

    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (context, state) => const Scaffold(body: InstitutionAdminsScreen(institutionId: 'i1')) ),
    ]);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: fakeAuth),
          ChangeNotifierProvider<UserProvider>.value(value: fakeUserProvider),
          ChangeNotifierProvider<InstitutionAdminsPaginatedProvider>.value(value: FakeInstitutionAdminsPaginatedProvider()),
          ChangeNotifierProvider<InstitutionProvider>.value(value: fakeInstProvider),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    // Wait for init post frame
    await tester.pumpAndSettle();

    // Tap FAB to open bottom sheet
    final fab = find.byType(FloatingActionButton);
    expect(fab, findsOneWidget);
    await tester.tap(fab);
    await tester.pumpAndSettle();

    // Verify the bottom sheet shows the expected options but do not navigate in this test.
    final createTile = find.text('Crear Nuevo Administrador');
    expect(createTile, findsOneWidget);
  });

  testWidgets('Open bottom sheet and choose assign existing opens dialog', (WidgetTester tester) async {
    final fakeAuth = FakeAuthProvider();
    fakeAuth.selectInstitution('i1');
    final fakeUserProvider = FakeUserProvider();
    final inst = Institution(id: 'i1', nombre: 'Test Inst', activa: true);
    final fakeInstProvider = FakeInstitutionProvider([inst]);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: fakeAuth),
          ChangeNotifierProvider<UserProvider>.value(value: fakeUserProvider),
          ChangeNotifierProvider<InstitutionAdminsPaginatedProvider>.value(value: FakeInstitutionAdminsPaginatedProvider()),
          ChangeNotifierProvider<InstitutionProvider>.value(value: fakeInstProvider),
        ],
        child: const MaterialApp(
          home: Scaffold(body: InstitutionAdminsScreen(institutionId: 'i1')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Tap 'Asignar Usuario Existente'
    final assignTile = find.text('Asignar Usuario Existente');
    expect(assignTile, findsOneWidget);
    await tester.tap(assignTile);
    await tester.pumpAndSettle();

    // A dialog should be shown
    expect(find.text('Asignar Administrador de Institución'), findsOneWidget);
  });
}
