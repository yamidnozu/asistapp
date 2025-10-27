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

    return Text(
      'AsistApp',
      style: TextStyle(
        fontSize: titleFontSize,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
      textAlign: TextAlign.center,
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
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.emailAddress,
    );
  }

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

    return Column(
      children: [
        const SizedBox(height: 32),
        Text(
          'Usuarios de Prueba (Desarrollo)',
          style: TextStyle(
            fontSize: bodyFontSize,
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
              responsive,
            ),
            _buildTestUserButton(
              'Admin Multi',
              'multi@asistapp.com',
              'Multi123!',
              'admin_institucion',
              '2 instituciones',
              Colors.green,
              responsive,
            ),
            _buildTestUserButton(
              'Admin San José',
              'admin@sanjose.edu',
              'SanJose123!',
              'admin_institucion',
              '1 institución',
              Colors.orange,
              responsive,
            ),
            _buildTestUserButton(
              'Profesor',
              'pedro.garcia@sanjose.edu',
              'Prof123!',
              'profesor',
              '1 institución',
              Colors.red,
              responsive,
            ),
            _buildTestUserButton(
              'Estudiante',
              'juan.perez@sanjose.edu',
              'Est123!',
              'estudiante',
              '1 institución',
              Colors.purple,
              responsive,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Presiona un botón para autocompletar los campos',
          style: TextStyle(
            fontSize: bodyFontSize * 0.8,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTestUserButton(
    String name,
    String email,
    String password,
    String role,
    String institutions,
    Color color,
    Map<String, dynamic> responsive,
  ) {
    final isSmallScreen = responsive['isSmallScreen'] as bool;
    final bodyFontSize = responsive['bodyFontSize'] as double;
    final buttonWidth = isSmallScreen ? 140.0 : 160.0;

    return SizedBox(
      width: buttonWidth,
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
                fontSize: bodyFontSize * 0.9,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              role,
              style: TextStyle(
                fontSize: bodyFontSize * 0.8,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              institutions,
              style: TextStyle(
                fontSize: bodyFontSize * 0.75,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

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