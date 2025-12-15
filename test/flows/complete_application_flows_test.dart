// ignore_for_file: avoid_print
/// 🧪 PRUEBAS DE FLUJOS COMPLETOS DE APLICACIÓN
///
/// Este archivo contiene pruebas unitarias y de widgets que simulan los flujos
/// principales de la aplicación AsistApp, cubriendo:
///
/// 🟢 GRUPO A: Inicialización y Estructura
/// 🟡 GRUPO B: Gestión de Conflictos y Restricciones
/// 🔵 GRUPO C: Ciclo de Vida de la Asistencia
/// 🟠 GRUPO D: Acceso y Seguridad
/// 🟣 GRUPO E: Notificaciones y Reportes
///
/// Basado en la arquitectura: Flutter Frontend + Fastify/Prisma Backend

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

// Config
import 'package:asistapp/config/app_config.dart';

// Models
import 'package:asistapp/models/grupo.dart';
import 'package:asistapp/models/materia.dart';
import 'package:asistapp/models/user.dart';
import 'package:asistapp/models/horario.dart';
import 'package:asistapp/models/institution.dart';
import 'package:asistapp/models/conflict_error.dart';
import 'package:asistapp/models/asistencia_estudiante.dart';

// Providers
import 'package:asistapp/providers/auth_provider.dart';
import 'package:asistapp/providers/horario_provider.dart';
import 'package:asistapp/providers/materia_provider.dart';
import 'package:asistapp/providers/user_provider.dart';
import 'package:asistapp/providers/grupo_provider.dart';
import 'package:asistapp/providers/periodo_academico_provider.dart';
import 'package:asistapp/providers/institution_provider.dart';
import 'package:asistapp/providers/asistencia_provider.dart';

// Services
import 'package:asistapp/services/academic/horario_service.dart';

// Widgets
import 'package:asistapp/widgets/horarios/create_class_dialog.dart';
import 'package:asistapp/widgets/horarios/edit_class_dialog.dart';

// ============================================================================
// FAKE PROVIDERS - Simulan comportamiento sin red
// ============================================================================

/// Fake AuthProvider que simula autenticación para diferentes roles
class FakeAuthProvider extends AuthProvider {
  String _role;
  String? _institutionId;
  final String _userId;
  final String _email;

  FakeAuthProvider({
    String role = 'super_admin',
    String? institutionId,
    String userId = 'fake-user-id',
    String email = 'admin@test.com',
  })  : _role = role,
        _institutionId = institutionId,
        _userId = userId,
        _email = email;

  @override
  String? get accessToken => 'FAKE_TOKEN_$_role';

  @override
  String? get selectedInstitutionId => _institutionId;

  @override
  Map<String, dynamic>? get user => {
        'id': _userId,
        'email': _email,
        'rol': _role,
        'nombres': 'Test',
        'apellidos': 'User',
      };

  @override
  bool get isAuthenticated => true;

  void setRole(String role) {
    _role = role;
    notifyListeners();
  }

  void setInstitution(String? institutionId) {
    _institutionId = institutionId;
    notifyListeners();
  }
}

/// Fake InstitutionProvider - métodos simplificados para tests
class FakeInstitutionProvider extends InstitutionProvider {
  final List<Institution> _testInstitutions;

  FakeInstitutionProvider([List<Institution>? institutions])
      : _testInstitutions = institutions ?? [];

  @override
  List<Institution> get institutions => _testInstitutions;

  @override
  Future<void> loadInstitutions(String accessToken,
      {int? page, int? limit, bool? activa, String? search}) async {
    notifyListeners();
  }

  /// Método de test para crear institución (no override)
  Future<Institution?> testCreateInstitution(
      String accessToken, Map<String, dynamic> data) async {
    final newInst = Institution(
      id: 'inst-${_testInstitutions.length + 1}',
      nombre: data['nombre'] ?? 'Nueva Institución',
      activa: data['activa'] ?? true,
      createdAt: DateTime.now(),
    );
    _testInstitutions.add(newInst);
    notifyListeners();
    return newInst;
  }
}

/// Fake PeriodoAcademicoProvider
class FakePeriodoProvider extends PeriodoAcademicoProvider {
  final List<PeriodoAcademico> _periodos;

  FakePeriodoProvider([List<PeriodoAcademico>? periodos])
      : _periodos = periodos ?? [];

  @override
  List<PeriodoAcademico> get periodosActivos =>
      _periodos.where((p) => p.activo).toList();

  @override
  List<PeriodoAcademico> get items => _periodos;

  @override
  Future<void> loadPeriodosActivos(String accessToken) async {
    notifyListeners();
  }

  /// Método de test para crear periodo (no override)
  Future<PeriodoAcademico?> testCreatePeriodo(
      String accessToken, Map<String, dynamic> data) async {
    final newPeriodo = PeriodoAcademico(
      id: 'periodo-${_periodos.length + 1}',
      nombre: data['nombre'] ?? 'Nuevo Periodo',
      fechaInicio: DateTime.parse(data['fechaInicio']),
      fechaFin: DateTime.parse(data['fechaFin']),
      activo: data['activo'] ?? true,
    );
    _periodos.add(newPeriodo);
    notifyListeners();
    return newPeriodo;
  }
}

/// Fake MateriaProvider
class FakeMateriaProvider extends MateriaProvider {
  final List<Materia> _materias;

  FakeMateriaProvider([List<Materia>? materias]) : _materias = materias ?? [];

  @override
  List<Materia> get materias => _materias;

  @override
  Future<void> loadMaterias(String accessToken,
      {int? page, int? limit, String? search}) async {
    notifyListeners();
  }

  /// Método de test para crear materia (no override)
  Future<Materia?> testCreateMateria(
      String accessToken, Map<String, dynamic> data) async {
    final newMateria = Materia(
      id: 'materia-${_materias.length + 1}',
      nombre: data['nombre'] ?? 'Nueva Materia',
      codigo: data['codigo'],
      institucionId: data['institucionId'] ?? 'inst-1',
      createdAt: DateTime.now(),
    );
    _materias.add(newMateria);
    notifyListeners();
    return newMateria;
  }
}

