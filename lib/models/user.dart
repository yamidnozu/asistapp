import '../utils/app_constants.dart';

class User {
  final String id;
  final String email;
  final String nombres;
  final String apellidos;
  final String rol;
  final String? telefono;
  final bool activo;
  final List<UserInstitution> instituciones;
  final StudentDetails? estudiante;

  User({
    required this.id,
    required this.email,
    required this.nombres,
    required this.apellidos,
    required this.rol,
    this.telefono,
    required this.activo,
    required this.instituciones,
    this.estudiante,
  });

  String get nombreCompleto => '$nombres $apellidos';

  bool get esProfesor => rol == 'profesor';
  bool get esEstudiante => rol == 'estudiante';
  bool get esAdminInstitucion => rol == 'admin_institucion';
  bool get esSuperAdmin => rol == 'super_admin';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      nombres: json['nombres'] as String? ?? '',
      apellidos: json['apellidos'] as String? ?? '',
      rol: json['rol'] as String? ?? 'profesor', // Default to profesor for institution-admin context
      telefono: json['telefono'] as String?,
      activo: json['activo'] as bool? ?? true,
      instituciones: (json['usuarioInstituciones'] as List<dynamic>?)
          ?.map((e) => UserInstitution.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      estudiante: json['estudiante'] != null
          ? StudentDetails.fromJson(json['estudiante'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nombres': nombres,
      'apellidos': apellidos,
      'rol': rol,
      'telefono': telefono,
      'activo': activo,
      'usuarioInstituciones': instituciones.map((e) => e.toJson()).toList(),
      if (estudiante != null) 'estudiante': estudiante!.toJson(),
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? nombres,
    String? apellidos,
    String? rol,
    String? telefono,
    bool? activo,
    List<UserInstitution>? instituciones,
    StudentDetails? estudiante,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      nombres: nombres ?? this.nombres,
      apellidos: apellidos ?? this.apellidos,
      rol: rol ?? this.rol,
      telefono: telefono ?? this.telefono,
      activo: activo ?? this.activo,
      instituciones: instituciones ?? this.instituciones,
      estudiante: estudiante ?? this.estudiante,
    );
  }
}

class UserInstitution {
  final String id;
  final String nombre;
  final String? rolEnInstitucion;
  final bool activo;

  UserInstitution({
    required this.id,
    required this.nombre,
    this.rolEnInstitucion,
    required this.activo,
  });

  factory UserInstitution.fromJson(Map<String, dynamic> json) {
    return UserInstitution(
      id: json['institucion']?['id'] as String? ?? '',
      nombre: json['institucion']?['nombre'] as String? ?? '',
      rolEnInstitucion: json['rolEnInstitucion'] as String?,
      activo: json['activo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'institucion': {
        'id': id,
        'nombre': nombre,
      },
      'rolEnInstitucion': rolEnInstitucion,
      'activo': activo,
    };
  }
}

class StudentDetails {
  final String id;
  final String identificacion;
  final String codigoQr;
  final String? nombreResponsable;
  final String? telefonoResponsable;

  StudentDetails({
    required this.id,
    required this.identificacion,
    required this.codigoQr,
    this.nombreResponsable,
    this.telefonoResponsable,
  });

  factory StudentDetails.fromJson(Map<String, dynamic> json) {
    return StudentDetails(
      id: json['id'] as String? ?? '',
      identificacion: json['identificacion'] as String? ?? '',
      codigoQr: json['codigoQr'] as String? ?? '',
      nombreResponsable: json['nombreResponsable'] as String?,
      telefonoResponsable: json['telefonoResponsable'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'identificacion': identificacion,
      'codigoQr': codigoQr,
      'nombreResponsable': nombreResponsable,
      'telefonoResponsable': telefonoResponsable,
    };
  }
}

// Request models for API calls
class CreateUserRequest {
  final String email;
  final String password;
  final String nombres;
  final String apellidos;
  final String rol;
  final String? telefono;
  final String? institucionId;
  final String? rolEnInstitucion;
  // Campos específicos para estudiantes
  final String? identificacion;
  final String? nombreResponsable;
  final String? telefonoResponsable;
  // Campos específicos para profesores
  final String? titulo;
  final String? especialidad;

  CreateUserRequest({
    required this.email,
    required this.password,
    required this.nombres,
    required this.apellidos,
    required this.rol,
    this.telefono,
    this.institucionId,
    this.rolEnInstitucion,
    this.identificacion,
    this.nombreResponsable,
    this.telefonoResponsable,
    this.titulo,
    this.especialidad,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'email': email,
      'password': password,
      'nombres': nombres,
      'apellidos': apellidos,
      'rol': rol,
      if (telefono != null) 'telefono': telefono,
      if (institucionId != null) 'institucionId': institucionId,
      if (rolEnInstitucion != null) 'rolEnInstitucion': rolEnInstitucion,
    };

    // Campos específicos para estudiantes
    if (rol == 'estudiante') {
      if (identificacion != null) data['identificacion'] = identificacion;
      if (nombreResponsable != null) data['nombreResponsable'] = nombreResponsable;
      if (telefonoResponsable != null) data['telefonoResponsable'] = telefonoResponsable;
    }

    // Campos específicos para profesores
    if (rol == 'profesor') {
      if (titulo != null) data['titulo'] = titulo;
      if (especialidad != null) data['especialidad'] = especialidad;
    }

    return data;
  }
}

class UpdateUserRequest {
  final String? email;
  final String? nombres;
  final String? apellidos;
  final String? telefono;
  final bool? activo;
  // Para estudiantes
  final String? identificacion;
  final String? nombreResponsable;
  final String? telefonoResponsable;

  UpdateUserRequest({
    this.email,
    this.nombres,
    this.apellidos,
    this.telefono,
    this.activo,
    this.identificacion,
    this.nombreResponsable,
    this.telefonoResponsable,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    if (email != null) data['email'] = email;
    if (nombres != null) data['nombres'] = nombres;
    if (apellidos != null) data['apellidos'] = apellidos;
    if (telefono != null) data['telefono'] = telefono;
    if (activo != null) data['activo'] = activo;
    if (identificacion != null) data['identificacion'] = identificacion;
    if (nombreResponsable != null) data['nombreResponsable'] = nombreResponsable;
    if (telefonoResponsable != null) data['telefonoResponsable'] = telefonoResponsable;

    return data;
  }
}

class PaginationInfo {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  PaginationInfo({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? AppConstants.itemsPerPage,
      total: json['total'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 1,
      hasNext: json['hasNext'] as bool? ?? false,
      hasPrev: json['hasPrev'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'limit': limit,
      'total': total,
      'totalPages': totalPages,
      'hasNext': hasNext,
      'hasPrev': hasPrev,
    };
  }
}