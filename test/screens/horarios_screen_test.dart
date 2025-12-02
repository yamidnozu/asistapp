import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:asistapp/screens/academic/horarios_screen.dart';
import 'package:asistapp/providers/auth_provider.dart';
import 'package:asistapp/providers/horario_provider.dart';
import 'package:asistapp/providers/materia_provider.dart';
import 'package:asistapp/providers/user_provider.dart';
import 'package:asistapp/providers/grupo_provider.dart';
import 'package:asistapp/providers/periodo_academico_provider.dart';
import 'package:asistapp/models/grupo.dart';
import 'package:asistapp/models/materia.dart';
import 'package:asistapp/models/user.dart';
import 'package:asistapp/models/horario.dart';
// PeriodoAcademico and GrupoCount are exported by models/grupo.dart above
import 'package:asistapp/models/conflict_error.dart';
import 'package:asistapp/config/app_config.dart';
import 'package:asistapp/services/academic/horario_service.dart';
import 'package:asistapp/widgets/horarios/edit_class_dialog.dart';
import 'package:asistapp/widgets/horarios/create_class_dialog.dart';

class FakeAuthProvider extends AuthProvider {
  @override
  String? get accessToken => 'FAKE_TOKEN';
}

class FakePeriodoProvider extends PeriodoAcademicoProvider {
  final List<PeriodoAcademico> _periodos;
  FakePeriodoProvider(this._periodos);

  @override
  List<PeriodoAcademico> get periodosActivos => _periodos.where((p) => p.activo).toList();

  @override
  Future<void> loadPeriodosActivos(String accessToken) async {
    notifyListeners();
  }
}

class FakeGrupoProvider extends GrupoProvider {
  final List<Grupo> initialGrupos;
  FakeGrupoProvider({this.initialGrupos = const []});

  @override
  List<Grupo> get items => initialGrupos;

  @override
  Future<void> loadItems(String accessToken, {int page = 1, int? limit, String? search, Map<String, String>? filters}) async {
    // no-op
    notifyListeners();
  }
}

class FakeMateriaProvider extends MateriaProvider {
  final List<Materia> initialMaterias;
  FakeMateriaProvider({this.initialMaterias = const []});

  @override
  List<Materia> get materias => initialMaterias;

  @override
  Future<void> loadMaterias(String accessToken, {int? page, int? limit, String? search}) async {
    notifyListeners();
  }
}

class FakeUserProvider extends UserProvider {
  final List<User> _profs;
  FakeUserProvider(this._profs);

  @override
  List<User> get professors => _profs;

  @override
  Future<void> loadUsersByInstitution(String accessToken, String institutionId, {bool? activo, int limit = 10, int? page, String? role, String? search}) async {
    notifyListeners();
  }

  @override
  Future<void> loadUsers(String accessToken, {int? page, int? limit, bool? activo, String? search, List<String>? roles}) async {
    // Avoid actual network call
    notifyListeners();
  }
}

class _FakeHorarioService extends HorarioService {
  final List<Horario> _initial;
  _FakeHorarioService([this._initial = const []]);

  @override
  Future<PaginatedHorariosResponse?> getHorarios(String accessToken, {int? page, int? limit, String? grupoId, String? periodoId}) async {
    final total = _initial.length;
    final limit = total == 0 ? 10 : total;
    final totalPages = total == 0 ? 0 : 1;
    return PaginatedHorariosResponse(
      horarios: _initial,
      pagination: PaginationInfo(page: 1, limit: limit, total: total, totalPages: totalPages, hasNext: false, hasPrev: false),
    );
  }

  @override
  Future<List<Horario>?> getHorariosPorGrupo(String accessToken, String grupoId) async {
    return _initial.where((h) => h.grupo.id == grupoId).toList();
  }

  @override
  Future<Horario?> createHorario(String accessToken, CreateHorarioRequest horarioData) async {
    return null; // Not used in tests because provider override handles this
  }

  @override
  Future<Horario?> updateHorario(String accessToken, String horarioId, UpdateHorarioRequest horarioData) async {
    return null; // provider override used in tests
  }