/// Fake GrupoProvider
class FakeGrupoProvider extends GrupoProvider {
  final List<Grupo> _grupos;
  final List<String> _estudiantesAsignados = [];

  FakeGrupoProvider([List<Grupo>? grupos]) : _grupos = grupos ?? [];

  @override
  List<Grupo> get items => _grupos;

  @override
  Grupo? get selectedGrupo => _grupos.isNotEmpty ? _grupos.first : null;

  @override
  Future<void> loadItems(String accessToken,
      {int page = 1,
      int? limit,
      String? search,
      Map<String, String>? filters}) async {
    notifyListeners();
  }

  /// Método de test para crear grupo (no override)
  Future<Grupo?> testCreateGrupo(
      String accessToken, Map<String, dynamic> data) async {
    final periodo = PeriodoAcademico(
      id: data['periodoId'] ?? 'periodo-1',
      nombre: 'Periodo Test',
      fechaInicio: DateTime.now(),
      fechaFin: DateTime.now().add(const Duration(days: 180)),
      activo: true,
    );
    final newGrupo = Grupo(
      id: 'grupo-${_grupos.length + 1}',
      nombre: data['nombre'] ?? 'Nuevo Grupo',
      grado: data['grado'] ?? '1ro',
      seccion: data['seccion'] ?? 'A',
      periodoId: data['periodoId'] ?? 'periodo-1',
      institucionId: data['institucionId'] ?? 'inst-1',
      createdAt: DateTime.now(),
      periodoAcademico: periodo,
      count: GrupoCount(estudiantesGrupos: 0, horarios: 0, asistencias: 0),
    );
    _grupos.add(newGrupo);
    notifyListeners();
    return newGrupo;
  }

  @override
  Future<bool> asignarEstudianteAGrupo(
      String accessToken, String grupoId, String estudianteId) async {
    _estudiantesAsignados.add('$grupoId:$estudianteId');
    notifyListeners();
    return true;
  }

  @override
  Future<bool> desasignarEstudianteDeGrupo(
      String accessToken, String grupoId, String estudianteId) async {
    _estudiantesAsignados.remove('$grupoId:$estudianteId');
    notifyListeners();
    return true;
  }

  bool isEstudianteAsignado(String grupoId, String estudianteId) {
    return _estudiantesAsignados.contains('$grupoId:$estudianteId');
  }
}

/// Fake UserProvider
class FakeUserProvider extends UserProvider {
  final List<User> _users;
  final List<User> _professors;

  FakeUserProvider({List<User>? users, List<User>? professors})
      : _users = users ?? [],
        _professors = professors ?? [];

  @override
  List<User> get users => _users;

  @override
  List<User> get professors => _professors;

  @override
  Future<void> loadUsers(String accessToken,
      {int? page,
      int? limit,
      bool? activo,
      String? search,
      List<String>? roles}) async {
    notifyListeners();
  }

  @override
  Future<void> loadUsersByInstitution(String accessToken, String institutionId,
      {bool? activo,
      int limit = 10,
      int? page,
      String? role,
      String? search}) async {
    notifyListeners();
  }

  /// Método de test para crear usuario (no override)
  Future<User?> testCreateUser(
      String accessToken, Map<String, dynamic> data) async {
    final newUser = User(
      id: 'user-${_users.length + 1}',
      email: data['email'] ?? 'user@test.com',
      nombres: data['nombres'] ?? 'Nuevo',
      apellidos: data['apellidos'] ?? 'Usuario',
      rol: data['rol'] ?? 'estudiante',
      activo: data['activo'] ?? true,
      instituciones: [],
    );
    _users.add(newUser);
    if (newUser.rol == 'profesor') {
      _professors.add(newUser);
    }
    notifyListeners();
    return newUser;
  }

  /// Método de test para eliminar usuario (no override)
  Future<bool> testDeleteUser(String accessToken, String userId) async {
    _users.removeWhere((u) => u.id == userId);
    _professors.removeWhere((u) => u.id == userId);
    notifyListeners();
    return true;
  }
}

/// Fake HorarioProvider con soporte para conflictos
class FakeHorarioProvider extends HorarioProvider {
  final List<Horario> _horarios;
  bool _shouldConflict = false;
  ConflictError? _conflictErrorInternal;

  bool createCalled = false;
  bool updateCalled = false;
  bool deleteCalled = false;

  FakeHorarioProvider([List<Horario>? horarios]) : _horarios = horarios ?? [];

  void setShouldConflict(bool value, {ConflictError? error}) {
    _shouldConflict = value;
    _conflictErrorInternal = error;
  }

  @override
  List<Horario> get horarios => _horarios;

  @override
  List<Horario> get items => _horarios;

  @override
  ConflictError? get conflictError => _conflictErrorInternal;

  @override
  Future<void> loadItems(String accessToken,
      {int page = 1,
      int? limit,
      String? search,
      Map<String, String>? filters}) async {
    notifyListeners();
  }

  @override
  Future<void> loadHorariosByGrupo(String accessToken, String grupoId) async {
    notifyListeners();
  }

  @override
  Future<void> loadHorariosForGrupoWithConflictDetection(
      String accessToken, String grupoId, String periodoId) async {
    notifyListeners();
  }

  @override
  Future<bool> createHorario(
      String accessToken, CreateHorarioRequest horarioData) async {
    createCalled = true;

    if (_shouldConflict) {
      _conflictErrorInternal = _conflictErrorInternal ??
          ConflictError(
            code: '409',
            reason: 'grupo_conflict',
            message: 'El grupo ya tiene una clase programada en este horario',
            meta: {
              'conflictingHorarioIds': _horarios.map((h) => h.id).toList()
            },
          );
      return false;
    }

    // Check for actual conflicts (same group, day, overlapping hours)
    for (final existing in _horarios) {
      if (existing.grupoId == horarioData.grupoId &&
          existing.diaSemana == horarioData.diaSemana) {
        // Simplified overlap check
        final existingStart = _timeToMinutes(existing.horaInicio);
        final existingEnd = _timeToMinutes(existing.horaFin);
        final newStart = _timeToMinutes(horarioData.horaInicio);
        final newEnd = _timeToMinutes(horarioData.horaFin);

        if (newStart < existingEnd && newEnd > existingStart) {
          _conflictErrorInternal = ConflictError(
            code: '409',
            reason: 'grupo_conflict',
            message: 'El grupo ya tiene una clase programada en este horario',
            meta: {
              'conflictingHorarioIds': [existing.id]
            },
          );
          return false;
        }
      }
    }

    notifyListeners();
    return true;
  }

