import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/institution_selection_screen.dart';
import '../screens/home_screen.dart';
import '../screens/super_admin_dashboard.dart';
import '../screens/admin_dashboard.dart';
import '../screens/teacher_dashboard.dart';
import '../screens/student_dashboard.dart';

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
    // final authProvider = context.read<AuthProvider>();

    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('App resumed');
        // authProvider.onAppResumed(); // TODO: Implementar si es necesario
        break;
      case AppLifecycleState.inactive:
        debugPrint('App inactive - transitioning');
        break;
      case AppLifecycleState.paused:
        debugPrint('App paused - preparing for background');
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
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Si no hay usuario autenticado, mostrar pantalla de login
        if (!authProvider.isAuthenticated) {
          return const LoginScreen();
        }

        // Si está autenticado pero no tiene institución seleccionada
        // y tiene múltiples instituciones, mostrar selector
        final institutions = authProvider.institutions;
        final selectedInstitutionId = authProvider.selectedInstitutionId;

        if (institutions != null && institutions.length > 1 && selectedInstitutionId == null) {
          return const InstitutionSelectionScreen();
        }

        // Si está autenticado, navegar según el rol del usuario
        final user = authProvider.user;
        final userRole = user?['rol'] as String?;

        // Determinar qué dashboard mostrar según el rol
        Widget dashboard;
        switch (userRole) {
          case 'super_admin':
            dashboard = const SuperAdminDashboard();
            break;
          case 'admin_institucion':
            dashboard = const AdminDashboard();
            break;
          case 'profesor':
            dashboard = const TeacherDashboard();
            break;
          case 'estudiante':
            dashboard = const StudentDashboard();
            break;
          default:
            // Fallback al dashboard genérico si el rol no está definido
            dashboard = const HomeScreen();
            break;
        }

        return dashboard;
      },
    );
  }
}