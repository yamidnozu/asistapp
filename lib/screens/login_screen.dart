import 'package:flutter/widgets.dart';
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

  // Función para calcular variables responsive
  Map<String, dynamic> _getResponsiveValues(BoxConstraints constraints, double lg, double xxl, double xl, double sm, double md) {
    final isSmallScreen = constraints.maxWidth < 600;
    final horizontalPadding = isSmallScreen ? lg : xxl;
    final verticalPadding = isSmallScreen ? xl : xxl * 2;
    final titleSpacing = isSmallScreen ? sm : md;
    final subtitleSpacing = isSmallScreen ? xl : xxl; // Reducido de xxl*2/xxl*3 a xl/xxl

    return {
      'isSmallScreen': isSmallScreen,
      'horizontalPadding': horizontalPadding,
      'verticalPadding': verticalPadding,
      'titleSpacing': titleSpacing,
      'subtitleSpacing': subtitleSpacing,
    };
  }

  // Función para construir el título principal
  Widget _buildMainTitle(TextStyle displayLarge, bool isSmallScreen) {
    return Text(
      'AsistApp',
      style: displayLarge.copyWith(
        fontSize: isSmallScreen ? 32 : 48,
      ),
      textAlign: TextAlign.center,
    );
  }

  // Función para construir el subtítulo
  Widget _buildSubtitle(TextStyle bodyMedium, Color textMuted, bool isSmallScreen) {
    return Text(
      'Sistema de Registro de Asistencia Escolar',
      style: bodyMedium.copyWith(
        color: textMuted,
        fontSize: isSmallScreen ? 14 : 16,
      ),
      textAlign: TextAlign.center,
    );
  }

  // Función para construir el botón de Google
  Widget _buildGoogleButton() {
    return AppButton(
      label: _isLoading ? 'Iniciando sesión...' : 'Continuar con Google',
      onPressed: _isLoading ? () {} : _signInWithGoogle,
      isLoading: _isLoading,
      isEnabled: !_isLoading,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final textStyles = context.textStyles;

    return Container(
      color: colors.background,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final responsive = _getResponsiveValues(constraints, spacing.lg, spacing.xxl, spacing.xl, spacing.sm, spacing.md);
            final isSmallScreen = responsive['isSmallScreen'] as bool;
            final horizontalPadding = responsive['horizontalPadding'] as double;
            final verticalPadding = responsive['verticalPadding'] as double;
            final titleSpacing = responsive['titleSpacing'] as double;
            final subtitleSpacing = responsive['subtitleSpacing'] as double;

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: AppConstants.instance.maxScreenWidth),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Título principal
                      _buildMainTitle(textStyles.displayLarge, isSmallScreen),
                      SizedBox(height: titleSpacing),

                      // Subtítulo
                      _buildSubtitle(textStyles.bodyMedium, colors.textMuted, isSmallScreen),
                      SizedBox(height: subtitleSpacing),

                      // Botón de Google
                      _buildGoogleButton(),
                    ],
                  ),
                ),
              ),
            );
          },
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
      } else {
        debugPrint('⚠️ Login cancelado o fallido');
      }
    } catch (e) {
      debugPrint('❌ Error en UI de login: $e');

      // Manejar diferentes tipos de errores (solo logging, sin mostrar modales)
      if (e.toString().contains('network') || e.toString().contains('Network')) {
        debugPrint('Error de conexión. Verifica tu internet.');
      } else if (e.toString().contains('cancelled') || e.toString().contains('CANCELLED')) {
        debugPrint('Login cancelado por el usuario');
      } else if (e.toString().contains('unavailable') || e.toString().contains('UNAVAILABLE')) {
        debugPrint('Servicio no disponible. Intenta más tarde.');
      } else if (e.toString().contains('sign_in_failed') || e.toString().contains('SIGN_IN_FAILED')) {
        debugPrint('Error de configuración. Revisa la consola de Firebase.');
      } else if (e.toString().contains('developer_error') || e.toString().contains('DEVELOPER_ERROR')) {
        debugPrint('Error de configuración. Configura SHA-1 en Google Cloud Console.');
      } else {
        debugPrint('Error de autenticación. Revisa los logs para más detalles.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}