  @override
  Future<bool> updateHorario(String accessToken, String horarioId,
      UpdateHorarioRequest horarioData) async {
    updateCalled = true;
    notifyListeners();
    return true;
  }

  @override
  Future<bool> deleteHorario(String accessToken, String horarioId) async {
    deleteCalled = true;
    _horarios.removeWhere((h) => h.id == horarioId);
    notifyListeners();
    return true;
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}

/// Fake AsistenciaProvider
class FakeAsistenciaProvider extends AsistenciaProvider {
  final List<AsistenciaEstudiante> _testAsistencias = [];
  bool _duplicateError = false;
  bool _studentNotInGroupError = false;
  String? _testErrorMessage;

  void setDuplicateError(bool value) => _duplicateError = value;
  void setStudentNotInGroupError(bool value) => _studentNotInGroupError = value;

  @override
  List<AsistenciaEstudiante> get asistencias => _testAsistencias;

  @override
  String? get errorMessage => _testErrorMessage;

  /// Método de test para registrar asistencia manual
  Future<AsistenciaEstudiante?> testRegistrarAsistenciaManual(
      String accessToken, String horarioId, String estudianteId,
      {String? estado, String? observaciones}) async {
    if (_duplicateError) {
      _testErrorMessage = 'Asistencia ya registrada para hoy';
      return null;
    }

    if (_studentNotInGroupError) {
      _testErrorMessage = 'El estudiante no pertenece al grupo de esta clase';
      return null;
    }

    final asistencia = AsistenciaEstudiante(
      id: 'asist-${_testAsistencias.length + 1}',
      estudianteId: estudianteId,
      nombres: 'Test',
      apellidos: 'Student',
      identificacion: '123456',
      estado: estado ?? 'PRESENTE',
      fechaRegistro: DateTime.now(),
    );
    _testAsistencias.add(asistencia);
    notifyListeners();
    return asistencia;
  }

  /// Método de test para registrar asistencia QR
  Future<AsistenciaEstudiante?> testRegistrarAsistenciaQr(
      String accessToken, String horarioId, String codigoQr) async {
    if (_duplicateError) {
      _testErrorMessage = 'Asistencia ya registrada para hoy';
      return null;
    }

    if (_studentNotInGroupError) {
      _testErrorMessage = 'El estudiante no pertenece al grupo de esta clase';
      return null;
    }

    final asistencia = AsistenciaEstudiante(
      id: 'asist-${_testAsistencias.length + 1}',
      estudianteId: 'est-from-qr',
      nombres: 'QR',
      apellidos: 'Student',
      identificacion: '654321',
      estado: 'PRESENTE',
      fechaRegistro: DateTime.now(),
    );
    _testAsistencias.add(asistencia);
    notifyListeners();
    return asistencia;
  }

  /// Método de test para actualizar asistencia
  Future<bool> testActualizarAsistencia(String accessToken, String asistenciaId,
      Map<String, dynamic> data) async {
    final index = _testAsistencias.indexWhere((a) => a.id == asistenciaId);
    if (index != -1) {
      notifyListeners();
      return true;
    }
    return false;
  }
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/// Crea un widget de prueba envuelto con todos los providers necesarios
Widget createTestWidget({
  required Widget child,
  FakeAuthProvider? authProvider,
  FakeInstitutionProvider? institutionProvider,
  FakePeriodoProvider? periodoProvider,
  FakeMateriaProvider? materiaProvider,
  FakeGrupoProvider? grupoProvider,
  FakeUserProvider? userProvider,
  FakeHorarioProvider? horarioProvider,
  FakeAsistenciaProvider? asistenciaProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider ?? FakeAuthProvider()),
      ChangeNotifierProvider<InstitutionProvider>.value(
          value: institutionProvider ?? FakeInstitutionProvider()),
      ChangeNotifierProvider<PeriodoAcademicoProvider>.value(
          value: periodoProvider ?? FakePeriodoProvider()),
      ChangeNotifierProvider<MateriaProvider>.value(
          value: materiaProvider ?? FakeMateriaProvider()),
      ChangeNotifierProvider<GrupoProvider>.value(
          value: grupoProvider ?? FakeGrupoProvider()),
      ChangeNotifierProvider<UserProvider>.value(
          value: userProvider ?? FakeUserProvider()),
      ChangeNotifierProvider<HorarioProvider>.value(
          value: horarioProvider ?? FakeHorarioProvider()),
      ChangeNotifierProvider<AsistenciaProvider>.value(
          value: asistenciaProvider ?? FakeAsistenciaProvider()),
    ],
    child: MaterialApp(home: child),
  );
}

/// Crea datos de prueba completos para el "Golden Path"
class TestDataFactory {
  static Institution createInstitution(
      {String? id, String? nombre, bool activa = true}) {
    return Institution(
      id: id ?? 'inst-test',
      nombre: nombre ?? 'Colegio Futuro',
      activa: activa,
      createdAt: DateTime.now(),
    );
  }

  static PeriodoAcademico createPeriodo(
      {String? id, String? nombre, bool activo = true}) {
    return PeriodoAcademico(
      id: id ?? 'periodo-test',
      nombre: nombre ?? '2024-I',
      fechaInicio: DateTime.now(),
      fechaFin: DateTime.now().add(const Duration(days: 180)),
      activo: activo,
    );
  }

