import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/theme_extensions.dart';
import '../ui/widgets/app_button.dart';
import '../utils/responsive_utils.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Widget _buildDashboardTitle(TextStyle displayLarge, bool isSmallScreen) {
    return Text(
      'Dashboard',
      style: displayLarge.copyWith(
        fontSize: isSmallScreen ? 32 : 48,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildUserInfo(AuthProvider authProvider, TextStyle headlineMedium, Color primary, bool isSmallScreen) {
    final user = authProvider.user;
    final userName = user?['nombres'] ?? user?['email'] ?? 'Usuario';

    return Column(
      children: [
        Text(
          'Bienvenido, $userName',
          style: headlineMedium.copyWith(
            color: primary,
            fontSize: isSmallScreen ? 18 : 24,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Rol: ${user?['rol'] ?? 'Sin rol'}',
          style: TextStyle(
            color: primary.withValues(alpha: 0.7),
            fontSize: isSmallScreen ? 14 : 16,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInstitutionInfo(AuthProvider authProvider, TextStyle bodyLarge, Color textMuted, bool isSmallScreen) {
    final selectedInstitution = authProvider.selectedInstitution;

    if (selectedInstitution == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.business,
              color: Colors.orange,
              size: isSmallScreen ? 24 : 32,
            ),
            const SizedBox(height: 8),
            Text(
              'No hay institución seleccionada',
              style: bodyLarge.copyWith(
                color: Colors.orange,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Como super administrador, puedes gestionar todas las instituciones del sistema.',
              style: TextStyle(
                color: textMuted,
                fontSize: isSmallScreen ? 12 : 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Text(
          'Institución: ${selectedInstitution.name}',
          style: bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 16 : 18,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'Rol en institución: ${selectedInstitution.role ?? 'Sin rol'}',
          style: TextStyle(
            color: textMuted,
            fontSize: isSmallScreen ? 14 : 16,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDashboardOptions(bool isSmallScreen) {
    return Column(
      children: [
        const SizedBox(height: 32),
        Text(
          'Funcionalidades del Sistema',
          style: TextStyle(
            fontSize: isSmallScreen ? 18 : 22,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            _buildFeatureCard(
              icon: Icons.people,
              title: 'Gestión de Usuarios',
              description: 'Administrar usuarios del sistema',
              isSmallScreen: isSmallScreen,
            ),
            _buildFeatureCard(
              icon: Icons.business,
              title: 'Instituciones',
              description: 'Gestionar instituciones educativas',
              isSmallScreen: isSmallScreen,
            ),
            _buildFeatureCard(
              icon: Icons.assignment,
              title: 'Asistencia',
              description: 'Registro y control de asistencia',
              isSmallScreen: isSmallScreen,
            ),
            _buildFeatureCard(
              icon: Icons.bar_chart,
              title: 'Reportes',
              description: 'Estadísticas y reportes',
              isSmallScreen: isSmallScreen,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue,
                size: isSmallScreen ? 24 : 32,
              ),
              const SizedBox(height: 8),
              Text(
                'Sistema en Desarrollo',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 16 : 18,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Las funcionalidades estarán disponibles próximamente.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: isSmallScreen ? 12 : 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isSmallScreen,
  }) {
    return Container(
      width: isSmallScreen ? 160 : 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: isSmallScreen ? 32 : 40,
            color: Colors.grey[700],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 14 : 16,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: isSmallScreen ? 10 : 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }


  Widget _buildSignOutButton(AuthProvider authProvider) {
    return AppButton(
      label: 'Cerrar Sesión',
      onPressed: () async {
        await authProvider.logout();
      },
    );
  }

  AppBar _buildAppBar(Color primaryColor) {
    return AppBar(
      title: const Text('AsistApp'),
      backgroundColor: primaryColor,
      actions: _buildAppBarActions(),
    );
  }

  List<Widget> _buildAppBarActions() {
    return [
      IconButton(
        icon: const Icon(Icons.logout),
        onPressed: () async {
          // TODO: Implement logout
        },
      ),
    ];
  }

  Widget _buildBody(AuthProvider authProvider, dynamic textStyles, Color primaryColor, Color textMuted, Map<String, dynamic> responsive) {
    return SafeArea(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: responsive['maxWidth']),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive['horizontalPadding'],
                  vertical: responsive['verticalPadding'],
                ),
                child: Column(
                  children: [
                    _buildDashboardTitle(textStyles.displayLarge, responsive['isSmallScreen']),
                    SizedBox(height: responsive['elementSpacing']),

                    _buildUserInfo(authProvider, textStyles.headlineMedium, primaryColor, responsive['isSmallScreen']),
                    SizedBox(height: responsive['elementSpacing']),

                    _buildInstitutionInfo(authProvider, textStyles.bodyLarge, textMuted, responsive['isSmallScreen']),
                    SizedBox(height: responsive['elementSpacing']),

                    _buildDashboardOptions(responsive['isSmallScreen']),

                    SizedBox(height: responsive['elementSpacing'] * 2),

                    _buildSignOutButton(authProvider),

                    SizedBox(height: responsive['verticalPadding']),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final colors = context.colors;
    final textStyles = context.textStyles;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: _buildAppBar(colors.primary),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final responsive = ResponsiveUtils.getResponsiveValues(constraints);
          return _buildBody(authProvider, textStyles, colors.primary, colors.textMuted, responsive);
        },
      ),
    );
  }
}