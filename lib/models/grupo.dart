class Grupo {
  final String id;
  final String nombre;
  final String grado;
  final String? seccion;
  final String periodoId;
  final String institucionId;
  final DateTime createdAt;
  final PeriodoAcademico periodoAcademico;
  final GrupoCount _count;

  Grupo({
    required this.id,
    required this.nombre,
    required this.grado,
    this.seccion,
    required this.periodoId,
    required this.institucionId,
    required this.createdAt,
    required this.periodoAcademico,
    required GrupoCount count,
  }) : _count = count;

  int get estudiantesGruposCount => _count.estudiantesGrupos;
  int get horariosCount => _count.horarios;

  factory Grupo.fromJson(Map<String, dynamic> json) {
    return Grupo(
      id: json['id'],
      nombre: json['nombre'],
      grado: json['grado'],
      seccion: json['seccion'],
      periodoId: json['periodoId'],
      institucionId: json['institucionId'],
      createdAt: DateTime.parse(json['createdAt']),
      periodoAcademico: PeriodoAcademico.fromJson(json['periodoAcademico']),
      count: GrupoCount.fromJson(json['_count']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'grado': grado,
      'seccion': seccion,
      'periodoId': periodoId,
      'institucionId': institucionId,
      'createdAt': createdAt.toIso8601String(),
      'periodoAcademico': periodoAcademico.toJson(),
      '_count': _count.toJson(),
    };
  }

  String get nombreCompleto => seccion != null ? '$grado $seccion' : grado;
}

class GrupoCount {
  final int estudiantesGrupos;
  final int horarios;

  GrupoCount({
    required this.estudiantesGrupos,
    required this.horarios,
  });

  factory GrupoCount.fromJson(Map<String, dynamic> json) {
    return GrupoCount(
      estudiantesGrupos: json['estudiantesGrupos'] ?? 0,
      horarios: json['horarios'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'estudiantesGrupos': estudiantesGrupos,
      'horarios': horarios,
    };
  }
}

class PeriodoAcademico {
  final String id;
  final String nombre;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final bool activo;

  PeriodoAcademico({
    required this.id,
    required this.nombre,
    required this.fechaInicio,
    required this.fechaFin,
    required this.activo,
  });

  factory PeriodoAcademico.fromJson(Map<String, dynamic> json) {
    return PeriodoAcademico(
      id: json['id'],
      nombre: json['nombre'],
      fechaInicio: DateTime.parse(json['fechaInicio']),
      fechaFin: DateTime.parse(json['fechaFin']),
      activo: json['activo'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'fechaInicio': fechaInicio.toIso8601String(),
      'fechaFin': fechaFin.toIso8601String(),
      'activo': activo,
    };
  }
}