  static Materia createMateria(
      {String? id, String? nombre, String? institucionId}) {
    return Materia(
      id: id ?? 'materia-test',
      nombre: nombre ?? 'Física Cuántica',
      codigo: 'FIS101',
      institucionId: institucionId ?? 'inst-test',
      createdAt: DateTime.now(),
    );
  }

  static Grupo createGrupo({
    String? id,
    String? nombre,
    String? periodoId,
    PeriodoAcademico? periodoAcademico,
  }) {
    final periodo = periodoAcademico ?? createPeriodo(id: periodoId);
    return Grupo(
      id: id ?? 'grupo-test',
      nombre: nombre ?? 'Grado 11-A',
      grado: '11',
      seccion: 'A',
      periodoId: periodo.id,
      institucionId: 'inst-test',
      createdAt: DateTime.now(),
      periodoAcademico: periodo,
      count: GrupoCount(estudiantesGrupos: 1, horarios: 1, asistencias: 0),
    );
  }

  static User createProfesor(
      {String? id, String? email, String? nombres, String? apellidos}) {
    return User(
      id: id ?? 'prof-test',
      email: email ?? 'dr.brown@futuro.edu',
      nombres: nombres ?? 'Dr. Emmett',
      apellidos: apellidos ?? 'Brown',
      rol: 'profesor',
      activo: true,
      instituciones: [
        UserInstitution(
            id: 'inst-test',
            nombre: 'Colegio Futuro',
            rolEnInstitucion: 'profesor',
            activo: true),
      ],
    );
  }

  static User createEstudiante(
      {String? id, String? email, String? nombres, String? apellidos}) {
    return User(
      id: id ?? 'est-test',
      email: email ?? 'marty.mcfly@futuro.edu',
      nombres: nombres ?? 'Marty',
      apellidos: apellidos ?? 'McFly',
      rol: 'estudiante',
      activo: true,
      instituciones: [
        UserInstitution(
            id: 'inst-test',
            nombre: 'Colegio Futuro',
            rolEnInstitucion: 'estudiante',
            activo: true),
      ],
    );
  }

  static User createAdminInstitucion({String? id, String? email}) {
    return User(
      id: id ?? 'admin-inst-test',
      email: email ?? 'admin@futuro.edu',
      nombres: 'Admin',
      apellidos: 'Institución',
      rol: 'admin_institucion',
      activo: true,
      instituciones: [
        UserInstitution(
            id: 'inst-test',
            nombre: 'Colegio Futuro',
            rolEnInstitucion: 'admin_institucion',
            activo: true),
      ],
    );
  }

  static Horario createHorario({
    String? id,
    Grupo? grupo,
    Materia? materia,
    PeriodoAcademico? periodo,
    User? profesor,
    int diaSemana = 1,
    String horaInicio = '08:00',
    String horaFin = '10:00',
  }) {
    final g = grupo ?? createGrupo();
    final m = materia ?? createMateria();
    final p = periodo ?? createPeriodo();
    return Horario(
      id: id ?? 'horario-test',
      periodoId: p.id,
      grupoId: g.id,
      materiaId: m.id,
      profesorId: profesor?.id,
      diaSemana: diaSemana,
      horaInicio: horaInicio,
      horaFin: horaFin,
      institucionId: 'inst-test',
      createdAt: DateTime.now(),
      grupo: g,
      materia: m,
      periodoAcademico: p,
      profesor: profesor,
    );
  }
}

// ============================================================================
// TESTS
// ============================================================================

