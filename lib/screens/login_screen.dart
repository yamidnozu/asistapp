import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show AlertDialog, TextButton, Navigator, showDialog;
import '../services/auth_service.dart';
import '../theme/theme_extensions.dart';
import '../theme/app_constants.dart';
import '../ui/widgets/index.dart';

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
    final colors = context.colors;
    final spacing = context.spacing;
    final textStyles = context.textStyles;

    return Container(
      color: colors.background,
      child: SafeArea(
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: AppConstants.instance.maxScreenWidth),
            padding: EdgeInsets.all(spacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'AsistApp',
                  style: textStyles.displayLarge,
                ),
                SizedBox(height: spacing.sm),
                Text(
                  'Sistema de Registro de Asistencia Escolar',
                  style: textStyles.bodyMedium.copyWith(
                    color: colors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: spacing.xxl * 2),
                Container(
                  padding: EdgeInsets.all(spacing.md),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(AppConstants.instance.cardBorderRadius),
                    border: Border.all(
                      color: colors.border,
                      width: AppConstants.instance.borderWidthThin,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadowLight,
                        blurRadius: AppConstants.instance.shadowBlurRadius,
                        offset: Offset(0, AppConstants.instance.shadowOffsetY),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Bienvenido',
                        style: textStyles.headlineMedium,
                      ),
                      SizedBox(height: spacing.md),
                      Text(
                        'Administra tus tareas y asignaciones de forma eficiente',
                        style: textStyles.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: spacing.xl),
                      AppButton(
                        label: _isLoading ? 'Iniciando sesión...' : 'Continuar con Google',
                        onPressed: _isLoading ? () {} : _signInWithGoogle,
                        isLoading: _isLoading,
                        isEnabled: !_isLoading,
                      ),
                      SizedBox(height: spacing.md),
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
      debugPrint('🚀 Iniciando login con Google desde UI...');
      final result = await _authService.signInWithGoogle();

      if (result != null && result.user != null) {
        debugPrint('✅ Login exitoso: ${result.user!.email}');

        // Usuario autenticado exitosamente - el provider se actualiza automáticamente

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
        debugPrint('⚠️ Login cancelado o fallido');
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
      debugPrint('❌ Error en UI de login: $e');

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
        // Usuario autenticado exitosamente - el provider se actualiza automáticamente
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