import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/super_admin_dashboard.dart';
import '../screens/admin_dashboard.dart';
import '../screens/teacher_dashboard.dart';
import '../screens/student_dashboard.dart';
import '../screens/users/users_list_screen.dart';
import '../screens/users/user_form_screen.dart';
import '../screens/users/user_detail_screen.dart';
import '../screens/institutions/institutions_list_screen.dart';
import '../screens/institutions/institution_admins_screen.dart';
import '../screens/institutions/institution_form_screen.dart';
import '../screens/institutions/create_institution_admin_screen.dart';
import '../screens/academic/gestion_academica_screen.dart';
import '../screens/academic/grupos_screen.dart';
import '../screens/academic/materias_screen.dart';
import '../screens/academic/horarios_screen.dart';
import '../screens/academic/periodos_academicos_screen.dart';
import '../screens/academic/grupo_detail_screen.dart';
import '../models/institution.dart';
import '../screens/app_shell.dart';
import '../models/user.dart';
import '../models/grupo.dart';
import '../screens/student_schedule_screen.dart';
import '../screens/student_attendance_screen.dart';
import '../screens/student_notifications_screen.dart';
import '../screens/test_multi_hora_screen.dart';
import '../screens/my_qr_code_screen.dart';

// Global keys for navigation branches
final _dashboardNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'Dashboard');
final _institutionsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'Institutions');
final _usersNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'Users');

/// Router principal de la aplicación
/// Maneja rutas, autenticación y deep linking
class AppRouter {
  final AuthProvider authProvider;

  AppRouter({
    required this.authProvider,
  });

  late final GoRouter router = GoRouter(
    debugLogDiagnostics: true,
    refreshListenable: authProvider,
    initialLocation: _getStartRoute(),
    redirect: _checkAuth,
    routes: _allRoutes(),
    errorBuilder: _errorPage,
  );

  /// Decide dónde empezar cuando abre la app
  String _getStartRoute() {
    if (authProvider.isAuthenticated) {
      return '/dashboard';
    }
    return '/login';
  }

  /// Verifica si puede entrar a cada ruta
  String? _checkAuth(BuildContext context, GoRouterState state) {
    final isLoggedIn = authProvider.isAuthenticated;
    final currentRoute = state.matchedLocation;

    // 1. Si el usuario NO está logueado, se va para el login.
    if (!isLoggedIn) {
      return '/login';
    }

    // A partir de aquí, el usuario SÍ está logueado.
    final institutions = authProvider.institutions;
    final selectedInstitutionId = authProvider.selectedInstitutionId;
    final needsSelection = institutions != null &&
                          institutions.length > 1 &&
                          selectedInstitutionId == null;

    // 2. Si el usuario está en la pantalla de login pero ya está logueado, se va para el dashboard.
    if (currentRoute == '/login') {
      return '/dashboard';
    }

    // 3. Si necesita seleccionar institución y NO está en la pantalla de selección, se le redirige allí.
    if (needsSelection && currentRoute != '/institution-selection') {
      return '/institution-selection';
    }

    // 4. [LA CLAVE DE LA SOLUCIÓN]
    // Si el usuario ya seleccionó (needsSelection es false) pero sigue en la pantalla de selección,
    // lo redirigimos al dashboard para que no se quede atascado.
    if (!needsSelection && currentRoute == '/institution-selection') {
      return '/dashboard';
    }

    // 5. Si no se cumple ninguna de las condiciones anteriores, no se redirige a ningún lado.
    return null;
  }

