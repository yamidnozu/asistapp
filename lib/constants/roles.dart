/// Constantes para roles de usuario en AsistApp
/// Central para evitar strings mágicos en toda la aplicación

class UserRoles {
  static const String superAdmin = 'super_admin';
  static const String adminInstitucion = 'admin_institucion';
  static const String profesor = 'profesor';
  static const String estudiante = 'estudiante';
  static const String acudiente = 'acudiente';

  /// Verifica si un string es un rol válido
  static bool isValidRole(String role) {
    return [superAdmin, adminInstitucion, profesor, estudiante, acudiente].contains(role);
  }

  /// Verifica si un rol tiene permisos de administración
  static bool isAdminRole(String role) {
    return role == superAdmin || role == adminInstitucion;
  }

  /// Verifica si un rol puede gestionar clases
  static bool canManageClasses(String role) {
    return isAdminRole(role) || role == profesor;
  }

  /// Verifica si un rol puede ver asistencias de estudiantes
  static bool canViewStudentAttendance(String role) {
    return isAdminRole(role) || role == profesor || role == acudiente;
  }

  /// Obtiene el nombre legible de un rol
  static String getRoleName(String role) {
    switch (role) {
      case superAdmin:
        return 'Super Administrador';
      case adminInstitucion:
        return 'Administrador de Institución';
      case profesor:
        return 'Profesor';
      case estudiante:
        return 'Estudiante';
      case acudiente:
        return 'Acudiente';
      default:
        return 'Desconocido';
    }
  }
}
