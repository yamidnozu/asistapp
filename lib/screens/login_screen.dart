import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart' show AlertDialog, TextButton, Navigator, showDialog;
import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import '../ui/widgets/index.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo o ícono
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text(
                      '✓',
                      style: TextStyle(
                        fontSize: 48,
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'AsistApp',
                  style: AppTextStyles.displayLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Sistema de Registro de Asistencia Escolar',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl * 2),
                AppCard(
                  child: Column(
                    children: [
                      Text(
                        'Bienvenido',
                        style: AppTextStyles.headlineMedium,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Administra tus tareas y asignaciones de forma eficiente',
                        style: AppTextStyles.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AppButton(
                        label: _isLoading ? 'Iniciando sesión...' : 'Continuar con Google',
                        onPressed: _isLoading ? () {} : _signInWithGoogle,
                        isLoading: _isLoading,
                        isEnabled: !_isLoading,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppButton(
                        label: _isLoading ? 'Cargando...' : 'Continuar como Invitado',
                        onPressed: _isLoading ? () {} : _signInAnonymously,
                        isLoading: _isLoading,
                        isEnabled: !_isLoading,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      print('🚀 Iniciando login con Google desde UI...');
      final result = await _authService.signInWithGoogle();

      if (result != null && result.user != null) {
        print('✅ Login exitoso: ${result.user!.email}');

        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.syncUserData();

        if (mounted) {
          // Mostrar diálogo de éxito en lugar de SnackBar
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('¡Éxito!'),
              content: Text('¡Bienvenido ${result.user!.displayName ?? result.user!.email}!'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        print('⚠️ Login cancelado o fallido');
        if (mounted) {
          // Mostrar diálogo de error en lugar de SnackBar
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Error'),
              content: const Text('Login cancelado o no autorizado'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error en UI de login: $e');

      String errorMessage = 'Error desconocido al iniciar sesión';

      // Manejar diferentes tipos de errores
      if (e.toString().contains('network') || e.toString().contains('Network')) {
        errorMessage = 'Error de conexión. Verifica tu internet.';
      } else if (e.toString().contains('cancelled') || e.toString().contains('CANCELLED')) {
        errorMessage = 'Login cancelado por el usuario';
      } else if (e.toString().contains('unavailable') || e.toString().contains('UNAVAILABLE')) {
        errorMessage = 'Servicio no disponible. Intenta más tarde.';
      } else if (e.toString().contains('sign_in_failed') || e.toString().contains('SIGN_IN_FAILED')) {
        errorMessage = 'Error de configuración. Revisa la consola de Firebase.';
      } else if (e.toString().contains('developer_error') || e.toString().contains('DEVELOPER_ERROR')) {
        errorMessage = 'Error de configuración. Configura SHA-1 en Google Cloud Console.';
      } else {
        errorMessage = 'Error de autenticación. Revisa los logs para más detalles.';
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(errorMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInAnonymously() async {
    setState(() => _isLoading = true);
    try {
      final result = await _authService.signInAnonymously();
      if (result != null) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.syncUserData();
        // Usuario autenticado exitosamente - permanecer en la pantalla
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('¡Éxito!'),
              content: const Text('¡Bienvenido! Has iniciado sesión como invitado'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Error'),
              content: const Text('No se pudo completar el inicio de sesión'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error signing in anonymously: $e');
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: const Text('Error al iniciar sesión como invitado'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}