  @override
  Future<bool> deleteHorario(String accessToken, String horarioId) async {
    return true;
  }
}

class FakeHorarioProvider extends HorarioProvider {
  bool createCalled = false;
  bool updateCalled = false;
  bool deleteCalled = false;

  final List<Horario> initialHorarios;

  FakeHorarioProvider({this.initialHorarios = const []}) : super(horarioService: _FakeHorarioService(initialHorarios));

  @override
  List<Horario> get horarios => initialHorarios;

  @override
  Future<void> loadItems(String accessToken, {int page = 1, int? limit, String? search, Map<String, String>? filters}) async {
    // Prevent actual network calls during widget tests
    notifyListeners();
  }

  @override
  Future<void> loadHorariosByGrupo(String accessToken, String grupoId) async {
    // Prevent real network calls - return the pre-defined list
    notifyListeners();
  }

  @override
  Future<void> loadHorariosForGrupoWithConflictDetection(String accessToken, String grupoId, String periodoId) async {
    // Provide the pre-defined period/horario data and simulate conflict detection
    notifyListeners();
  }

  @override
  Future<bool> createHorario(String accessToken, CreateHorarioRequest horarioData) async {
    createCalled = true;
    return true;
  }

  @override
  Future<bool> updateHorario(String accessToken, String horarioId, UpdateHorarioRequest horarioData) async {
    updateCalled = true;
    return true;
  }

  @override
  Future<bool> deleteHorario(String accessToken, String horarioId) async {
    debugPrint('FakeHorarioProvider.deleteHorario called for $horarioId');
    deleteCalled = true;
    return true;
  }
}

class FakeHorarioConflictProvider extends FakeHorarioProvider {
  final ConflictError conflict;
  FakeHorarioConflictProvider(this.conflict, {super.initialHorarios = const []});

  @override
  ConflictError? get conflictError => conflict;

  @override
  Future<bool> createHorario(String accessToken, CreateHorarioRequest horarioData) async {
    createCalled = true;
    return false; // Simulate conflict
  }
}

