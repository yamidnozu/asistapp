import 'dart:convert';
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
          key: const Key('appTitle'),
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
      key: const Key('emailField'),
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
      key: const Key('passwordField'),
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
        key: const Key('loginButton'),
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
            // Super Admins
            _buildUserCategory(
              '👑 Super Administradores',
              [
                _buildTestUserButton('Super Admin (Activo)', 'superadmin@asistapp.com', 'Admin123!', 'super_admin', 'Sistema completo', responsive),
                _buildTestUserButton('Super Admin (Inactivo)', 'inactive.super@asistapp.com', 'InactiveSuper123!', 'super_admin', 'Inactivo', responsive),
              ],
              responsive,
            ),

            // Admins de Institución
            _buildUserCategory(
              '👨‍💼 Administradores de Institución',
              [
                _buildTestUserButton('Admin San José', 'admin@sanjose.edu', 'SanJose123!', 'admin_institucion', 'Colegio San José', responsive),
                _buildTestUserButton('Admin Inactivo', 'inactive.admin@sanjose.edu', 'InactiveAdmin123!', 'admin_institucion', 'Usuario inactivo', responsive),
                _buildTestUserButton('Admin Inst. Inactiva', 'admin@inactiva.edu', 'AdminInactiva123!', 'admin_institucion', 'Institución inactiva', responsive),
                _buildTestUserButton('Admin Multi-Inst.', 'multi@asistapp.com', 'Multi123!', 'admin_institucion', '2 instituciones', responsive),
                _buildTestUserButton('Admin Mixto', 'admin.mixto@asistapp.com', 'AdminMixto123!', 'admin_institucion', 'Mixto activo/inactivo', responsive),
              ],
              responsive,
            ),

            // Profesores
            _buildUserCategory(
              '👨‍🏫 Profesores',
              [
                _buildTestUserButton('Juan Pérez', 'juan.perez@sanjose.edu', 'Prof123!', 'profesor', 'San José', responsive),
                _buildTestUserButton('María García', 'maria.garcia@sanjose.edu', 'Prof123!', 'profesor', 'San José', responsive),
                _buildTestUserButton('Carlos López', 'carlos.lopez@sanjose.edu', 'Prof123!', 'profesor', 'San José', responsive),
                _buildTestUserButton('Prof. Inactivo', 'profesor.inactivo@sanjose.edu', 'Prof123!', 'profesor', 'Inactivo', responsive),
                _buildTestUserButton('Sofía Ramírez', 'sofia.ramirez@santander.edu', 'Prof123!', 'profesor', 'Santander', responsive),
                _buildTestUserButton('Diego Morales', 'diego.morales@santander.edu', 'Prof123!', 'profesor', 'Santander', responsive),
              ],
              responsive,
            ),

            // Estudiantes
            _buildUserCategory(
              '👨‍🎓 Estudiantes',
              [
                _buildTestUserButton('Santiago Gómez', 'santiago.gomez@sanjose.edu', 'Est123!', 'estudiante', 'San José', responsive),
                _buildTestUserButton('Valeria Fernández', 'valeria.fernandez@sanjose.edu', 'Est123!', 'estudiante', 'San José', responsive),
                _buildTestUserButton('Mateo Silva', 'mateo.silva@sanjose.edu', 'Est123!', 'estudiante', 'San José', responsive),
                _buildTestUserButton('Isabella Ruiz', 'isabella.ruiz@sanjose.edu', 'Est123!', 'estudiante', 'San José', responsive),
                _buildTestUserButton('Lucas Moreno', 'lucas.moreno@sanjose.edu', 'Est123!', 'estudiante', 'San José', responsive),
                _buildTestUserButton('Mariana Jiménez', 'mariana.jimenez@sanjose.edu', 'Est123!', 'estudiante', 'San José', responsive),
                _buildTestUserButton('Daniel Herrera', 'daniel.herrera@sanjose.edu', 'Est123!', 'estudiante', 'San José', responsive),
                _buildTestUserButton('Gabriela Medina', 'gabriela.medina@sanjose.edu', 'Est123!', 'estudiante', 'San José', responsive),
                _buildTestUserButton('Alejandro Castro', 'alejandro.castro@sanjose.edu', 'Est123!', 'estudiante', 'San José', responsive),
                _buildTestUserButton('Est. Inactivo', 'estudiante.inactivo@sanjose.edu', 'Est123!', 'estudiante', 'Inactivo', responsive),
                _buildTestUserButton('Leonardo Ramos', 'leonardo.ramos@santander.edu', 'Est123!', 'estudiante', 'Santander', responsive),
                _buildTestUserButton('Sara Torres', 'sara.torres@santander.edu', 'Est123!', 'estudiante', 'Santander', responsive),
                _buildTestUserButton('Emiliano Flores', 'emiliano.flores@santander.edu', 'Est123!', 'estudiante', 'Santander', responsive),
                _buildTestUserButton('Valentina Rivera', 'valentina.rivera@santander.edu', 'Est123!', 'estudiante', 'Santander', responsive),
                _buildTestUserButton('Diego Gutiérrez', 'diego.gutierrez@santander.edu', 'Est123!', 'estudiante', 'Santander', responsive),
                _buildTestUserButton('Camila Sánchez', 'camila.sanchez@santander.edu', 'Est123!', 'estudiante', 'Santander', responsive),
                _buildTestUserButton('Sebastián Romero', 'sebastian.romero@santander.edu', 'Est123!', 'estudiante', 'Santander', responsive),
                _buildTestUserButton('Lucía Díaz', 'lucia.diaz@santander.edu', 'Est123!', 'estudiante', 'Santander', responsive),
              ],
              responsive,
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserCategory(String title, List<Widget> buttons, Map<String, dynamic> responsive) {
    return Builder(
      builder: (context) {
        final colors = context.colors;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: responsive['bodyFontSize'] as double,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.start,
              children: buttons,
            ),
            const SizedBox(height: 8),
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
      // Procesar la excepción para mostrar un mensaje humano legible
      String raw = e.toString();
      // Quitar el prefijo estándar "Exception: " si existe
      const exceptionPrefix = 'Exception: ';
      if (raw.startsWith(exceptionPrefix)) {
        raw = raw.substring(exceptionPrefix.length);
      }

      String messageToShow = raw;
      try {
        final parsed = jsonDecode(raw);
        if (parsed is Map<String, dynamic>) {
          messageToShow = parsed['message'] ?? parsed['error'] ?? (parsed['data'] is Map ? (parsed['data']['message'] ?? parsed['data']['error']) : null) ?? raw;
        }
      } catch (_) {
        // No JSON, mantener el texto crudo
      }

      setState(() {
        _errorMessage = messageToShow;
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