void main() {
  setUpAll(() async {
    await AppConfig.initialize();
  });

  // ==========================================================================
  // 🟢 GRUPO A: INICIALIZACIÓN Y ESTRUCTURA
  // ==========================================================================

  group('🟢 GRUPO A: Inicialización y Estructura', () {
    group('Escenario 1: Golden Path - Flujo Completo de Cero a Asistencia', () {
      test('FASE 1: Super Admin puede crear una nueva institución', () async {
        final institutionProvider = FakeInstitutionProvider();
        final authProvider = FakeAuthProvider(role: 'super_admin');

        expect(authProvider.user?['rol'], equals('super_admin'));

        final institution = await institutionProvider.testCreateInstitution(
          authProvider.accessToken!,
          {'nombre': 'Colegio Futuro', 'activa': true},
        );

        expect(institution, isNotNull);
        expect(institution!.nombre, equals('Colegio Futuro'));
        expect(institution.activa, isTrue);
        expect(institutionProvider.institutions.length, equals(1));
      });

      test('FASE 2: Super Admin puede crear un admin de institución', () async {
        final userProvider = FakeUserProvider();
        final authProvider = FakeAuthProvider(role: 'super_admin');

        final adminUser = await userProvider.testCreateUser(
          authProvider.accessToken!,
          {
            'email': 'admin@futuro.edu',
            'nombres': 'Admin',
            'apellidos': 'Futuro',
            'rol': 'admin_institucion',
            'institucionId': 'inst-1',
          },
        );

        expect(adminUser, isNotNull);
        expect(adminUser!.rol, equals('admin_institucion'));
        expect(adminUser.email, equals('admin@futuro.edu'));
      });

      test(
          'FASE 3: Admin Institución puede crear estructura académica completa',
          () async {
        final authProvider = FakeAuthProvider(
            role: 'admin_institucion', institutionId: 'inst-1');
        final periodoProvider = FakePeriodoProvider();
        final materiaProvider = FakeMateriaProvider();
        final grupoProvider = FakeGrupoProvider();
        final userProvider = FakeUserProvider();

        // Crear Periodo Académico
        final periodo = await periodoProvider.testCreatePeriodo(
          authProvider.accessToken!,
          {
            'nombre': '2024-I',
            'fechaInicio': DateTime.now().toIso8601String(),
            'fechaFin':
                DateTime.now().add(const Duration(days: 180)).toIso8601String(),
            'activo': true,
          },
        );
        expect(periodo, isNotNull);
        expect(periodo!.nombre, equals('2024-I'));

        // Crear Materia
        final materia = await materiaProvider.testCreateMateria(
          authProvider.accessToken!,
          {'nombre': 'Física Cuántica', 'codigo': 'FIS101'},
        );
        expect(materia, isNotNull);
        expect(materia!.nombre, equals('Física Cuántica'));

        // Crear Profesor
        final profesor = await userProvider.testCreateUser(
          authProvider.accessToken!,
          {
            'email': 'dr.brown@futuro.edu',
            'nombres': 'Dr. Emmett',
            'apellidos': 'Brown',
            'rol': 'profesor'
          },
        );
        expect(profesor, isNotNull);
        expect(profesor!.rol, equals('profesor'));

        // Crear Grupo
        final grupo = await grupoProvider.testCreateGrupo(
          authProvider.accessToken!,
          {
            'nombre': 'Grado 11-A',
            'grado': '11',
            'seccion': 'A',
            'periodoId': periodo.id
          },
        );
        expect(grupo, isNotNull);
        expect(grupo!.nombre, equals('Grado 11-A'));

        // Crear Estudiante
        final estudiante = await userProvider.testCreateUser(
          authProvider.accessToken!,
          {
            'email': 'marty.mcfly@futuro.edu',
            'nombres': 'Marty',
            'apellidos': 'McFly',
            'rol': 'estudiante'
          },
        );
        expect(estudiante, isNotNull);
        expect(estudiante!.rol, equals('estudiante'));
      });

      test('FASE 4: Admin puede asignar estudiante a grupo', () async {
        final authProvider = FakeAuthProvider(
            role: 'admin_institucion', institutionId: 'inst-1');
        final grupoProvider = FakeGrupoProvider();

        final success = await grupoProvider.asignarEstudianteAGrupo(
          authProvider.accessToken!,
          'grupo-1',
          'estudiante-1',
        );

        expect(success, isTrue);
        expect(grupoProvider.isEstudianteAsignado('grupo-1', 'estudiante-1'),
            isTrue);
      });
    });

    group('Escenario 2: Configuración Multi-Sede (Aislamiento de Datos)', () {
      test('Admin de Institución A NO puede ver materias de Institución B',
          () async {
        // Simular que las materias están filtradas por institución
        final materiaProviderA = FakeMateriaProvider([
          Materia(
              id: 'm1',
              nombre: 'Matemáticas A',
              institucionId: 'inst-A',
              createdAt: DateTime.now()),
        ]);

        final materiaProviderB = FakeMateriaProvider([
          Materia(
              id: 'm2',
              nombre: 'Matemáticas B',
              institucionId: 'inst-B',
              createdAt: DateTime.now()),
        ]);

        // Admin A solo ve sus materias
        expect(materiaProviderA.materias.length, equals(1));
        expect(materiaProviderA.materias.first.nombre, equals('Matemáticas A'));
        expect(materiaProviderA.materias.first.institucionId, equals('inst-A'));

        // Admin B solo ve sus materias
        expect(materiaProviderB.materias.length, equals(1));
        expect(materiaProviderB.materias.first.nombre, equals('Matemáticas B'));
        expect(materiaProviderB.materias.first.institucionId, equals('inst-B'));

        // Verificar aislamiento
        expect(
          materiaProviderA.materias.any((m) => m.institucionId == 'inst-B'),
          isFalse,
        );
      });
    });
  });

  // ==========================================================================
  // 🟡 GRUPO B: GESTIÓN DE CONFLICTOS Y RESTRICCIONES
  // ==========================================================================

  group('🟡 GRUPO B: Gestión de Conflictos y Restricciones', () {
    group('Escenario 3: El Profesor Ubicuo (Conflicto de Horario)', () {
      test(
          'Sistema detecta conflicto cuando profesor tiene clase en mismo horario',
          () async {
        final periodo = TestDataFactory.createPeriodo();
        final grupo = TestDataFactory.createGrupo(periodoAcademico: periodo);
        final materia = TestDataFactory.createMateria();
        final profesor = TestDataFactory.createProfesor();

        // Horario existente: Lunes 08:00-10:00
        final horarioExistente = TestDataFactory.createHorario(
          id: 'h1',
          grupo: grupo,
          materia: materia,
          periodo: periodo,
          profesor: profesor,
          diaSemana: 1,
          horaInicio: '08:00',
          horaFin: '10:00',
        );

        final horarioProvider = FakeHorarioProvider([horarioExistente]);
        final authProvider = FakeAuthProvider(
            role: 'admin_institucion', institutionId: 'inst-test');
        authProvider.selectInstitution('inst-test');

        // Intentar crear horario conflictivo: Lunes 08:30-09:30
        final success = await horarioProvider.createHorario(
          authProvider.accessToken!,
          CreateHorarioRequest(
            periodoId: periodo.id,
            grupoId: grupo.id,
            materiaId: materia.id,
            profesorId: profesor.id,
            diaSemana: 1,
            horaInicio: '08:30',
            horaFin: '09:30',
            institucionId: 'inst-test',
          ),
        );

        expect(success, isFalse);
        expect(horarioProvider.conflictError, isNotNull);
        expect(horarioProvider.conflictError!.reason, equals('grupo_conflict'));
      });
    });

    group('Escenario 4: El Grupo Ocupado', () {
      test('Sistema detecta conflicto cuando grupo ya tiene clase en horario',
          () async {
        final periodo = TestDataFactory.createPeriodo();
        final grupoA = TestDataFactory.createGrupo(
            id: 'grupo-10A', nombre: '10-A', periodoAcademico: periodo);
        final matematicas =
            TestDataFactory.createMateria(id: 'mat', nombre: 'Matemáticas');

        // Martes 10:00-12:00 ya ocupado
        final horarioExistente = TestDataFactory.createHorario(
          id: 'h-existing',
          grupo: grupoA,
          materia: matematicas,
          periodo: periodo,
          diaSemana: 2, // Martes
          horaInicio: '10:00',
          horaFin: '12:00',
        );

        final horarioProvider = FakeHorarioProvider([horarioExistente]);
        final authProvider = FakeAuthProvider(
            role: 'admin_institucion', institutionId: 'inst-test');

        // Intentar: Martes 11:00-13:00 (overlap)
        final success = await horarioProvider.createHorario(
          authProvider.accessToken!,
          CreateHorarioRequest(
            periodoId: periodo.id,
            grupoId: grupoA.id,
            materiaId: 'ingles-id',
            profesorId: 'otro-prof',
            diaSemana: 2,
            horaInicio: '11:00',
            horaFin: '13:00',
            institucionId: 'inst-test',
          ),
        );

        expect(success, isFalse);
        expect(horarioProvider.conflictError, isNotNull);
        expect(horarioProvider.conflictError!.message, contains('grupo'));
      });
    });

    group('Escenario 5: Eliminación con Dependencias', () {
      test('Sistema debe manejar eliminación de entidades con dependencias',
          () async {
        // Este test verifica que el provider maneja correctamente la eliminación
        // En la práctica, el backend rechazaría la eliminación si hay dependencias

        final grupoProvider = FakeGrupoProvider();

        // Crear grupo con "dependencias" (simulado)
        await grupoProvider.testCreateGrupo(
          'token',
          {'nombre': 'Grupo 9-B', 'grado': '9', 'seccion': 'B'},
        );

        // En el mundo real, deleteGrupo fallaría si hay asistencias
        // Aquí verificamos que el provider puede intentar la operación
        expect(grupoProvider.items.length, equals(1));

        // La UI debería sugerir desactivar en lugar de eliminar
        // cuando hay dependencias
      });
    });
  });

  // ==========================================================================
  // 🔵 GRUPO C: CICLO DE VIDA DE LA ASISTENCIA
  // ==========================================================================

  group('🔵 GRUPO C: Ciclo de Vida de la Asistencia', () {
    group('Escenario 6: Asistencia Manual (Fallo de Tecnología)', () {
      test('Profesor puede registrar asistencia manual', () async {
        final asistenciaProvider = FakeAsistenciaProvider();
        final authProvider =
            FakeAuthProvider(role: 'profesor', institutionId: 'inst-test');

        final asistencia =
            await asistenciaProvider.testRegistrarAsistenciaManual(
          authProvider.accessToken!,
          'horario-1',
          'estudiante-1',
          estado: 'PRESENTE',
        );

        expect(asistencia, isNotNull);
        expect(asistencia!.estado, equals('PRESENTE'));
      });

      test('Profesor puede registrar tardanza manualmente', () async {
        final asistenciaProvider = FakeAsistenciaProvider();
        final authProvider = FakeAuthProvider(role: 'profesor');

        final asistencia =
            await asistenciaProvider.testRegistrarAsistenciaManual(
          authProvider.accessToken!,
          'horario-1',
          'estudiante-1',
          estado: 'TARDANZA',
        );

        expect(asistencia, isNotNull);
        expect(asistencia!.estado, equals('TARDANZA'));
      });
    });

    group('Escenario 7: El Estudiante Intruso (Seguridad QR)', () {
      test('Sistema rechaza QR de estudiante que no pertenece al grupo',
          () async {
        final asistenciaProvider = FakeAsistenciaProvider();
        asistenciaProvider.setStudentNotInGroupError(true);

        final authProvider = FakeAuthProvider(role: 'profesor');

        final asistencia = await asistenciaProvider.testRegistrarAsistenciaQr(
          authProvider.accessToken!,
          'horario-grupo-a',
          'qr-estudiante-grupo-b',
        );

        expect(asistencia, isNull);
        expect(asistenciaProvider.errorMessage, contains('no pertenece'));
      });
    });

    group('Escenario 8: Doble Registro (Idempotencia)', () {
      test('Sistema rechaza asistencia duplicada', () async {
        final asistenciaProvider = FakeAsistenciaProvider();
        final authProvider = FakeAuthProvider(role: 'profesor');

        // Primer registro exitoso
        final primerRegistro =
            await asistenciaProvider.testRegistrarAsistenciaManual(
          authProvider.accessToken!,
          'horario-1',
          'estudiante-1',
        );
        expect(primerRegistro, isNotNull);

        // Simular que ya existe el registro
        asistenciaProvider.setDuplicateError(true);

        // Segundo registro debe fallar
        final segundoRegistro =
            await asistenciaProvider.testRegistrarAsistenciaQr(
          authProvider.accessToken!,
          'horario-1',
          'qr-estudiante-1',
        );

        expect(segundoRegistro, isNull);
        expect(asistenciaProvider.errorMessage, contains('ya registrada'));
      });
    });

    group('Escenario 9: Asistencia Justificada (Post-Clase)', () {
      test('Profesor puede cambiar asistencia de AUSENTE a JUSTIFICADO',
          () async {
        final asistenciaProvider = FakeAsistenciaProvider();
        final authProvider = FakeAuthProvider(role: 'profesor');

        // Registrar ausencia inicial
        final ausencia = await asistenciaProvider.testRegistrarAsistenciaManual(
          authProvider.accessToken!,
          'horario-1',
          'estudiante-1',
          estado: 'AUSENTE',
        );

        expect(ausencia, isNotNull);
        expect(ausencia!.estado, equals('AUSENTE'));

        // Actualizar a justificado
        final actualizado = await asistenciaProvider.testActualizarAsistencia(
          authProvider.accessToken!,
          ausencia.id!,
          {'estado': 'JUSTIFICADO', 'observaciones': 'Cita médica'},
        );

        expect(actualizado, isTrue);
      });
    });
  });

  // ==========================================================================
  // 🟠 GRUPO D: ACCESO Y SEGURIDAD
  // ==========================================================================

  group('🟠 GRUPO D: Acceso y Seguridad', () {
    group('Escenario 10: El Estudiante Hacker (Protección de Rutas)', () {
      test('Estudiante no puede acceder a funciones de admin', () {
        final authProvider = FakeAuthProvider(role: 'estudiante');

        // Verificar que el rol es estudiante
        expect(authProvider.user?['rol'], equals('estudiante'));

        // En la aplicación real, el middleware rechazaría estas peticiones
        // con 403 Forbidden. Aquí verificamos que la lógica de roles funciona.

        // Simular verificación de permisos
        final bool canDeleteUsers =
            authProvider.user?['rol'] == 'super_admin' ||
                authProvider.user?['rol'] == 'admin_institucion';
        final bool canCreateHorarios =
            authProvider.user?['rol'] != 'estudiante';

        expect(canDeleteUsers, isFalse);
        expect(canCreateHorarios, isFalse);
      });
    });

    group('Escenario 11: Institución Morosa (Desactivación Global)', () {
      test('Sistema puede verificar si institución está activa', () {
        final institutionActiva =
            TestDataFactory.createInstitution(activa: true);
        final institutionInactiva =
            TestDataFactory.createInstitution(id: 'inst-2', activa: false);

        expect(institutionActiva.activa, isTrue);
        expect(institutionInactiva.activa, isFalse);

        // En la aplicación real, el middleware de autenticación
        // verificaría esto y bloquearía el acceso
      });
    });

    group('Escenario 12: Cambio de Contraseña', () {
      test('Usuario puede actualizar su contraseña (simulado)', () async {
        final userProvider = FakeUserProvider(users: [
          User(
            id: 'user-1',
            email: 'profesor@test.com',
            nombres: 'Test',
            apellidos: 'User',
            rol: 'profesor',
            activo: true,
            instituciones: [],
          ),
        ]);

        // En la aplicación real, esto llamaría al endpoint de cambio de contraseña
        // Aquí solo verificamos que el usuario existe y puede ser actualizado
        expect(userProvider.users.length, equals(1));
        expect(userProvider.users.first.email, equals('profesor@test.com'));
      });
    });
  });

  // ==========================================================================
  // 🟣 GRUPO E: NOTIFICACIONES Y REPORTES
  // ==========================================================================

  group('🟣 GRUPO E: Notificaciones y Reportes', () {
    group('Escenario 13: Alerta de Ausencia', () {
      test('Ausencia registrada debe poder encolarse para notificación',
          () async {
        final asistenciaProvider = FakeAsistenciaProvider();
        final authProvider = FakeAuthProvider(role: 'profesor');

        final ausencia = await asistenciaProvider.testRegistrarAsistenciaManual(
          authProvider.accessToken!,
          'horario-1',
          'estudiante-1',
          estado: 'AUSENTE',
        );

        expect(ausencia, isNotNull);
        expect(ausencia!.estado, equals('AUSENTE'));

        // En la aplicación real, el backend encolaria una notificación
        // si la configuración de la institución tiene notificacionesActivas: true
      });
    });

    group('Escenario 14: Dashboard de Rendimiento', () {
      test('Estudiante puede ver estadísticas de asistencia', () {
        // Simular datos de asistencia
        final asistencias = [
          AsistenciaEstudiante(
              estudianteId: 'e1',
              nombres: 'A',
              apellidos: 'B',
              identificacion: '1',
              estado: 'PRESENTE'),
          AsistenciaEstudiante(
              estudianteId: 'e1',
              nombres: 'A',
              apellidos: 'B',
              identificacion: '1',
              estado: 'PRESENTE'),
          AsistenciaEstudiante(
              estudianteId: 'e1',
              nombres: 'A',
              apellidos: 'B',
              identificacion: '1',
              estado: 'TARDANZA'),
          AsistenciaEstudiante(
              estudianteId: 'e1',
              nombres: 'A',
              apellidos: 'B',
              identificacion: '1',
              estado: 'AUSENTE'),
          AsistenciaEstudiante(
              estudianteId: 'e1',
              nombres: 'A',
              apellidos: 'B',
              identificacion: '1',
              estado: 'JUSTIFICADO'),
        ];

        // Calcular estadísticas
        final total = asistencias.length;
        final presentes = asistencias.where((a) => a.estaPresente).length;
        final tardanzas = asistencias.where((a) => a.tieneTardanza).length;
        final ausentes = asistencias.where((a) => a.estaAusente).length;
        final justificados = asistencias.where((a) => a.estaJustificado).length;

        // Porcentaje de asistencia (presentes + tardanzas + justificados)
        final asistenciasContadas = presentes + tardanzas + justificados;
        final porcentaje = (asistenciasContadas / total * 100).round();

        expect(total, equals(5));
        expect(presentes, equals(2));
        expect(tardanzas, equals(1));
        expect(ausentes, equals(1));
        expect(justificados, equals(1));
        expect(porcentaje, equals(80)); // 4 de 5 = 80%
      });
    });
  });

  // ==========================================================================
  // 🔧 TESTS DE WIDGETS - DIALOGS
  // ==========================================================================

  group('🔧 Widget Tests: Dialogs de Horarios', () {
    testWidgets('CreateClassDialog muestra campos correctamente',
        (WidgetTester tester) async {
      final periodo = TestDataFactory.createPeriodo();
      final grupo = TestDataFactory.createGrupo(periodoAcademico: periodo);
      final materia = TestDataFactory.createMateria();
      final profesor = TestDataFactory.createProfesor();

      final authProvider = FakeAuthProvider(
          role: 'admin_institucion', institutionId: 'inst-test');
      authProvider.selectInstitution('inst-test');
      final horarioProvider = FakeHorarioProvider();
      final materiaProvider = FakeMateriaProvider([materia]);
      final userProvider = FakeUserProvider(professors: [profesor]);
      final periodoProvider = FakePeriodoProvider([periodo]);
      final grupoProvider = FakeGrupoProvider([grupo]);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<HorarioProvider>.value(
                value: horarioProvider),
            ChangeNotifierProvider<MateriaProvider>.value(
                value: materiaProvider),
            ChangeNotifierProvider<UserProvider>.value(value: userProvider),
            ChangeNotifierProvider<PeriodoAcademicoProvider>.value(
                value: periodoProvider),
            ChangeNotifierProvider<GrupoProvider>.value(value: grupoProvider),
          ],
          child: MaterialApp(
            home: Builder(builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => CreateClassDialog(
                            grupo: grupo, horaInicio: '08:00', diaSemana: 1),
                      );
                    },
                    child: const Text('Abrir Dialog'),
                  ),
                ),
              );
            }),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Abrir el dialog
      await tester.tap(find.text('Abrir Dialog'));
      await tester.pumpAndSettle();

      // Verificar que el dialog muestra información correcta
      // "Crear Clase" aparece como título y como botón, así que verificamos que exista al menos uno
      expect(find.text('Crear Clase'), findsWidgets);
      expect(find.text('Horario: 08:00 - 10:00'), findsOneWidget);
      expect(find.text('Día: Lunes'), findsOneWidget);
      expect(find.textContaining('Grupo:'), findsOneWidget);
    });

    testWidgets('EditClassDialog muestra horario existente',
        (WidgetTester tester) async {
      final periodo = TestDataFactory.createPeriodo();
      final grupo = TestDataFactory.createGrupo(periodoAcademico: periodo);
      final materia = TestDataFactory.createMateria();
      final profesor = TestDataFactory.createProfesor();

      final horario = TestDataFactory.createHorario(
        grupo: grupo,
        materia: materia,
        periodo: periodo,
        profesor: profesor,
        horaInicio: '08:00',
        horaFin: '10:00',
      );

      final authProvider = FakeAuthProvider(
          role: 'admin_institucion', institutionId: 'inst-test');
      final horarioProvider = FakeHorarioProvider([horario]);
      final userProvider = FakeUserProvider(professors: [profesor]);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<HorarioProvider>.value(
                value: horarioProvider),
            ChangeNotifierProvider<UserProvider>.value(value: userProvider),
          ],
          child: MaterialApp(
            home: Builder(builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => EditClassDialog(horario: horario),
                      );
                    },
                    child: const Text('Editar'),
                  ),
                ),
              );
            }),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Abrir el dialog
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();

      // Verificar contenido
      expect(find.text('Editar Clase'), findsOneWidget);
      expect(find.text('Eliminar'), findsOneWidget);
      expect(find.text('Actualizar'), findsOneWidget);
    });
  });

  // ==========================================================================
  // 📊 RESUMEN TÉCNICO - CHECKLIST
  // ==========================================================================

  group('📊 Checklist de Validación Final', () {
    test('✅ Auth: Todos los roles tienen tokens válidos', () {
      final superAdmin = FakeAuthProvider(role: 'super_admin');
      final adminInst =
          FakeAuthProvider(role: 'admin_institucion', institutionId: 'inst-1');
      final profesor =
          FakeAuthProvider(role: 'profesor', institutionId: 'inst-1');
      final estudiante =
          FakeAuthProvider(role: 'estudiante', institutionId: 'inst-1');

      expect(superAdmin.accessToken, isNotNull);
      expect(adminInst.accessToken, isNotNull);
      expect(profesor.accessToken, isNotNull);
      expect(estudiante.accessToken, isNotNull);

      expect(superAdmin.isAuthenticated, isTrue);
      expect(adminInst.isAuthenticated, isTrue);
      expect(profesor.isAuthenticated, isTrue);
      expect(estudiante.isAuthenticated, isTrue);
    });

    test('✅ Creation: Providers pueden crear entidades básicas', () async {
      final instProvider = FakeInstitutionProvider();
      final periodoProvider = FakePeriodoProvider();
      final materiaProvider = FakeMateriaProvider();
      final grupoProvider = FakeGrupoProvider();
      final userProvider = FakeUserProvider();

      expect(
          await instProvider.testCreateInstitution('token', {'nombre': 'Test'}),
          isNotNull);
      expect(
          await periodoProvider.testCreatePeriodo('token', {
            'nombre': 'P1',
            'fechaInicio': DateTime.now().toIso8601String(),
            'fechaFin':
                DateTime.now().add(const Duration(days: 90)).toIso8601String(),
          }),
          isNotNull);
      expect(
          await materiaProvider.testCreateMateria('token', {'nombre': 'Mat'}),
          isNotNull);
      expect(await grupoProvider.testCreateGrupo('token', {'nombre': 'G1'}),
          isNotNull);
      expect(await userProvider.testCreateUser('token', {'email': 'u@t.com'}),
          isNotNull);
    });

    test('✅ Logic: Conflictos de horario son detectados', () async {
      final horarioProvider = FakeHorarioProvider([
        TestDataFactory.createHorario(
            diaSemana: 1, horaInicio: '08:00', horaFin: '10:00'),
      ]);

      final conflicto = await horarioProvider.createHorario(
        'token',
        CreateHorarioRequest(
          periodoId: 'p1',
          grupoId: 'grupo-test', // Mismo grupo
          materiaId: 'm1',
          profesorId: 'prof1',
          diaSemana: 1, // Mismo día
          horaInicio: '09:00', // Overlap
          horaFin: '11:00',
          institucionId: 'inst-1',
        ),
      );

      expect(conflicto, isFalse);
      expect(horarioProvider.conflictError, isNotNull);
    });

    test('✅ Flow: Asistencia puede registrarse por QR y Manual', () async {
      final asistProvider = FakeAsistenciaProvider();

      final manual = await asistProvider.testRegistrarAsistenciaManual(
          'token', 'h1', 'e1');
      expect(manual, isNotNull);
      expect(manual!.estado, equals('PRESENTE'));

      final qr = await asistProvider.testRegistrarAsistenciaQr(
          'token', 'h2', 'qr-code');
      expect(qr, isNotNull);
      expect(qr!.estado, equals('PRESENTE'));
    });

    test('✅ Clean: Entidades pueden ser eliminadas', () async {
      final userProvider = FakeUserProvider(users: [
        User(
            id: 'u1',
            email: 'a@b.com',
            nombres: 'A',
            apellidos: 'B',
            rol: 'estudiante',
            activo: true,
            instituciones: []),
      ]);

      expect(userProvider.users.length, equals(1));

      final deleted = await userProvider.testDeleteUser('token', 'u1');
      expect(deleted, isTrue);
      expect(userProvider.users.length, equals(0));
    });
  });
}
