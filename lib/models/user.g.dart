// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
      id: json['id'] as String,
      email: json['email'] as String,
      nombres: json['nombres'] as String,
      apellidos: json['apellidos'] as String,
      rol: json['rol'] as String,
      telefono: json['telefono'] as String?,
      identificacion: json['identificacion'] as String?,
      activo: json['activo'] as bool,
      instituciones: (json['instituciones'] as List<dynamic>?)
          ?.map((e) => UserInstitution.fromJson(e as Map<String, dynamic>))
          .toList(),
      estudiante: json['estudiante'] == null
          ? null
          : StudentDetails.fromJson(json['estudiante'] as Map<String, dynamic>),
      titulo: json['titulo'] as String?,
      especialidad: json['especialidad'] as String?,
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'nombres': instance.nombres,
      'apellidos': instance.apellidos,
      'rol': instance.rol,
      'telefono': instance.telefono,
      'identificacion': instance.identificacion,
      'activo': instance.activo,
      'instituciones': instance.instituciones,
      'estudiante': instance.estudiante,
      'titulo': instance.titulo,
      'especialidad': instance.especialidad,
    };

UserInstitution _$UserInstitutionFromJson(Map<String, dynamic> json) =>
    UserInstitution(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      rolEnInstitucion: json['rolEnInstitucion'] as String?,
      activo: json['activo'] as bool,
    );

Map<String, dynamic> _$UserInstitutionToJson(UserInstitution instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nombre': instance.nombre,
      'rolEnInstitucion': instance.rolEnInstitucion,
      'activo': instance.activo,
    };

StudentDetails _$StudentDetailsFromJson(Map<String, dynamic> json) =>
    StudentDetails(
      id: json['id'] as String,
      identificacion: json['identificacion'] as String,
      codigoQr: json['codigoQr'] as String,
      nombreResponsable: json['nombreResponsable'] as String?,
      telefonoResponsable: json['telefonoResponsable'] as String?,
    );

Map<String, dynamic> _$StudentDetailsToJson(StudentDetails instance) =>
    <String, dynamic>{
      'id': instance.id,
      'identificacion': instance.identificacion,
      'codigoQr': instance.codigoQr,
      'nombreResponsable': instance.nombreResponsable,
      'telefonoResponsable': instance.telefonoResponsable,
    };

PaginationInfo _$PaginationInfoFromJson(Map<String, dynamic> json) =>
    PaginationInfo(
      page: (json['page'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      total: (json['total'] as num).toInt(),
      totalPages: (json['totalPages'] as num).toInt(),
      hasNext: json['hasNext'] as bool,
      hasPrev: json['hasPrev'] as bool,
    );

Map<String, dynamic> _$PaginationInfoToJson(PaginationInfo instance) =>
    <String, dynamic>{
      'page': instance.page,
      'limit': instance.limit,
      'total': instance.total,
      'totalPages': instance.totalPages,
      'hasNext': instance.hasNext,
      'hasPrev': instance.hasPrev,
    };