  /// Todas las rutas de la app
  List<RouteBase> _allRoutes() {
    return [
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => _fadePage(
          context,
          state,
          const LoginScreen(),
        ),
      ),

      // --- RUTAS DE FORMULARIOS (NIVEL SUPERIOR) ---
      GoRoute(
        path: '/users/create',
        name: 'create-user',
        pageBuilder: (context, state) {
          final userRole = state.extra as String?;
          return MaterialPage(
            fullscreenDialog: true,
            name: 'Crear Usuario',
            child: UserFormScreen(userRole: userRole ?? 'estudiante'),
          );
        },
      ),
      GoRoute(
        path: '/users/detail/:id',
        name: 'user-detail',
        builder: (context, state) {
          final user = state.extra as User;
          return UserDetailScreen(user: user);
        },
      ),

      // StatefulShellRoute para navegación persistente
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Dashboard
          StatefulShellBranch(
            navigatorKey: _dashboardNavigatorKey,
            routes: [
              GoRoute(
                path: '/dashboard',
                name: 'dashboard',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: _getDashboardForRole(),
                ),
              ),
              // Rutas académicas
              GoRoute(
                path: '/academic',
                name: 'academic-management',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: const GestionAcademicaScreen(),
                ),
              ),
              GoRoute(
                path: '/academic/grupos',
                name: 'academic-grupos',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: const GruposScreen(),
                ),
              ),
              GoRoute(
                path: '/academic/materias',
                name: 'academic-materias',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: const MateriasScreen(),
                ),
              ),
              GoRoute(
                path: '/academic/periodos',
                name: 'academic-periodos',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: const PeriodosAcademicosScreen(),
                ),
              ),
              GoRoute(
                path: '/academic/horarios',
                name: 'academic-horarios',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: const HorariosScreen(),
                ),
              ),
              GoRoute(
                path: '/test-multi-hora',
                name: 'test-multi-hora',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: const TestMultiHoraScreen(),
                ),
              ),
              GoRoute(
                path: '/academic/grupos/:id',
                name: 'academic-grupo-detail',
                pageBuilder: (context, state) {
                  final grupo = state.extra as Grupo;
                  return NoTransitionPage(
                    child: GrupoDetailScreen(grupo: grupo),
                  );
                },
              ),
              // Ruta para el código QR del estudiante
              GoRoute(
                path: '/student/qr',
                name: 'student-qr',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: const MyQRCodeScreen(),
                ),
              ),
              // Rutas para módulos del estudiante
              GoRoute(
                path: '/student/schedule',
                name: 'student-schedule',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: const StudentScheduleScreen(),
                ),
              ),
              GoRoute(
                path: '/student/attendance',
                name: 'student-attendance',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: const StudentAttendanceScreen(),
                ),
              ),
              GoRoute(
                path: '/student/notifications',
                name: 'student-notifications',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: const StudentNotificationsScreen(),
                ),
              ),
            ],
          ),

          // Branch 1: Instituciones
          StatefulShellBranch(
            navigatorKey: _institutionsNavigatorKey,
            routes: [
              GoRoute(
                path: '/institutions',
                name: 'institutions-list',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: const InstitutionsListScreen(),
                ),
              ),
              // Route to open the Institution form (create/edit) using extra to pass the Institution object when needed
              GoRoute(
                path: '/institutions/form',
                name: 'institution-form',
                pageBuilder: (context, state) {
                  final institution = state.extra as Institution?;
                  return MaterialPage(
                    fullscreenDialog: true,
                    name: 'Institution Form',
                    child: InstitutionFormScreen(institution: institution),
                  );
                },
              ),
              // Route to create an admin for an institution (expects Institution in extra)
              GoRoute(
                path: '/institutions/create-admin',
                name: 'institution-create-admin',
                pageBuilder: (context, state) {
                  final institution = state.extra as Institution;
                  return MaterialPage(
                    fullscreenDialog: true,
                    name: 'Create Institution Admin',
                    child: CreateInstitutionAdminScreen(institution: institution),
                  );
                },
              ),
              GoRoute(
                path: '/institutions/:id/admins',
                name: 'institution-admins',
                pageBuilder: (context, state) {
                  // Extraer id desde los segmentos de la URI (compatible con distintas versiones de go_router)
                  final segments = state.uri.pathSegments;
                  final id = segments.length >= 2 ? segments[1] : '';
                  return MaterialPage(
                    fullscreenDialog: false,
                    name: 'Institution Admins',
                    child: InstitutionAdminsScreen(institutionId: id),
                  );
                },
              ),
            ],
          ),

          // Branch 2: Usuarios
          StatefulShellBranch(
            navigatorKey: _usersNavigatorKey,
            routes: [
              GoRoute(
                path: '/users',
                name: 'users-list',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: const UsersListScreen(),
                ),
                // Las rutas de formularios se movieron arriba
              ),
            ],
          ),
        ],
      ),
    ];
  }

  /// Obtiene el dashboard correcto basado en el rol del usuario
  Widget _getDashboardForRole() {
    final role = authProvider.user?['rol'] as String?;
    switch (role) {
      case 'super_admin':
        return const SuperAdminDashboard();
      case 'admin_institucion':
        return const AdminDashboard();
      case 'profesor':
        return const TeacherDashboard();
      case 'estudiante':
        return const StudentDashboard();
      default:
        // Rol desconocido, redirigir a login
        return const LoginScreen();
    }
  }

  /// Crea página con transición fade
  Page _fadePage(BuildContext context, GoRouterState state, Widget child) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  /// Página de error
  Widget _errorPage(BuildContext context, GoRouterState state) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Error de Navegación', 
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${state.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              child: const Text('Ir al inicio'),
            ),
          ],
        ),
      ),
    );
  }

  /// Limpiar al cerrar
  void dispose() {
    router.dispose();
  }
}
