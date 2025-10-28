import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/theme_extensions.dart';
import '../utils/responsive_utils.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Widget _buildUserInfo(AuthProvider authProvider, TextStyle headlineMedium, Color primary, bool isSmallScreen) {
    final user = authProvider.user;
    final userName = user?['nombres'] ?? user?['email'] ?? 'Usuario';

    return Column(
      children: [
        Text(
          userName,
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
      return Builder(
        builder: (context) {
          final colors = context.colors;
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.warningBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.warningBorder),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.business,
                  color: colors.warning,
                  size: isSmallScreen ? 24 : 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'No hay institución seleccionada',
                  style: bodyLarge.copyWith(
                    color: colors.warning,
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
        },
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

  Widget _buildDashboardOptions(bool isSmallScreen, Color textPrimary, Color textSecondary) {
    return Builder(
      builder: (context) {
        final colors = context.colors;
        return Column(
          children: [
            const SizedBox(height: 32),
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
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                _buildFeatureCard(
                  icon: Icons.business,
                  title: 'Instituciones',
                  description: 'Gestionar instituciones educativas',
                  isSmallScreen: isSmallScreen,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                _buildFeatureCard(
                  icon: Icons.assignment,
                  title: 'Asistencia',
                  description: 'Registro y control de asistencia',
                  isSmallScreen: isSmallScreen,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
                _buildFeatureCard(
                  icon: Icons.bar_chart,
                  title: 'Reportes',
                  description: 'Estadísticas y reportes',
                  isSmallScreen: isSmallScreen,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.infoBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.infoBorder),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: colors.info,
                    size: isSmallScreen ? 24 : 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sistema en Desarrollo',
                    style: TextStyle(
                      color: colors.info,
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 16 : 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Las funcionalidades estarán disponibles próximamente.',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: isSmallScreen ? 12 : 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isSmallScreen,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Builder(
      builder: (context) {
        final colors = context.colors;
        return Container(
          width: isSmallScreen ? 160 : 180,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: colors.shadow,
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: colors.borderLight),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: isSmallScreen ? 32 : 40,
                color: colors.secondary,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 14 : 16,
                  color: textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: isSmallScreen ? 10 : 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _buildSignOutButton(AuthProvider authProvider) {
    return ElevatedButton(
      onPressed: () async {
        await authProvider.logout();
      },
      child: const Text('Cerrar Sesión'),
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

  Widget _buildBody(AuthProvider authProvider, dynamic textStyles, dynamic colors, Map<String, dynamic> responsive) {
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
                    _buildUserInfo(authProvider, textStyles.headlineMedium, colors.primary, responsive['isSmallScreen']),
                    SizedBox(height: responsive['elementSpacing']),

                    _buildInstitutionInfo(authProvider, textStyles.bodyLarge, colors.textMuted, responsive['isSmallScreen']),
                    SizedBox(height: responsive['elementSpacing']),

                    _buildDashboardOptions(responsive['isSmallScreen'], colors.textPrimary, colors.textSecondary),

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
          return _buildBody(authProvider, textStyles, colors, responsive);
        },
      ),
    );
  }
}