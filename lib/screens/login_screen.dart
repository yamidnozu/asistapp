import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/theme_extensions.dart';
import '../utils/responsive_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // En release los campos empiezan vacíos; en debug se pre-llenan para facilitar pruebas
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Los controladores se inicializan en didChangeDependencies para acceder a SettingsProvider
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final shouldPreloadSuperAdmin = settings.showTestUsers && !kReleaseMode;

    if (_emailController.text.isEmpty) {
      _emailController.text = shouldPreloadSuperAdmin
          ? 'superadmin@asistapp.com'
          : (kReleaseMode ? '' : 'superadmin@asistapp.com');
    }
    if (_passwordController.text.isEmpty) {
      _passwordController.text = shouldPreloadSuperAdmin
          ? 'Admin123!'
          : (kReleaseMode ? '' : 'Admin123!');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Construye el logo de AsistApp con un diseño atractivo
  Widget _buildLogo(Map<String, dynamic> responsive) {
    final isSmallScreen = responsive['isSmallScreen'] as bool;
    final logoSize = isSmallScreen ? 100.0 : 140.0;

    return Container(
      width: logoSize,
      height: logoSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/icon/logo.jpg',
          width: logoSize,
          height: logoSize,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback si no se puede cargar la imagen
            return Container(
              width: logoSize,
              height: logoSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
              ),
              child: Icon(
                Icons.school_rounded,
                size: logoSize * 0.5,
                color: Colors.white,
              ),
            );
          },
        ),
      ),
    );
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
            _buildUserCategory(
              '👑 Super Administradores',
              [
                _buildTestUserButton(
                    'Super Admin',
                    'superadmin@asistapp.com',
                    'Admin123!',
                    'super_admin',
                    'Gestión de instituciones y admins.',
                    responsive),
              ],
              responsive,
            ),
            _buildUserCategory(
              '👨‍💼 Administradores de Institución',
              [
                _buildTestUserButton(
                    'Admin San José',
                    'admin@sanjose.edu',
                    'SanJose123!',
                    'admin_institucion',
                    'Probar gestión académica (grupos, materias, horarios).',
                    responsive),
                _buildTestUserButton(
                    'Admin Santander',
                    'admin@santander.edu',
                    'Santander123!',
                    'admin_institucion',
                    'Probar en institución con menos datos.',
                    responsive),
                _buildTestUserButton(
                    'Admin Multi-Sede',
                    'multiadmin@asistapp.com',
                    'Multi123!',
                    'admin_institucion',
                    'Probar pantalla de selección de institución.',
                    responsive),
              ],
              responsive,
            ),
            _buildUserCategory(
              '👨‍🏫 Profesores',
              [
                _buildTestUserButton(
                    'Juan Pérez',
                    'juan.perez@sanjose.edu',
                    'Prof123!',
                    'profesor',
                    'San José - Tiene clases hoy para probar el dashboard.',
                    responsive),
                _buildTestUserButton(
                    'Laura Gómez',
                    'laura.gomez@sanjose.edu',
                    'Prof123!',
                    'profesor',
                    'San José - Tiene clases en diferentes grupos.',
                    responsive),
                _buildTestUserButton(
                    'Profe Sin Clases',
                    'vacio.profe@sanjose.edu',
                    'Prof123!',
                    'profesor',
                    'San José - Probar dashboard sin clases asignadas.',
                    responsive),
                _buildTestUserButton(
                    'Carlos Díaz',
                    'carlos.diaz@santander.edu',
                    'Prof123!',
                    'profesor',
                    'Santander - Probar dashboard en otra institución.',
                    responsive),
              ],
              responsive,
            ),
            _buildUserCategory(
              '👨‍🎓 Estudiantes',
              [
                _buildTestUserButton(
                    'Santiago Mendoza',
                    'santiago.mendoza@sanjose.edu',
                    'Est123!',
                    'estudiante',
                    'San José - Asignado al Grupo 10-A.',
                    responsive),
                _buildTestUserButton(
                    'Mateo Castro',
                    'mateo.castro@sanjose.edu',
                    'Est123!',
                    'estudiante',
                    'San José - Asignado al Grupo 11-B.',
                    responsive),
                _buildTestUserButton(
                    'Sofía Núñez',
                    'sofia.nunez@santander.edu',
                    'Est123!',
                    'estudiante',
                    'Santander - Asignada al Grupo 6-1.',
                    responsive),
              ],
              responsive,
            ),
            _buildUserCategory(
              '👨‍👩‍👧 Acudientes (Padres/Tutores)',
              [
                _buildTestUserButton(
                    'María Mendoza',
                    'maria.mendoza@email.com',
                    'Acu123!',
                    'acudiente',
                    'Madre de Santiago y Valentina (2 hijos). Tiene notificaciones.',
                    responsive),
                _buildTestUserButton(
                    'Patricia Castro',
                    'patricia.castro@email.com',
                    'Acu123!',
                    'acudiente',
                    'Madre de Mateo. Tiene notificaciones.',
                    responsive),
                _buildTestUserButton('Carmen López', 'carmen.lopez@email.com',
                    'Acu123!', 'acudiente', 'Madre de Andrés.', responsive),
                _buildTestUserButton(
                    'Carlos Núñez',
                    'carlos.nunez@email.com',
                    'Acu123!',
                    'acudiente',
                    'Padre de Sofía. Tiene notificación.',
                    responsive),
              ],
              responsive,
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserCategory(
      String title, List<Widget> buttons, Map<String, dynamic> responsive) {
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
          style: textStyles.bodyMedium
              .copyWith(color: colors.error), // Usar estilo del tema
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
                          _buildLogo(responsive),
                          SizedBox(height: responsive['elementSpacing']),

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

                          // Solo mostrar sección de usuarios de prueba cuando esté habilitado en settings
                          Consumer<SettingsProvider>(
                            builder: (context, settings, _) {
                              if (settings.showTestUsers) {
                                return _buildTestUsersSection(responsive);
                              }
                              return const SizedBox.shrink();
                            },
                          ),
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
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
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
        context, // Pasamos el BuildContext actual
      );

      if (success) {
        print('Login exitoso, AuthWrapper manejará la navegación');
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
          messageToShow = parsed['message'] ??
              parsed['error'] ??
              (parsed['data'] is Map
                  ? (parsed['data']['message'] ?? parsed['data']['error'])
                  : null) ??
              raw;
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
