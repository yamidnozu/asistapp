import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../theme/theme_extensions.dart';
import '../theme/app_constants.dart';
import '../ui/widgets/index.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  // Función para calcular variables responsive
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

  // Función para construir el título de bienvenida
  Widget _buildWelcomeTitle(TextStyle displayLarge, bool isSmallScreen) {
    return Text(
      '¡Bienvenido!',
      style: displayLarge.copyWith(
        fontSize: isSmallScreen ? 32 : 48,
      ),
      textAlign: TextAlign.center,
    );
  }

  // Función para construir el nombre del usuario
  Widget _buildUserName(UserProvider userProvider, TextStyle headlineMedium, Color primary, bool isSmallScreen) {
    return Text(
      userProvider.currentUser?.displayName ??
      userProvider.currentUser?.email ??
      'Usuario',
      style: headlineMedium.copyWith(
        color: primary,
        fontSize: isSmallScreen ? 18 : 24,
      ),
      textAlign: TextAlign.center,
    );
  }



  // Función para construir el botón de cerrar sesión
  Widget _buildSignOutButton(UserProvider userProvider) {
    return AppButton(
      label: 'Cerrar Sesión',
      onPressed: () async {
        await userProvider.signOut();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
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
                      // Título de bienvenida
                      _buildWelcomeTitle(textStyles.displayLarge, isSmallScreen),
                      SizedBox(height: titleSpacing),

                      // Nombre del usuario
                      _buildUserName(userProvider, textStyles.headlineMedium, colors.primary, isSmallScreen),
                      SizedBox(height: cardSpacing),

                      // Mensaje de éxito
                    

                      // Botón de cerrar sesión
                      _buildSignOutButton(userProvider),
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