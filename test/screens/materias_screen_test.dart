import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:asistapp/screens/academic/materias_screen.dart';
import 'package:asistapp/providers/auth_provider.dart';
import 'package:asistapp/providers/materia_provider.dart';
// models imported via provider stubs when needed
import 'package:asistapp/services/academic/materia_service.dart';
import 'package:asistapp/models/materia.dart';

class FakeAuthProvider extends AuthProvider {
  @override
  String? get accessToken => 'FAKE_TOKEN';
}

class FakeMateriaProvider extends MateriaProvider {
  bool createCalled = false;
  bool loadCalled = false;
  bool updateCalled = false;
  bool deleteCalled = false;
  final List<Materia> initialMaterias;

  FakeMateriaProvider({this.initialMaterias = const []});

  @override
  List<Materia> get materias => initialMaterias;

  @override
  Future<void> loadMaterias(String accessToken, {int? page, int? limit, String? search}) async {
    loadCalled = true;
    // Simulate no-op
    notifyListeners();
  }

  @override
  Future<bool> createMateria(String accessToken, CreateMateriaRequest materiaData) async {
    createCalled = true;
    return true;
  }

  @override
  Future<bool> updateMateria(String accessToken, String materiaId, UpdateMateriaRequest materiaData) async {
    updateCalled = true;
    return true;
  }

  @override
  Future<bool> deleteMateria(String accessToken, String materiaId) async {
    deleteCalled = true;
    return true;
  }
}

void main() {
  testWidgets('Open create materia dialog and create succeeds', (WidgetTester tester) async {
    final fakeAuth = FakeAuthProvider();
    fakeAuth.selectInstitution('i1');
    final fakeMaterias = FakeMateriaProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: fakeAuth),
          ChangeNotifierProvider<MateriaProvider>.value(value: fakeMaterias),
        ],
        child: const MaterialApp(
          home: Scaffold(body: MateriasScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final fab = find.byType(FloatingActionButton);
    expect(fab, findsOneWidget);
    await tester.tap(fab);
    await tester.pumpAndSettle();

    // Dialog should be visible
    expect(find.text('Crear Materia'), findsOneWidget);

    // Fill form and tap save
    await tester.enterText(find.byType(TextFormField).first, 'Matemáticas Test');
    await tester.pumpAndSettle();

    final saveButton = find.text('Crear');
    expect(saveButton, findsOneWidget);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Ensure creation was called
    expect(fakeMaterias.createCalled, isTrue);

    // SnackBar success text
    expect(find.text('Materia creada correctamente'), findsOneWidget);
  });

  testWidgets('Open edit materia dialog and update succeeds', (WidgetTester tester) async {
    final fakeAuth = FakeAuthProvider();
    fakeAuth.selectInstitution('i1');
    final materia = Materia(id: 'm1', nombre: 'Matemáticas', institucionId: 'i1', createdAt: DateTime.now());
    final fakeMaterias = FakeMateriaProvider(initialMaterias: [materia]);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: fakeAuth),
          ChangeNotifierProvider<MateriaProvider>.value(value: fakeMaterias),
        ],
        child: const MaterialApp(
          home: Scaffold(body: MateriasScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Open context menu on the first item
    final menuIcon = find.byIcon(Icons.more_vert).first;
    expect(menuIcon, findsOneWidget);
    await tester.tap(menuIcon);
    await tester.pumpAndSettle();

    // Tap Editar
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();

    // Edit dialog should be visible
    expect(find.text('Editar Materia'), findsOneWidget);

    // Change the name
    await tester.enterText(find.byType(TextFormField).first, 'Matemáticas Editada');
    await tester.pumpAndSettle();

    // Save changes
    final updateButton = find.text('Actualizar');
    expect(updateButton, findsOneWidget);
    await tester.tap(updateButton);
    await tester.pumpAndSettle();

    expect(fakeMaterias.updateCalled, isTrue);
    expect(find.text('Materia actualizada correctamente'), findsOneWidget);
  });

  testWidgets('Delete materia from context menu calls delete and shows SnackBar', (WidgetTester tester) async {
    final fakeAuth = FakeAuthProvider();
    fakeAuth.selectInstitution('i1');
    final materia = Materia(id: 'm2', nombre: 'Ciencias', institucionId: 'i1', createdAt: DateTime.now());
    final fakeMaterias = FakeMateriaProvider(initialMaterias: [materia]);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: fakeAuth),
          ChangeNotifierProvider<MateriaProvider>.value(value: fakeMaterias),
        ],
        child: const MaterialApp(
          home: Scaffold(body: MateriasScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final menuIcon = find.byIcon(Icons.more_vert).first;
    expect(menuIcon, findsOneWidget);
    await tester.tap(menuIcon);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    // Confirm delete in dialog
    final confirmDelete = find.text('Eliminar').last;
    expect(confirmDelete, findsOneWidget);
    await tester.tap(confirmDelete);
    await tester.pumpAndSettle();

    expect(fakeMaterias.deleteCalled, isTrue);
    expect(find.text('Materia eliminada correctamente'), findsOneWidget);
  });
}
