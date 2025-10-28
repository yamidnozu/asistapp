import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/theme_extensions.dart';
import '../utils/responsive_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final _emailController = TextEditingController(text: 'superadmin@asistapp.com');
  final _passwordController = TextEditingController(text: 'Admin123!');
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _buildMainTitle(Map<String, dynamic> responsive) {
    final titleFontSize = responsive['titleFontSize'] as double;

    return Builder(
      builder: (context) {
        final colors = context.colors;
        return Text(
          'AsistApp',
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
          textAlign: TextAlign.center,
        );
      },
    );
  }

  Widget _buildSubtitle(Map<String, dynamic> responsive, Color textMuted) {
    final subtitleFontSize = responsive['subtitleFontSize'] as double;

    return Text(
      'Sistema de Registro de Asistencia Escolar',
      style: TextStyle(
        color: textMuted,
        fontSize: subtitleFontSize,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: const InputDecoration(
        labelText: 'Correo electrónico',
        // No especificar border, fillColor, etc. - usa el tema
      ),
      keyboardType: TextInputType.emailAddress,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      decoration: const InputDecoration(
        labelText: 'Contraseña',
        // No especificar border, fillColor, etc. - usa el tema
      ),
      obscureText: true,
    );
  }

  Widget _buildLoginButton(Map<String, dynamic> responsive) {
    final buttonWidth = responsive['buttonWidth'] as double;

    return SizedBox(
      width: buttonWidth,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        child: Text(_isLoading ? 'Iniciando sesión...' : 'Iniciar Sesión'),
      ),
    );
  }

  Widget _buildTestUsersSection(Map<String, dynamic> responsive) {
    final bodyFontSize = responsive['bodyFontSize'] as double;

    return Builder(
      builder: (context) {
        final colors = context.colors;
        return Column(
          children: [
            const SizedBox(height: 32),
            Text(
              'Usuarios de Prueba (Desarrollo)',
              style: TextStyle(
                fontSize: bodyFontSize,
                fontWeight: FontWeight.bold,
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildTestUserButton(
                  'Super Admin',
                  'superadmin@asistapp.com',
                  'Admin123!',
                  'super_admin',
                  'Todas',
                  responsive,
                ),
                _buildTestUserButton(
                  'Admin Multi',
                  'multi@asistapp.com',
                  'Multi123!',
                  'admin_institucion',
                  '2 instituciones',
                  responsive,
                ),
                _buildTestUserButton(
                  'Admin San José',
                  'admin@sanjose.edu',
                  'SanJose123!',
                  'admin_institucion',
                  '1 institución',
                  responsive,
                ),
                _buildTestUserButton(
                  'Profesor',
                  'pedro.garcia@sanjose.edu',
                  'Prof123!',
                  'profesor',
                  '1 institución',
                  responsive,
                ),
                _buildTestUserButton(
                  'Estudiante',
                  'juan.perez@sanjose.edu',
                  'Est123!',
                  'estudiante',
                  '1 institución',
                  responsive,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildTestUserButton(
    String name,
    String email,
    String password,
    String role,
    String institutions,
    Map<String, dynamic> responsive,
  ) {
    final isSmallScreen = responsive['isSmallScreen'] as bool;
    final buttonWidth = isSmallScreen ? 140.0 : 160.0;

    return Builder(
      builder: (context) {
        final colors = context.colors;
        final textStyles = context.textStyles;

        return SizedBox(
          width: buttonWidth,
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                _emailController.text = email;
                _passwordController.text = password;
                _errorMessage = null;
              });
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              side: BorderSide(color: colors.primary.withValues(alpha: 0.5)),
            ),
            child: Column(
              children: [
                Text(
                  name,
                  style: textStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  role,
                  style: textStyles.bodySmall,
                  textAlign: TextAlign.center,
                ),
                Text(
                  institutions,
                  style: textStyles.bodySmall.copyWith(
                    fontStyle: FontStyle.italic,
                    color: colors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorMessage() {
    if (_errorMessage == null) return const SizedBox.shrink();

    return Builder(
      builder: (context) {
        final textStyles = context.textStyles;
        final colors = context.colors;
        return Text(
          _errorMessage!,
          style: textStyles.bodyMedium.copyWith(color: colors.error),  // Usar estilo del tema
          textAlign: TextAlign.center,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final responsive = ResponsiveUtils.getResponsiveValues(constraints);

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: responsive['maxWidth']),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive['horizontalPadding'],
                        vertical: responsive['verticalPadding'],
                      ),
                      child: Column(
                        children: [
                          _buildMainTitle(responsive),
                          SizedBox(height: responsive['elementSpacing']),

                          _buildSubtitle(responsive, colors.textMuted),
                          SizedBox(height: responsive['elementSpacing'] * 1.5),

                          _buildEmailField(),
                          SizedBox(height: responsive['elementSpacing']),

                          _buildPasswordField(),
                          SizedBox(height: responsive['elementSpacing']),

                          _buildErrorMessage(),
                          SizedBox(height: responsive['elementSpacing']),

                          _buildLoginButton(responsive),
                          SizedBox(height: responsive['elementSpacing']),

                          _buildTestUsersSection(responsive),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor complete todos los campos';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success) {


        debugPrint('Login exitoso, AuthWrapper manejará la navegación');
      } else {
        setState(() {
          _errorMessage = 'Credenciales incorrectas';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión. Intente nuevamente.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}