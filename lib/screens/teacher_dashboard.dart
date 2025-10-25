import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/theme_extensions.dart';
import '../theme/app_constants.dart';
import '../widgets/role_guard.dart';
import '../utils/role_enum.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  // Función para calcular variables responsive
  Map<String, dynamic> _getResponsiveValues(BoxConstraints constraints, double lg, double xxl, double xl, double sm, double md) {
    final isSmallScreen = constraints.maxWidth < 600;
    final horizontalPadding = isSmallScreen ? lg : xxl;
    final verticalPadding = isSmallScreen ? xl : xxl * 2;
    final titleSpacing = isSmallScreen ? sm : md;
    final cardSpacing = isSmallScreen ? lg : xl;

    return {
      'isSmallScreen': isSmallScreen,
      'horizontalPadding': horizontalPadding,
      'verticalPadding': verticalPadding,
      'titleSpacing': titleSpacing,
      'cardSpacing': cardSpacing,
    };
  }

  // Función para construir el saludo del usuario
  Widget _buildUserGreeting(String userName, AuthProvider authProvider, bool isSmallScreen) {
    final selectedInstitution = authProvider.selectedInstitution;
    
    return Column(
      children: [
        Text(
          'Hola, $userName',
          style: TextStyle(
            fontSize: isSmallScreen ? 28 : 38,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
          textAlign: TextAlign.center,
        ),
        if (selectedInstitution != null) ...[
          const SizedBox(height: 8),
          Text(
            selectedInstitution.name,
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  // Función para construir las opciones del dashboard
  Widget _buildDashboardOptions(bool isSmallScreen) {
    return Column(
      children: [
        const SizedBox(height: 32),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            _buildFeatureCard(
              icon: Icons.qr_code_scanner,
              title: 'Tomar Asistencia',
              description: 'Registrar asistencia con QR',
              color: Colors.green,
              isSmallScreen: isSmallScreen,
            ),
            _buildFeatureCard(
              icon: Icons.assignment,
              title: 'Mis Clases',
              description: 'Ver horarios y grupos asignados',
              color: Colors.blue,
              isSmallScreen: isSmallScreen,
            ),
            _buildFeatureCard(
              icon: Icons.people,
              title: 'Estudiantes',
              description: 'Lista de estudiantes por grupo',
              color: Colors.orange,
              isSmallScreen: isSmallScreen,
            ),
            _buildFeatureCard(
              icon: Icons.bar_chart,
              title: 'Reportes',
              description: 'Estadísticas de asistencia',
              color: Colors.purple,
              isSmallScreen: isSmallScreen,
            ),
            RoleGuard(
              allowedRoles: [UserRole.profesor],
              child: _buildFeatureCard(
                icon: Icons.notifications,
                title: 'Notificaciones',
                description: 'Enviar avisos a padres',
                color: Colors.teal,
                isSmallScreen: isSmallScreen,
              ),
            ),
            _buildFeatureCard(
              icon: Icons.calendar_today,
              title: 'Horario',
              description: 'Mi horario de clases',
              color: Colors.indigo,
              isSmallScreen: isSmallScreen,
            ),
          ],
        ),

      ],
    );
  }

  // Función para construir una tarjeta de funcionalidad
  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
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
            color: color,
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final colors = context.colors;
    final spacing = context.spacing;
    
    final user = authProvider.user;
    final userName = user?['nombres'] ?? 'Usuario';
    final userRole = 'Profesor';

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('AsistApp'),
        backgroundColor: colors.primary,
        actions: [
          // Badge de rol
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.school, size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  userRole,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final responsive = _getResponsiveValues(constraints, spacing.lg, spacing.xxl, spacing.xl, spacing.sm, spacing.md);
            final isSmallScreen = responsive['isSmallScreen'] as bool;
            final horizontalPadding = responsive['horizontalPadding'] as double;
            final verticalPadding = responsive['verticalPadding'] as double;
            final cardSpacing = responsive['cardSpacing'] as double;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: AppConstants.instance.maxScreenWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Saludo personalizado
                    _buildUserGreeting(userName, authProvider, isSmallScreen),
                    SizedBox(height: cardSpacing),

                    // Opciones del dashboard
                    _buildDashboardOptions(isSmallScreen),

                    // Espacio final
                    SizedBox(height: verticalPadding),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}