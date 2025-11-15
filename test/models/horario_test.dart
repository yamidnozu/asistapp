import 'package:flutter_test/flutter_test.dart';
import 'package:asistapp/models/horario.dart';

// No additional imports required

void main() {
  test('Horario.fromJson with nested full grupo', () {
    final nowIso = DateTime.now().toIso8601String();

    final json = {
      'id': 'h1',
      'periodoId': 'p1',
      'grupoId': 'g1',
      'materiaId': 'm1',
      'profesorId': null,
      'diaSemana': 1,
      'horaInicio': '08:00',
      'horaFin': '09:00',
      'institucionId': 'i1',
      'createdAt': nowIso,
      'grupo': {
        'id': 'g1',
        'nombre': 'Grupo A',
        'grado': '3',
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
        '_count': {'estudiantesGrupos': 2, 'horarios': 1},
      },
      'materia': {
        'id': 'm1',
        'nombre': 'Matemáticas',
        'codigo': 'MAT',
        'color': '#fff',
        'createdAt': nowIso,
        'institucionId': 'i1'
      },
      'periodoAcademico': {
        'id': 'p1',
        'nombre': 'Periodo 1',
        'fechaInicio': nowIso,
        'fechaFin': nowIso,
        'activo': true,
      }
    };

    final h = Horario.fromJson(json);

    expect(h.id, 'h1');
    expect(h.grupo.id, 'g1');
    expect(h.materia.nombre, 'Matemáticas');
    expect(h.periodoAcademico.id, 'p1');
  });

  test('Horario.fromJson with compact grupo shape', () {
    final nowIso = DateTime.now().toIso8601String();

    final json = {
      'id': 'h2',
      'periodoId': 'p2',
      'grupoId': 'g2',
      'materiaId': 'm2',
      'profesorId': null,
      'diaSemana': 2,
      'horaInicio': '09:00',
      'horaFin': '10:00',
      'institucionId': 'i2',
      'createdAt': nowIso,
      'grupo': {
        'id': 'g2',
        'nombre': 'Grupo B',
        'grado': '4',
        'periodoId': 'p2',
        'institucionId': 'i2',
        // omit periodoAcademico to simulate compact response
        '_count': {'estudiantesGrupos': 0, 'horarios': 0},
      },
      'materia': {
        'id': 'm2',
        'nombre': 'Ciencias',
        'codigo': 'CIE',
        'color': '#000',
        'createdAt': nowIso,
        'institucionId': 'i2'
      },
      'periodoAcademico': {
        'id': 'p2',
        'nombre': 'Periodo 2',
        'fechaInicio': nowIso,
        'fechaFin': nowIso,
        'activo': true,
      }
    };

    final h = Horario.fromJson(json);

    expect(h.id, 'h2');
    expect(h.grupo.id, 'g2');
    // fallback should map periodoId into periodoAcademico.id inside Grupo
    expect(h.grupo.periodoAcademico.id, 'p2');
  });
}
