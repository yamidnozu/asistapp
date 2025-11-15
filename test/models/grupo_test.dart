import 'package:flutter_test/flutter_test.dart';
import 'package:asistapp/models/grupo.dart';

void main() {
  test('Grupo.fromJson with full periodoAcademico', () {
    final nowIso = DateTime.now().toIso8601String();
    final json = {
      'id': 'g1',
      'nombre': 'Grupo A',
      'grado': '3',
      'seccion': 'A',
      'periodoId': 'p1',
      'institucionId': 'i1',
      'createdAt': nowIso,
      'periodoAcademico': {
        'id': 'p1',
        'nombre': 'Periodo 1',
        'fechaInicio': nowIso,
        'fechaFin': nowIso,
        'activo': true,
      },
      '_count': {'estudiantesGrupos': 10, 'horarios': 2},
    };

    final g = Grupo.fromJson(json);

    expect(g.id, 'g1');
    expect(g.periodoAcademico.id, 'p1');
    expect(g.periodoAcademico.nombre, 'Periodo 1');
    expect(g.estudiantesGruposCount, 10);
  });

  test('Grupo.fromJson with compact shape (no periodoAcademico)', () {
    final json = {
      'id': 'g2',
      'nombre': 'Grupo B',
      'grado': '4',
      'seccion': null,
      'periodoId': 'p2',
      'institucionId': 'i2',
      // intentionally omit 'createdAt' and 'periodoAcademico'
      '_count': {'estudiantesGrupos': 0, 'horarios': 0},
    };

    final g = Grupo.fromJson(json);

    expect(g.id, 'g2');
    // fallback maps periodoId into periodoAcademico.id
    expect(g.periodoAcademico.id, 'p2');
    expect(g.periodoAcademico.nombre, '');
    expect(g.periodoAcademico.activo, false);
    expect(g.seccion, isNull);
  });
}
