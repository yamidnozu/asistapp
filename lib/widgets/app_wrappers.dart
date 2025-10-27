import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/navigation_state_provider.dart';
import '../screens/login_screen.dart';
import '../screens/institution_selection_screen.dart';
import '../screens/home_screen.dart';
import '../screens/super_admin_dashboard.dart';
import '../screens/admin_dashboard.dart';
import '../screens/teacher_dashboard.dart';
import '../screens/student_dashboard.dart';
import '../utils/app_routes.dart';

/// Wrapper que maneja el ciclo de vida de la aplicación
class LifecycleAwareWrapper extends StatefulWidget {
  const LifecycleAwareWrapper({super.key});

  @override
  State<LifecycleAwareWrapper> createState() => _LifecycleAwareWrapperState();
}

class _LifecycleAwareWrapperState extends State<LifecycleAwareWrapper>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final navigationProvider = Provider.of<NavigationStateProvider>(context, listen: false);

    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('App resumed - recovering full state');
        authProvider.recoverFullState();
        if (!navigationProvider.hasValidState()) {
          navigationProvider.clearNavigationState();
        }
        break;
      case AppLifecycleState.inactive:
        debugPrint('App inactive - transitioning');
        break;
      case AppLifecycleState.paused:
        debugPrint('App paused - saving current state');
        navigationProvider.refreshStateTimestamp();
        break;
      case AppLifecycleState.hidden:
        debugPrint('App hidden');
        break;
      case AppLifecycleState.detached:
        debugPrint('App detached');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const AuthWrapper();
  }
}

/// Wrapper que maneja la autenticación y navegación inicial
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, NavigationStateProvider>(
      builder: (context, authProvider, navigationProvider, child) {
        if (!authProvider.isAuthenticated) {
          return const LoginScreen();
        }
        final institutions = authProvider.institutions;
        final selectedInstitutionId = authProvider.selectedInstitutionId;

        if (institutions != null && institutions.length > 1 && selectedInstitutionId == null) {
          return const InstitutionSelectionScreen();
        }
        if (navigationProvider.hasValidState() && navigationProvider.currentRoute != null) {
          final savedRoute = navigationProvider.currentRoute!;
          debugPrint('Recuperando navegación guardada: $savedRoute');
          
          return _getScreenForRoute(savedRoute, authProvider);
        }
        final user = authProvider.user;
        final userRole = user?['rol'] as String?;
        Widget dashboard;
        String route;
        
        switch (userRole) {
          case 'super_admin':
            dashboard = const SuperAdminDashboard();
            route = AppRoutes.superAdminDashboard;
            break;
          case 'admin_institucion':
            dashboard = const AdminDashboard();
            route = AppRoutes.adminDashboard;
            break;
          case 'profesor':
            dashboard = const TeacherDashboard();
            route = AppRoutes.teacherDashboard;
            break;
          case 'estudiante':
            dashboard = const StudentDashboard();
            route = AppRoutes.studentDashboard;
            break;
          default:
            dashboard = const HomeScreen();
            route = AppRoutes.home;
            break;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigationProvider.saveNavigationState(route);
        });

        return dashboard;
      },
    );
  }

  /// Obtiene la pantalla correspondiente a una ruta guardada
  Widget _getScreenForRoute(String route, AuthProvider authProvider) {
    switch (route) {
      case AppRoutes.superAdminDashboard:
        return const SuperAdminDashboard();
      case AppRoutes.adminDashboard:
        return const AdminDashboard();
      case AppRoutes.teacherDashboard:
        return const TeacherDashboard();
      case AppRoutes.studentDashboard:
        return const StudentDashboard();
      case AppRoutes.institutionSelection:
        return const InstitutionSelectionScreen();
      case AppRoutes.home:
        return const HomeScreen();
      default:
        final userRole = authProvider.user?['rol'] as String?;
        final defaultRoute = AppRoutes.getDashboardRouteForRole(userRole ?? '');
        return _getScreenForRoute(defaultRoute, authProvider);
    }
  }
}