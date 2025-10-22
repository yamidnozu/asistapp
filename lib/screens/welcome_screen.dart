import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../theme/theme_extensions.dart';
import '../theme/app_constants.dart';
import '../ui/widgets/index.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final colors = context.colors;
    final spacing = context.spacing;
    final textStyles = context.textStyles;

    return Container(
      color: colors.background,
      child: SafeArea(
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: AppConstants.instance.maxScreenWidth),
            padding: EdgeInsets.all(spacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo o ícono
                Container(
                  width: AppConstants.instance.logoSize,
                  height: AppConstants.instance.logoSize,
                  decoration: BoxDecoration(
                    color: colors.success,
                    borderRadius: BorderRadius.circular(AppConstants.instance.logoBorderRadius),
                  ),
                  child: Center(
                    child: Text(
                      '✓',
                      style: TextStyle(
                        fontSize: AppConstants.instance.logoFontSize,
                        color: colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: spacing.xl),
                Text(
                  '¡Bienvenido!',
                  style: textStyles.displayLarge,
                ),
                SizedBox(height: spacing.sm),
                Text(
                  userProvider.currentUser?.displayName ??
                  userProvider.currentUser?.email ??
                  'Usuario',
                  style: textStyles.headlineMedium.copyWith(
                    color: colors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: spacing.xl),
                Container(
                  padding: EdgeInsets.all(spacing.md),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(AppConstants.instance.cardBorderRadius),
                    border: Border.all(
                      color: colors.border,
                      width: AppConstants.instance.borderWidthThin,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadowLight,
                        blurRadius: AppConstants.instance.shadowBlurRadius,
                        offset: Offset(0, AppConstants.instance.shadowOffsetY),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Has iniciado sesión correctamente',
                        style: textStyles.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: spacing.md),
                      Text(
                        'Estado: ${userProvider.currentUser != null ? 'Conectado' : 'Desconectado'}',
                        style: textStyles.bodyMedium.copyWith(
                          color: userProvider.currentUser != null
                              ? colors.success
                              : colors.error,
                        ),
                      ),
                      SizedBox(height: spacing.xl),
                      AppButton(
                        label: 'Cerrar Sesión',
                        onPressed: () async {
                          await userProvider.signOut();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}