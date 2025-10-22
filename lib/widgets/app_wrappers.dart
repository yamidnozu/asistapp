import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../screens/login_screen.dart';
import '../screens/welcome_screen.dart';
import '../theme/app_colors.dart';

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
    final userProvider = context.read<UserProvider>();

    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('App resumed - optimizing data loading');
        userProvider.onAppResumed();
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
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // Mostrar loading mientras se verifica el estado
        if (userProvider.isLoading) {
          return Container(
            color: AppColors.instance.black,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Si hay usuario autenticado, mostrar pantalla de bienvenida
        if (userProvider.currentUser != null) {
          return const WelcomeScreen();
        }

        // Si no hay usuario, mostrar pantalla de login
        return const LoginScreen();
      },
    );
  }
}