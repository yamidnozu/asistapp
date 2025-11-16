import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:asistapp/screens/academic/grupos_screen.dart';
import 'package:asistapp/providers/auth_provider.dart';
import 'package:asistapp/providers/grupo_paginated_provider.dart';
import 'package:asistapp/providers/periodo_academico_provider.dart';
import 'package:asistapp/models/grupo.dart';
import 'package:asistapp/config/app_config.dart';
// removed unused import: `academic_service` is not needed in this test

class FakeAuthProvider extends AuthProvider {
  @override
  String? get accessToken => 'FAKE_TOKEN';
}

class FakeGrupoProvider extends GrupoPaginatedProvider {
  bool updateCalled = false;
  bool deleteCalled = false;
  final List<Grupo> initialGrupos;

  FakeGrupoProvider({this.initialGrupos = const []});

  @override
  List<Grupo> get items => initialGrupos;

  @override
  Future<void> loadItems(String accessToken, {int page = 1, int? limit, String? search, Map<String, String>? filters}) async {
    // Avoid network call during tests - return provided initial list
    notifyListeners();
  }

  @override
  Future<bool> updateItem(String accessToken, String id, dynamic data) async {
    updateCalled = true;
    return true;
  }

  @override
  Future<bool> deleteItem(String accessToken, String id) async {
    deleteCalled = true;
    return true;
  }
}

class FakePeriodoProvider extends PeriodoAcademicoProvider {
  final List<PeriodoAcademico> _periodos;
  FakePeriodoProvider(this._periodos);

  @override
  List<PeriodoAcademico> get periodosAcademicos => _periodos;

  @override
  List<PeriodoAcademico> get periodosActivos => _periodos.where((p) => p.activo).toList();

  @override
  Future<void> loadPeriodosActivos(String accessToken) async {
    // no-op to avoid network calls
    notifyListeners();
  }
}

void main() {
  testWidgets('Edit grupo via context menu calls update', (WidgetTester tester) async {
    final fakeAuth = FakeAuthProvider();
    final periodo = PeriodoAcademico(id: 'p1', nombre: '2025', fechaInicio: DateTime.now(), fechaFin: DateTime.now().add(const Duration(days: 365)), activo: true);
    final grupo = Grupo(id: 'g1', nombre: 'Grupo 1', grado: '1ro', seccion: 'A', periodoId: 'p1', institucionId: 'i1', createdAt: DateTime.now(), periodoAcademico: periodo, count: GrupoCount(estudiantesGrupos: 0, horarios: 0));
    final fakeProvider = FakeGrupoProvider(initialGrupos: [grupo]);

  await AppConfig.initialize();

  await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: fakeAuth),
          ChangeNotifierProvider<GrupoPaginatedProvider>.value(value: fakeProvider),
          ChangeNotifierProvider<PeriodoAcademicoProvider>.value(value: FakePeriodoProvider([periodo])),
        ],
        child: const MaterialApp(home: Scaffold(body: GruposScreen())),
      ),
    );

    await tester.pumpAndSettle();

    final menuIcon = find.byIcon(Icons.more_vert).first;
    expect(menuIcon, findsOneWidget);
    await tester.tap(menuIcon);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();

    // Edit dialog visible
    expect(find.text('Editar Grupo'), findsOneWidget);

    // change name
    await tester.enterText(find.byType(TextFormField).first, 'Grupo 1 Editado');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Actualizar'));
    await tester.pumpAndSettle();

    expect(fakeProvider.updateCalled, isTrue);
    expect(find.text('Grupo actualizado correctamente'), findsOneWidget);
  });

  testWidgets('Delete grupo via context menu calls delete and shows snack', (WidgetTester tester) async {
    final fakeAuth = FakeAuthProvider();
    final periodo = PeriodoAcademico(id: 'p1', nombre: '2025', fechaInicio: DateTime.now(), fechaFin: DateTime.now().add(const Duration(days: 365)), activo: true);
    final grupo = Grupo(id: 'g1', nombre: 'Grupo X', grado: '2do', seccion: 'B', periodoId: 'p1', institucionId: 'i1', createdAt: DateTime.now(), periodoAcademico: periodo, count: GrupoCount(estudiantesGrupos: 0, horarios: 0));
    final fakeProvider = FakeGrupoProvider(initialGrupos: [grupo]);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: fakeAuth),
          ChangeNotifierProvider<GrupoPaginatedProvider>.value(value: fakeProvider),
          ChangeNotifierProvider<PeriodoAcademicoProvider>.value(value: FakePeriodoProvider([periodo])),
        ],
        child: const MaterialApp(home: Scaffold(body: GruposScreen())),
      ),
    );

    await tester.pumpAndSettle();

    final menuIcon = find.byIcon(Icons.more_vert).first;
    expect(menuIcon, findsOneWidget);
    await tester.tap(menuIcon);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    // Confirm in dialog
    await tester.tap(find.text('Eliminar').last);
    await tester.pumpAndSettle();

    expect(fakeProvider.deleteCalled, isTrue);
    expect(find.text('Grupo eliminado correctamente'), findsOneWidget);
  });
}
