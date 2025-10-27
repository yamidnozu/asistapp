/// Todas las rutas de la app en un solo lugar
/// Usar estas constantes en lugar de escribir strings
class AppRoutes {
  AppRoutes._(); // No se puede instanciar
  static const String login = '/login';
  static const String institutionSelection = '/institution-selection';
  static const String superAdminDashboard = '/super-admin-dashboard';
  static const String adminDashboard = '/admin-dashboard';
  static const String teacherDashboard = '/teacher-dashboard';
  static const String studentDashboard = '/student-dashboard';
  static const String home = '/home';

  /// Qué dashboard le corresponde a cada rol
  static String getDashboardRouteForRole(String role) {
    switch (role) {
      case 'super_admin':
        return superAdminDashboard;
      case 'admin_institucion':
        return adminDashboard;
      case 'profesor':
        return teacherDashboard;
      case 'estudiante':
        return studentDashboard;
      default:
        return home;
    }
  }

  /// ¿Esta ruta necesita login?
  static bool requiresAuth(String route) {
    return route != login;
  }

  /// ¿Esta ruta es un dashboard?
  static bool isDashboard(String route) {
    return [
      superAdminDashboard,
      adminDashboard,
      teacherDashboard,
      studentDashboard,
      home,
    ].contains(route);
  }
}
