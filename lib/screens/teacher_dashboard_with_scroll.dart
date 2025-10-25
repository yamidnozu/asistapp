import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/theme_extensions.dart';
import '../theme/app_constants.dart';
import '../widgets/scroll_state_keeper.dart';
import '../utils/app_routes.dart';

/// Ejemplo de Dashboard con persistencia de scroll
class TeacherDashboardWithScroll extends StatelessWidget {
  const TeacherDashboardWithScroll({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final textStyles = context.textStyles;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Profesor - AsistApp'),
        backgroundColor: colors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ScrollStateKeeper(
          routeKey: AppRoutes.teacherDashboard,
          keepScrollPosition: true,
          builder: (context, scrollController) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 600;
                final horizontalPadding = isSmallScreen ? spacing.lg : spacing.xxl;
                final verticalPadding = isSmallScreen ? spacing.xl : spacing.xxl * 2;

                return SingleChildScrollView(
                  controller: scrollController, // ← El scroll se guarda automáticamente
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: AppConstants.instance.maxScreenWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Contenido del dashboard
                        Text(
                          'Panel del Profesor',
                          style: textStyles.displayLarge.copyWith(
                            fontSize: isSmallScreen ? 28 : 42,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        
                        // Agregar mucho contenido para demostrar el scroll
                        ...List.generate(20, (index) => Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: CircleAvatar(child: Text('${index + 1}')),
                            title: Text('Clase ${index + 1}'),
                            subtitle: Text('Grupo ${index % 5 + 1}'),
                            trailing: const Icon(Icons.arrow_forward_ios),
                          ),
                        )),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
