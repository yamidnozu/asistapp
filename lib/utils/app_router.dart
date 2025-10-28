import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/navigation_state_provider.dart';
import '../screens/login_screen.dart';
import '../screens/institution_selection_screen.dart';
import '../screens/home_screen.dart';
import '../screens/super_admin_dashboard.dart';
import '../screens/admin_dashboard.dart';
import '../screens/teacher_dashboard.dart';
import '../screens/student_dashboard.dart';
import '../screens/institutions/institutions_list_screen.dart';
import '../screens/institutions/institution_form_screen.dart';
import '../models/institution.dart';
import '../theme/theme_extensions.dart';
import 'app_routes.dart';

/// Router principal de la aplicación
/// Maneja rutas, autenticación y deep linking
class AppRouter {
  final AuthProvider authProvider;
  final NavigationStateProvider navigationProvider;

  AppRouter({
    required this.authProvider,
    required this.navigationProvider,
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

    if (navigationProvider.hasValidState() && 
        navigationProvider.currentRoute != null) {
      return navigationProvider.currentRoute!;
    }

    if (authProvider.isAuthenticated) {
      final role = authProvider.user?['rol'] as String?;
      return AppRoutes.getDashboardRouteForRole(role ?? '');
    }

    return AppRoutes.login;
  }


  /// Verifica si puede entrar a cada ruta
  String? _checkAuth(BuildContext context, GoRouterState state) {
    final isLoggedIn = authProvider.isAuthenticated;
    final currentRoute = state.matchedLocation;

    // Si estamos en login y estamos logueados
    if (currentRoute == AppRoutes.login) {
      if (isLoggedIn) {
        final institutions = authProvider.institutions;
        final selected = authProvider.selectedInstitutionId;
        
        // Si tenemos múltiples instituciones y no hay selección, ir a selección
        if (institutions != null && institutions.length > 1 && selected == null) {
          return AppRoutes.institutionSelection;
        }
        
        // Si no, ir al dashboard correspondiente
        final role = authProvider.user?['rol'] as String?;
        return AppRoutes.getDashboardRouteForRole(role ?? '');
      }
      return null; // Dejar entrar al login
    }

    // Si no estamos logueados, ir al login
    if (!isLoggedIn) {
      return AppRoutes.login;
    }

    // Si estamos en una ruta protegida y necesitamos selección de institución
    final institutions = authProvider.institutions;
    final selected = authProvider.selectedInstitutionId;
    final needsSelection = institutions != null && 
                          institutions.length > 1 && 
                          selected == null &&
                          currentRoute != AppRoutes.institutionSelection &&
                          !currentRoute.startsWith('/institutions'); // Excluir rutas de instituciones
    
    if (needsSelection) {
      return AppRoutes.institutionSelection;
    }

    // Verificar permisos para rutas de instituciones (solo super_admin)
    if (currentRoute.startsWith('/institutions')) {
      final role = authProvider.user?['rol'] as String?;
      if (role != 'super_admin') {
        // Si no es super_admin, redirigir al dashboard correspondiente
        return AppRoutes.getDashboardRouteForRole(role ?? '');
      }
    }
    
    return null; // Todo bien, dejar pasar
  }


  /// Todas las rutas de la app
  List<RouteBase> _allRoutes() {
    return [

      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => _fadePage(
          context,
          state,
          const LoginScreen(),
        ),
      ),

      GoRoute(
        path: AppRoutes.institutionSelection,
        name: 'institution-selection',
        pageBuilder: (context, state) => _fadePage(
          context,
          state,
          const InstitutionSelectionScreen(),
        ),
      ),

      GoRoute(
        path: AppRoutes.superAdminDashboard,
        name: 'super-admin',
        pageBuilder: (context, state) {
          _saveRoute(state);
          return _fadePage(context, state, const SuperAdminDashboard());
        },
      ),

      GoRoute(
        path: AppRoutes.adminDashboard,
        name: 'admin',
        pageBuilder: (context, state) {
          _saveRoute(state);
          return _fadePage(context, state, const AdminDashboard());
        },
      ),

      GoRoute(
        path: AppRoutes.teacherDashboard,
        name: 'teacher',
        pageBuilder: (context, state) {
          _saveRoute(state);
          return _fadePage(context, state, const TeacherDashboard());
        },
      ),

      GoRoute(
        path: AppRoutes.studentDashboard,
        name: 'student',
        pageBuilder: (context, state) {
          _saveRoute(state);
          return _fadePage(context, state, const StudentDashboard());
        },
      ),

      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        pageBuilder: (context, state) {
          _saveRoute(state);
          return _fadePage(context, state, const HomeScreen());
        },
      ),

      // Rutas de instituciones (solo para super_admin)
      GoRoute(
        path: AppRoutes.institutionsList,
        name: 'institutions-list',
        pageBuilder: (context, state) {
          _saveRoute(state);
          return _fadePage(context, state, const InstitutionsListScreen());
        },
      ),

      GoRoute(
        path: AppRoutes.institutionForm,
        name: 'institution-form',
        pageBuilder: (context, state) {
          final institutionId = state.uri.queryParameters['id'];
          final institution = institutionId != null
              ? state.extra as Institution?
              : null;

          _saveRoute(state);
          return _fadePage(
            context,
            state,
            InstitutionFormScreen(institution: institution),
          );
        },
      ),
    ];
  }


  /// Guarda la ruta actual
  void _saveRoute(GoRouterState state) {
    final route = state.matchedLocation;
    final params = state.uri.queryParameters;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigationProvider.saveNavigationState(
        route,
        arguments: params.isNotEmpty ? params : null,
      );
    });
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
      body: Builder(
        builder: (ctx) {
          final colors = ctx.colors;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: colors.error),
                const SizedBox(height: 16),
                const Text('Error de Navegación', 
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('${state.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.go(AppRoutes.login),
                  child: const Text('Ir al inicio'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Limpiar al cerrar
  void dispose() {
    router.dispose();
  }
}
