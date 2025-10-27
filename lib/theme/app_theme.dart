import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// Theme principal de la aplicación - escalable y mantenible
class AppTheme {
  AppTheme._();
  static final AppTheme instance = AppTheme._();

  /// Theme claro (si se necesita en el futuro)
  static ThemeData get light => _createTheme(Brightness.light);

  /// Theme oscuro (principal)
  static ThemeData get dark => _createTheme(Brightness.dark);

  /// Theme por defecto (oscuro)
  static ThemeData get defaultTheme => dark;

  static ThemeData _createTheme(Brightness brightness) {
    final colors = AppColors.instance;
    final textStyles = AppTextStyles.instance;

    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.primary,
        onPrimary: colors.textPrimary,
        primaryContainer: colors.primaryContainer,
        onPrimaryContainer: colors.textPrimary,
        secondary: colors.secondary,
        onSecondary: colors.textPrimary,
        secondaryContainer: colors.secondaryContainer,
        onSecondaryContainer: colors.textSecondary,
        tertiary: colors.info,
        onTertiary: colors.textPrimary,
        error: colors.error,
        onError: colors.textPrimary,
        surface: colors.surface,
        onSurface: colors.textPrimary,
        surfaceContainerHighest: colors.surfaceLight,
        onSurfaceVariant: colors.textMuted,
        outline: colors.border,
        outlineVariant: colors.borderLight,
        shadow: colors.black.withValues(alpha: 0.1), // Sombra ligera 10%
        scrim: colors.scrim,
        inverseSurface: colors.surfaceLight,
        onInverseSurface: colors.textPrimary,
        inversePrimary: colors.primaryLight,
        surfaceTint: colors.primary.withValues(alpha: 0.1),
      ),
      textTheme: TextTheme(
        displayLarge: textStyles.displayLarge,
        displayMedium: textStyles.displayMedium,
        headlineLarge: textStyles.headlineLarge,
        headlineMedium: textStyles.headlineMedium,
        titleLarge: textStyles.titleLarge,
        titleMedium: textStyles.titleMedium,
        bodyLarge: textStyles.bodyLarge,
        bodyMedium: textStyles.bodyMedium,
        bodySmall: textStyles.bodySmall,
        labelLarge: textStyles.labelLarge,
        labelMedium: textStyles.labelMedium,
        labelSmall: textStyles.labelSmall,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.white,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textStyles.headlineMedium.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        toolbarHeight: AppSpacing.instance.appBarHeight,
        centerTitle: true,
      ),
      cardTheme: CardTheme(
        color: colors.white,
        shadowColor: colors.shadowLight,
        elevation: 1, // Elevación sutil
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.instance.borderRadius),
          side: BorderSide(color: colors.border, width: 0.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.white,
          elevation: 1, // Elevación sutil
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.instance.buttonPadding,
            vertical: AppSpacing.instance.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.instance.borderRadius),
          ),
          textStyle: textStyles.button,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.border, width: AppSpacing.instance.borderWidth),
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.instance.buttonPadding,
            vertical: AppSpacing.instance.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.instance.borderRadius),
          ),
          textStyle: textStyles.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.instance.sm,
            vertical: AppSpacing.instance.xs,
          ),
          textStyle: textStyles.labelMedium,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.instance.borderRadius),
          borderSide: BorderSide(color: colors.border, width: AppSpacing.instance.borderWidth),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.instance.borderRadius),
          borderSide: BorderSide(color: colors.border, width: AppSpacing.instance.borderWidth),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.instance.borderRadius),
          borderSide: BorderSide(color: colors.primaryLight, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.instance.borderRadius),
          borderSide: BorderSide(color: colors.error, width: AppSpacing.instance.borderWidth),
        ),
        contentPadding: EdgeInsets.all(AppSpacing.instance.inputPadding),
        labelStyle: textStyles.bodyMedium.copyWith(color: colors.textMuted),
        hintStyle: textStyles.bodyMedium.copyWith(color: colors.textMuted),
        errorStyle: textStyles.bodySmall.copyWith(color: colors.error),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: colors.white,
        elevation: 6, // Elevación media para diálogos
        shadowColor: colors.shadowLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.instance.borderRadius),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: colors.white,
        elevation: 2, // Elevación sutil
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.instance.borderRadiusLarge),
        ),
      ),
      scaffoldBackgroundColor: colors.background,
      dividerColor: colors.divider,
      shadowColor: colors.shadow,
      typography: Typography.material2021(),
    );
  }
}
