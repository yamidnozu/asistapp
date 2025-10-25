import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/theme_extensions.dart';
import '../theme/app_constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Valores por defecto para desarrollo
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

  // Función para construir el campo de email
  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: const InputDecoration(
        labelText: 'Correo electrónico',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.emailAddress,
    );
  }

  // Función para construir el campo de contraseña
  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      decoration: const InputDecoration(
        labelText: 'Contraseña',
        border: OutlineInputBorder(),
      ),
      obscureText: true,
    );
  }

  // Función para construir el botón de login
  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _login,
      child: Text(_isLoading ? 'Iniciando sesión...' : 'Iniciar Sesión'),
    );
  }

  // Función para construir la sección de usuarios de prueba
  Widget _buildTestUsersSection(bool isSmallScreen) {
    return Column(
      children: [
        const SizedBox(height: 32),
        Text(
          'Usuarios de Prueba (Desarrollo)',
          style: TextStyle(
            fontSize: isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
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
              Colors.blue,
              isSmallScreen,
            ),
            _buildTestUserButton(
              'Admin Multi',
              'multi@asistapp.com',
              'Multi123!',
              'admin_institucion',
              '2 instituciones',
              Colors.green,
              isSmallScreen,
            ),
            _buildTestUserButton(
              'Admin San José',
              'admin@sanjose.edu',
              'SanJose123!',
              'admin_institucion',
              '1 institución',
              Colors.orange,
              isSmallScreen,
            ),
            _buildTestUserButton(
              'Profesor',
              'pedro.garcia@sanjose.edu',
              'Prof123!',
              'profesor',
              '1 institución',
              Colors.red,
              isSmallScreen,
            ),
            _buildTestUserButton(
              'Estudiante',
              'juan.perez@sanjose.edu',
              'Est123!',
              'estudiante',
              '1 institución',
              Colors.purple,
              isSmallScreen,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Presiona un botón para autocompletar los campos',
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 14,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Función para construir un botón de usuario de prueba
  Widget _buildTestUserButton(
    String name,
    String email,
    String password,
    String role,
    String institutions,
    Color color,
    bool isSmallScreen,
  ) {
    return SizedBox(
      width: isSmallScreen ? 140 : 160,
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _emailController.text = email;
            _passwordController.text = password;
            _errorMessage = null;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.1),
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.3)),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        ),
        child: Column(
          children: [
            Text(
              name,
              style: TextStyle(
                fontSize: isSmallScreen ? 11 : 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              role,
              style: TextStyle(
                fontSize: isSmallScreen ? 9 : 10,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              institutions,
              style: TextStyle(
                fontSize: isSmallScreen ? 8 : 9,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Función para construir el mensaje de error
  Widget _buildErrorMessage() {
    if (_errorMessage == null) return const SizedBox.shrink();

    return Text(
      _errorMessage!,
      style: const TextStyle(color: Colors.red),
      textAlign: TextAlign.center,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final textStyles = context.textStyles;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
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

                      // Campo de email
                      _buildEmailField(),
                      SizedBox(height: spacing.lg),

                      // Campo de contraseña
                      _buildPasswordField(),
                      SizedBox(height: spacing.lg),

                      // Mensaje de error
                      _buildErrorMessage(),
                      SizedBox(height: spacing.lg),

                      // Botón de login
                      _buildLoginButton(),
                      SizedBox(height: spacing.lg),

                      // Usuarios de prueba (desarrollo)
                      _buildTestUsersSection(isSmallScreen),
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
        // La navegación ahora la maneja el AuthWrapper basado en el estado de autenticación
        // No necesitamos hacer nada más aquí, el AuthWrapper se encargará de la navegación
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