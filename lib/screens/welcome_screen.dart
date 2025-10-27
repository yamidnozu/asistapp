import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/theme_extensions.dart';
import '../theme/app_constants.dart';
import '../ui/widgets/index.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  Map<String, dynamic> _getResponsiveValues(BoxConstraints constraints, double lg, double xxl, double xl, double sm, double md) {
    final isSmallScreen = constraints.maxWidth < 600;
    final horizontalPadding = isSmallScreen ? lg : xxl;
    final verticalPadding = isSmallScreen ? xl : xxl * 2;
    final titleSpacing = isSmallScreen ? sm : md;
    final cardSpacing = isSmallScreen ? lg : xl; // Mantener consistente

    return {
      'isSmallScreen': isSmallScreen,
      'horizontalPadding': horizontalPadding,
      'verticalPadding': verticalPadding,
      'titleSpacing': titleSpacing,
      'cardSpacing': cardSpacing,
    };
  }
  Widget _buildWelcomeTitle(TextStyle displayLarge, bool isSmallScreen) {
    return Text(
      '¡Bienvenido!',
      style: displayLarge.copyWith(
        fontSize: isSmallScreen ? 32 : 48,
      ),
      textAlign: TextAlign.center,
    );
  }
  Widget _buildUserName(AuthProvider authProvider, TextStyle headlineMedium, Color primary, bool isSmallScreen) {
    final user = authProvider.user;
    final userName = user?['name'] ?? user?['email'] ?? 'Usuario';

    return Text(
      userName,
      style: headlineMedium.copyWith(
        color: primary,
        fontSize: isSmallScreen ? 18 : 24,
      ),
      textAlign: TextAlign.center,
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
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
            final cardSpacing = responsive['cardSpacing'] as double;

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: AppConstants.instance.maxScreenWidth),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildWelcomeTitle(textStyles.displayLarge, isSmallScreen),
                      SizedBox(height: titleSpacing),
                      _buildUserName(authProvider, textStyles.headlineMedium, colors.primary, isSmallScreen),
                      SizedBox(height: cardSpacing),
                      const Text(
                        'Has iniciado sesión correctamente',
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: cardSpacing),
                      _buildSignOutButton(authProvider),
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
}