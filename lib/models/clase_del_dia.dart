class ClaseDelDia {
  final String id;
  final int diaSemana;
  final String horaInicio;
  final String horaFin;
  final GrupoSimple grupo;
  final MateriaSimple materia;
  final PeriodoAcademicoSimple periodoAcademico;
  final Institucion institucion;

  ClaseDelDia({
    required this.id,
    required this.diaSemana,
    required this.horaInicio,
    required this.horaFin,
    required this.grupo,
    required this.materia,
    required this.periodoAcademico,
    required this.institucion,
  });

  factory ClaseDelDia.fromJson(Map<String, dynamic> json) {
    return ClaseDelDia(
      id: json['id'],
      diaSemana: json['diaSemana'],
      horaInicio: json['horaInicio'],
      horaFin: json['horaFin'],
      grupo: GrupoSimple.fromJson(json['grupo']),
      materia: MateriaSimple.fromJson(json['materia']),
      periodoAcademico: PeriodoAcademicoSimple.fromJson(json['periodoAcademico']),
      institucion: Institucion.fromJson(json['institucion']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'diaSemana': diaSemana,
      'horaInicio': horaInicio,
      'horaFin': horaFin,
      'grupo': grupo.toJson(),
      'materia': materia.toJson(),
      'periodoAcademico': periodoAcademico.toJson(),
      'institucion': institucion.toJson(),
    };
  }

  String get diaSemanaNombre {
    const dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    return dias[diaSemana - 1];
  }

  String get horarioFormato => '$horaInicio - $horaFin';

  String get descripcion => '${materia.nombre} - ${grupo.nombreCompleto}';
}

// Versiones simplificadas para respuestas de clases del día
class GrupoSimple {
  final String id;
  final String nombre;
  final String grado;
  final String? seccion;

  GrupoSimple({
    required this.id,
    required this.nombre,
    required this.grado,
    this.seccion,
  });

  factory GrupoSimple.fromJson(Map<String, dynamic> json) {
    return GrupoSimple(
      id: json['id'],
      nombre: json['nombre'],
      grado: json['grado'],
      seccion: json['seccion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'grado': grado,
      'seccion': seccion,
    };
  }

  String get nombreCompleto => seccion != null ? '$grado $seccion' : grado;
}

class MateriaSimple {
  final String id;
  final String nombre;
  final String? codigo;

  MateriaSimple({
    required this.id,
    required this.nombre,
    this.codigo,
  });

  factory MateriaSimple.fromJson(Map<String, dynamic> json) {
    return MateriaSimple(
      id: json['id'],
      nombre: json['nombre'],
      codigo: json['codigo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'codigo': codigo,
    };
  }

  String get nombreConCodigo => codigo != null ? '$codigo - $nombre' : nombre;
}

class PeriodoAcademicoSimple {
  final String id;
  final String nombre;
  final bool activo;

  PeriodoAcademicoSimple({
    required this.id,
    required this.nombre,
    required this.activo,
  });

  factory PeriodoAcademicoSimple.fromJson(Map<String, dynamic> json) {
    return PeriodoAcademicoSimple(
      id: json['id'],
      nombre: json['nombre'],
      activo: json['activo'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'activo': activo,
    };
  }
}

class Institucion {
  final String id;
  final String nombre;

  Institucion({
    required this.id,
    required this.nombre,
  });

  factory Institucion.fromJson(Map<String, dynamic> json) {
    return Institucion(
      id: json['id'],
      nombre: json['nombre'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
    };
  }
}