import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/theme_extensions.dart';
import '../theme/app_constants.dart';
import '../ui/widgets/index.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedInstitutionId;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInstitutions();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadInstitutions() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.loadInstitutions();
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

  // Función para construir el selector de institución
  Widget _buildInstitutionSelector() {
    final authProvider = Provider.of<AuthProvider>(context);
    final institutions = authProvider.institutions;

    return DropdownButtonFormField<String>(
      value: _selectedInstitutionId,
      decoration: const InputDecoration(
        labelText: 'Seleccionar Institución',
        border: OutlineInputBorder(),
      ),
      items: institutions?.map((institution) {
        return DropdownMenuItem<String>(
          value: institution['id'].toString(),
          child: Text(institution['name'] ?? 'Sin nombre'),
        );
      }).toList() ?? [],
      onChanged: (value) {
        setState(() {
          _selectedInstitutionId = value;
        });
      },
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
    return AppButton(
      label: _isLoading ? 'Iniciando sesión...' : 'Iniciar Sesión',
      onPressed: _isLoading ? () {} : _login,
      isLoading: _isLoading,
      isEnabled: !_isLoading && _selectedInstitutionId != null,
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

                      // Selector de institución
                      _buildInstitutionSelector(),
                      SizedBox(height: spacing.lg),

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
    if (_selectedInstitutionId == null ||
        _emailController.text.isEmpty ||
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
        _selectedInstitutionId!,
      );

      if (success) {
        // Login exitoso - navegar a la pantalla principal
        // TODO: Implementar navegación
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