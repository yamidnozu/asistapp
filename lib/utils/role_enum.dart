/// Los 4 tipos de usuario en la app
enum UserRole {
  superAdmin,       // Administrador global del sistema
  adminInstitucion, // Administrador de una institución
  profesor,         // Profesor de clases
  estudiante,       // Estudiante
}

/// Helpers para trabajar con roles
extension UserRoleExtension on UserRole {
  /// Convertir a string para enviar al backend
  String get value {
    switch (this) {
      case UserRole.superAdmin:
        return 'super_admin';
      case UserRole.adminInstitucion:
        return 'admin_institucion';
      case UserRole.profesor:
        return 'profesor';
      case UserRole.estudiante:
        return 'estudiante';
    }
  }

  /// Nombre bonito para mostrar en la UI
  String get displayName {
    switch (this) {
      case UserRole.superAdmin:
        return 'Super Administrador';
      case UserRole.adminInstitucion:
        return 'Administrador';
      case UserRole.profesor:
        return 'Profesor';
      case UserRole.estudiante:
        return 'Estudiante';
    }
  }

  /// Convertir string del backend a enum
  static UserRole fromString(String role) {
    switch (role) {
      case 'super_admin':
        return UserRole.superAdmin;
      case 'admin_institucion':
        return UserRole.adminInstitucion;
      case 'profesor':
        return UserRole.profesor;
      case 'estudiante':
        return UserRole.estudiante;
      default:
        throw ArgumentError('Rol desconocido: $role');
    }
  }

  /// ¿Es un administrador? (super admin o admin institución)
  bool get isAdmin {
    return this == UserRole.superAdmin || this == UserRole.adminInstitucion;
  }

  /// ¿Es super administrador?
  bool get isSuperAdmin {
    return this == UserRole.superAdmin;
  }
}