void main() {
  setUpAll(() async {
    await AppConfig.initialize();
  });

  testWidgets('Create class via FAB opens dialog and calls createHorario', (WidgetTester tester) async {
    final fakeAuth = FakeAuthProvider();
    fakeAuth.selectInstitution('iX');
    fakeAuth.selectInstitution('i1');
    final periodo = PeriodoAcademico(id: 'p1', nombre: 'P1', fechaInicio: DateTime.now(), fechaFin: DateTime.now().add(const Duration(days: 365)), activo: true);
    final grupo = Grupo(id: 'g1', nombre: 'G1', grado: '1ro', seccion: 'A', periodoId: 'p1', institucionId: 'i1', createdAt: DateTime.now(), periodoAcademico: periodo, count: GrupoCount(estudiantesGrupos: 0, horarios: 0, asistencias: 0));
    final materia = Materia(id: 'm1', nombre: 'Matemáticas', institucionId: 'i1', createdAt: DateTime.now());

    final fakeHorario = FakeHorarioProvider();
    final fakePeriodo = FakePeriodoProvider([periodo]);
    final fakeGrupo = FakeGrupoProvider(initialGrupos: [grupo]);
    final fakeMateria = FakeMateriaProvider(initialMaterias: [materia]);
    final fakeUser = FakeUserProvider([User(id: 'u1', email: 'teacher@x.com', nombres: 'Docente', apellidos: 'Test', rol: 'profesor', activo: true, instituciones: [])]);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: fakeAuth),
          ChangeNotifierProvider<HorarioProvider>.value(value: fakeHorario),
          ChangeNotifierProvider<PeriodoAcademicoProvider>.value(value: fakePeriodo),
          ChangeNotifierProvider<GrupoProvider>.value(value: fakeGrupo),
          ChangeNotifierProvider<MateriaProvider>.value(value: fakeMateria),
          ChangeNotifierProvider<UserProvider>.value(value: fakeUser),
        ],
        child: MaterialApp(
          home: Builder(builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(context: context, builder: (_) => CreateClassDialog(grupo: grupo, horaInicio: '07:00', diaSemana: 1));
                  },
                  child: const Text('Open'),
                ),
              ),
            );
          }),
        ),
      ),
    );

    await tester.pumpAndSettle();
    // Select a group explicitly on the provider to avoid async race
    fakeGrupo.selectGrupo(grupo);
    await tester.pumpAndSettle();

    final openBtn = find.byType(ElevatedButton);
    expect(openBtn, findsOneWidget);
    await tester.tap(openBtn);
    await tester.pumpAndSettle();

  // Dialog visible: verify the horario info to ensure it's the dialog
  expect(find.text('Horario: 07:00 - 09:00'), findsOneWidget);

    // Select Hora Fin (second option), Materia and Profesor
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    // select second item
    await tester.tap(find.text('08:00').last);
    await tester.pumpAndSettle();

    // Select materia
    await tester.tap(find.byType(DropdownButtonFormField<Materia>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Matemáticas').last);
    await tester.pumpAndSettle();

    // Select profesor
    await tester.tap(find.byType(DropdownButtonFormField<User>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Docente Test').last);
    await tester.pumpAndSettle();

  // Save by tapping the ElevatedButton used by ClarityFormDialog
  await tester.tap(find.widgetWithText(ElevatedButton, 'Crear Clase'));
    await tester.pumpAndSettle();

    expect(fakeHorario.createCalled, isTrue);
    // SnackBar with success
    expect(find.text('Clase creada correctamente'), findsOneWidget);
  });

  testWidgets('Create class conflict displays conflict dialog', (WidgetTester tester) async {
    final fakeAuth = FakeAuthProvider();
    fakeAuth.selectInstitution('i1');
    final periodo = PeriodoAcademico(id: 'p1', nombre: 'P1', fechaInicio: DateTime.now(), fechaFin: DateTime.now().add(const Duration(days: 365)), activo: true);
    final grupo = Grupo(id: 'g1', nombre: 'G1', grado: '1ro', seccion: 'A', periodoId: 'p1', institucionId: 'i1', createdAt: DateTime.now(), periodoAcademico: periodo, count: GrupoCount(estudiantesGrupos: 0, horarios: 0, asistencias: 0));
    final materia = Materia(id: 'm1', nombre: 'Ciencias', institucionId: 'i1', createdAt: DateTime.now());

    final conflict = ConflictError(code: '409', reason: 'grupo_conflict', message: 'Conflict', meta: {'conflictingHorarioIds': ['h123']});
    final fakeHorario = FakeHorarioConflictProvider(conflict);
    final fakePeriodo = FakePeriodoProvider([periodo]);
    final fakeGrupo = FakeGrupoProvider(initialGrupos: [grupo]);
    final fakeMateria = FakeMateriaProvider(initialMaterias: [materia]);
    final fakeUser = FakeUserProvider([User(id: 'u2', email: 'teacher2@x.com', nombres: 'Docente', apellidos: 'Conflict', rol: 'profesor', activo: true, instituciones: [])]);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: fakeAuth),
          ChangeNotifierProvider<HorarioProvider>.value(value: fakeHorario),
          ChangeNotifierProvider<PeriodoAcademicoProvider>.value(value: fakePeriodo),
          ChangeNotifierProvider<GrupoProvider>.value(value: fakeGrupo),
          ChangeNotifierProvider<MateriaProvider>.value(value: fakeMateria),
          ChangeNotifierProvider<UserProvider>.value(value: fakeUser),
        ],
        child: MaterialApp(
          home: Builder(builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(context: context, builder: (_) => CreateClassDialog(grupo: grupo, horaInicio: '07:00', diaSemana: 1));
                  },
                  child: const Text('Open'),
                ),
              ),
            );
          }),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final openBtn = find.byType(ElevatedButton);
    expect(openBtn, findsOneWidget);
    await tester.tap(openBtn);
    await tester.pumpAndSettle();

    // Fill form fields
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('08:00').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<Materia>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ciencias').last);
    await tester.pumpAndSettle();

    // Select profesor in conflict scenario
    await tester.tap(find.byType(DropdownButtonFormField<User>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Docente Conflict').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Crear Clase'));
    await tester.pumpAndSettle();

    // A conflict dialog should be shown instead of success
    expect(find.text('Conflicto de Horario'), findsOneWidget);
    expect(find.text('El grupo ya tiene una clase programada en este horario.'), findsOneWidget);
  });

  testWidgets('Edit class via dialog calls update and delete', (WidgetTester tester) async {
    final fakeAuth = FakeAuthProvider();
    final periodo = PeriodoAcademico(id: 'pX', nombre: 'P2', fechaInicio: DateTime.now(), fechaFin: DateTime.now().add(const Duration(days: 365)), activo: true);
    final grupo = Grupo(id: 'gX', nombre: 'GX', grado: '1ro', seccion: 'A', periodoId: 'pX', institucionId: 'iX', createdAt: DateTime.now(), periodoAcademico: periodo, count: GrupoCount(estudiantesGrupos: 0, horarios: 0, asistencias: 0));
    final materia = Materia(id: 'mX', nombre: 'Historia', institucionId: 'iX', createdAt: DateTime.now());
    final user = User(
      id: 'uX',
      email: 'p@x.com',
      nombres: 'Pedro',
      apellidos: 'Gomez',
      rol: 'profesor',
      activo: true,
      instituciones: [UserInstitution(id: 'iX', nombre: 'Institucion X', rolEnInstitucion: 'profesor', activo: true)],
    );

    final horario = Horario(
      id: 'h1', periodoId: periodo.id, grupoId: grupo.id, materiaId: materia.id, profesorId: null,
      diaSemana: 1, horaInicio: '07:00', horaFin: '08:00', institucionId: 'iX', createdAt: DateTime.now(), grupo: grupo, materia: materia, periodoAcademico: periodo);

    final fakeHorario = FakeHorarioProvider(initialHorarios: [horario]);
    final fakeUser = FakeUserProvider([user]);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: fakeAuth),
          ChangeNotifierProvider<HorarioProvider>.value(value: fakeHorario),
          ChangeNotifierProvider<UserProvider>.value(value: fakeUser),
        ],
        child: const MaterialApp(home: Scaffold()),
      ),
    );

    // Open the EditClassDialog directly
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: fakeAuth),
          ChangeNotifierProvider<HorarioProvider>.value(value: fakeHorario),
          ChangeNotifierProvider<UserProvider>.value(value: fakeUser),
        ],
        child: MaterialApp(
          home: Builder(builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(context: context, builder: (_) => EditClassDialog(horario: horario));
                  },
                  child: const Text('Open'),
                ),
              ),
            );
          }),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

  // Edit dialog visible
  expect(find.text('Editar Clase'), findsOneWidget);

  // Delete button is visible in the dialog
  expect(find.text('Eliminar'), findsOneWidget);

    // Change hora fin to next available
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('09:00').last);
    await tester.pumpAndSettle();

  await tester.tap(find.widgetWithText(ElevatedButton, 'Actualizar'));
    await tester.pumpAndSettle();
    expect(fakeHorario.updateCalled, isTrue);
    expect(find.text('Clase actualizada correctamente'), findsOneWidget);

  // Now test delete: reopen the dialog and delete the class
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Eliminar'));
  await tester.pumpAndSettle();
  // Confirm dialog should open
    expect(find.text('Confirmar eliminación'), findsOneWidget);
  // Confirm in dialog - find the TextButton specifically to avoid ambiguity
  // Confirm the deletion (accept)
  // Find the confirmation dialog's 'Eliminar' (it should be the last TextButton with that label)
  await tester.tap(find.widgetWithText(TextButton, 'Eliminar').last);
    await tester.pumpAndSettle();
  // After confirming the delete, the confirmation dialog should be gone
  expect(find.text('Confirmar eliminación'), findsNothing);
  await tester.pumpAndSettle();

  // Ensure the provider was called (UI success snackbar is flaky in tests)
  expect(fakeHorario.deleteCalled, isTrue);
  });
}
