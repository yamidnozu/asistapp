import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/theme_extensions.dart';
import '../widgets/scroll_state_keeper.dart';
import '../utils/app_routes.dart';
import '../utils/responsive_utils.dart';

/// Ejemplo de Dashboard con persistencia de scroll
class TeacherDashboardWithScroll extends StatelessWidget {
  const TeacherDashboardWithScroll({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final colors = context.colors;
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
              await authProvider.logoutAndClearAllData(context);
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
                final responsive = ResponsiveUtils.getResponsiveValues(constraints);

                return SingleChildScrollView(
                  controller: scrollController, // ← El scroll se guarda automáticamente
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: responsive['maxWidth'],
                    ),
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
                              Text(
                                'Panel del Profesor',
                                style: textStyles.displayLarge.copyWith(
                                  fontSize: responsive['isSmallScreen'] ? 28 : 42,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),

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
