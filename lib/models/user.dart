import 'package:json_annotation/json_annotation.dart';
import '../constants/roles.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String id;
  final String? email;
  final String nombres;
  final String apellidos;
  final String? rol;
  final String? telefono;
  final String? identificacion;
  final bool? activo;
  final List<UserInstitution>? instituciones;
  final StudentDetails? estudiante;
  // Campos específicos para profesores
  final String? titulo;
  final String? especialidad;
  final DateTime? createdAt;

  User({
    required this.id,
    this.email,
    required this.nombres,
    required this.apellidos,
    this.rol,
    this.telefono,
    this.identificacion,
    this.activo,
    List<UserInstitution>? instituciones,
    this.estudiante,
    this.titulo,
    this.especialidad,
    this.createdAt,
  }) : instituciones = instituciones ?? [];

  String get nombreCompleto => '$nombres $apellidos';

  bool get esProfesor => rol == UserRoles.profesor;
  bool get esEstudiante => rol == UserRoles.estudiante;
  bool get esAdminInstitucion => rol == UserRoles.adminInstitucion;
  bool get esSuperAdmin => rol == UserRoles.superAdmin;

  /// Obtiene la inicial del usuario para mostrar en avatares
  String get inicial {
    // Primero intentar usar la primera letra de nombres
    if (nombres.isNotEmpty) {
      return nombres[0].toUpperCase();
    }
    
    // Si nombres está vacío, usar la primera letra del nombre completo
    if (nombreCompleto.isNotEmpty && nombreCompleto != ' ') {
      return nombreCompleto[0].toUpperCase();
    }
    
    // Si nombre completo también está vacío, usar la primera letra del email
    if (email != null && email!.isNotEmpty) {
      return email![0].toUpperCase();
    }
    
    // Último recurso
    return '?';
  }

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);

  User copyWith({
    String? id,
    String? email,
    String? nombres,
    String? apellidos,
    String? rol,
    String? telefono,
    String? identificacion,
    bool? activo,
    List<UserInstitution>? instituciones,
    StudentDetails? estudiante,
    String? titulo,
    String? especialidad,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      nombres: nombres ?? this.nombres,
      apellidos: apellidos ?? this.apellidos,
      rol: rol ?? this.rol,
      telefono: telefono ?? this.telefono,
      identificacion: identificacion ?? this.identificacion,
      activo: activo ?? this.activo,
      instituciones: instituciones ?? this.instituciones,
      estudiante: estudiante ?? this.estudiante,
      titulo: titulo ?? this.titulo,
      especialidad: especialidad ?? this.especialidad,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

@JsonSerializable()
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

  factory UserInstitution.fromJson(Map<String, dynamic> json) => _$UserInstitutionFromJson(json);

  Map<String, dynamic> toJson() => _$UserInstitutionToJson(this);
}

@JsonSerializable()
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

  factory StudentDetails.fromJson(Map<String, dynamic> json) => _$StudentDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$StudentDetailsToJson(this);
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
    if (rol == UserRoles.estudiante) {
      if (identificacion != null) data['identificacion'] = identificacion;
      if (nombreResponsable != null) data['nombreResponsable'] = nombreResponsable;
      if (telefonoResponsable != null) data['telefonoResponsable'] = telefonoResponsable;
    }

    // Campos específicos para profesores
    if (rol == UserRoles.profesor) {
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
  // Para profesores
  final String? titulo;
  final String? especialidad;

  UpdateUserRequest({
    this.email,
    this.nombres,
    this.apellidos,
    this.telefono,
    this.activo,
    this.identificacion,
    this.nombreResponsable,
    this.telefonoResponsable,
    this.titulo,
    this.especialidad,
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
    if (titulo != null) data['titulo'] = titulo;
    if (especialidad != null) data['especialidad'] = especialidad;

    return data;
  }
}

@JsonSerializable()
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

  factory PaginationInfo.fromJson(Map<String, dynamic> json) => _$PaginationInfoFromJson(json);

  Map<String, dynamic> toJson() => _$PaginationInfoToJson(this);
}