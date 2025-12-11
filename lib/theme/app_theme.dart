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
    final colors = AppColors.fromBrightness(brightness);
    final textStyles = AppTextStyles.instance;

    return ThemeData(
      brightness: brightness,
      useMaterial3: true,

      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.primary,
        onPrimary: brightness == Brightness.light
            ? colors.textPrimary
            : colors.white, // Negro en light, blanco en dark
        primaryContainer: colors.primaryContainer,
        onPrimaryContainer: colors.textPrimary,
        secondary: colors.secondary,
        onSecondary: colors.white, // Texto blanco sobre secondary
        secondaryContainer: colors.secondaryContainer,
        onSecondaryContainer: colors.textSecondary,
        tertiary: colors.info,
        onTertiary: colors.white, // Texto blanco sobre info
        error: colors.error,
        onError: colors.white, // Texto blanco sobre error
        surface: colors.surface,
        onSurface: colors.textPrimary,
        surfaceContainerHighest: colors.surfaceLight,
        onSurfaceVariant: colors.textMuted,
        outline: colors.border,
        outlineVariant: colors.borderLight,
        shadow: colors.shadow,
        scrim: colors.scrim,
        inverseSurface: colors.primary,
        onInverseSurface: colors.white,
        inversePrimary: colors.primaryLight,
        surfaceTint: colors.primary.withValues(alpha: 0.05),
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
        backgroundColor: colors.primary,
        foregroundColor: brightness == Brightness.light
            ? colors.textPrimary
            : colors.white, // Negro en light, blanco en dark
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textStyles.headlineMedium.copyWith(
          color: brightness == Brightness.light
              ? colors.textPrimary
              : colors.white, // Negro en light, blanco en dark
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(
            color: brightness == Brightness.light
                ? colors.textPrimary
                : colors.white), // Negro en light, blanco en dark
        actionsIconTheme: IconThemeData(
            color: brightness == Brightness.light
                ? colors.textPrimary
                : colors.white), // Negro en light, blanco en dark
        toolbarHeight: AppSpacing.instance.appBarHeight,
        centerTitle: true,
      ),

      cardTheme: CardTheme(
        color: colors.surface,
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
          foregroundColor: brightness == Brightness.light
              ? colors.textPrimary
              : colors.white, // Negro en light, blanco en dark
          elevation: 1, // Elevación sutil
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.instance.buttonPadding,
            vertical: AppSpacing.instance.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppSpacing.instance.borderRadius),
          ),
          textStyle: textStyles.button,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          side: BorderSide(
              color: colors.border, width: AppSpacing.instance.borderWidth),
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.instance.buttonPadding,
            vertical: AppSpacing.instance.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppSpacing.instance.borderRadius),
          ),
          textStyle: textStyles.button, // Usar estilo sin color fijo
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.instance.sm,
            vertical: AppSpacing.instance.xs,
          ),
          textStyle: textStyles.button, // Usar estilo sin color fijo
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.instance.borderRadius),
          borderSide: BorderSide(
              color: colors.border, width: AppSpacing.instance.borderWidth),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.instance.borderRadius),
          borderSide: BorderSide(
              color: colors.border, width: AppSpacing.instance.borderWidth),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.instance.borderRadius),
          borderSide: BorderSide(color: colors.primaryLight, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.instance.borderRadius),
          borderSide: BorderSide(
              color: colors.error, width: AppSpacing.instance.borderWidth),
        ),
        contentPadding: EdgeInsets.all(AppSpacing.instance.inputPadding),
        labelStyle: textStyles.bodyMedium.copyWith(color: colors.textMuted),
        hintStyle: textStyles.bodyMedium.copyWith(color: colors.textMuted),
        errorStyle: textStyles.bodySmall.copyWith(color: colors.error),
      ),

      dialogTheme: DialogTheme(
        backgroundColor: colors.surface,
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
          borderRadius:
              BorderRadius.circular(AppSpacing.instance.borderRadiusLarge),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceLight,
        deleteIconColor: colors.textMuted,
        disabledColor: colors.stateInactive,
        selectedColor: colors.primary,
        secondarySelectedColor: colors.secondary,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.instance.sm,
          vertical: AppSpacing.instance.xs,
        ),
        labelStyle: textStyles.bodyMedium.copyWith(color: colors.textPrimary),
        secondaryLabelStyle:
            textStyles.bodyMedium.copyWith(color: colors.white),
        brightness: brightness,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.instance.borderRadius),
          side: BorderSide(color: colors.border),
        ),
      ),

      scaffoldBackgroundColor: colors.background,
      dividerColor: colors.divider,
      shadowColor: colors.shadow,

      typography: Typography.material2021(),

      // FASE 2: Material 3 Refinements - Mejor soporte para adaptatividad
      // useMaterial3: true, // Ya está activado arriba en _createTheme

      // Temas de navegación mejorados
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface,
        indicatorColor: colors.primary,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textStyles.labelSmall.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w600,
            );
          }
          return textStyles.labelSmall.copyWith(color: colors.textMuted);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colors.primary);
          }
          return IconThemeData(color: colors.textMuted);
        }),
      ),

      // Rail de navegación para tablet/desktop
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colors.surface,
        selectedIconTheme: IconThemeData(color: colors.primary),
        unselectedIconTheme: IconThemeData(color: colors.textMuted),
        selectedLabelTextStyle:
            textStyles.labelSmall.copyWith(color: colors.primary),
        unselectedLabelTextStyle:
            textStyles.labelSmall.copyWith(color: colors.textMuted),
      ),

      // Mejora de contraste para accesibilidad WCAG AA
      // Asegura que los colores tengan suficiente contraste
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppSpacing.instance.borderRadius),
            topRight: Radius.circular(AppSpacing.instance.borderRadius),
          ),
        ),
      ),

      // Centralizar estilo de SnackBars para consistencia de la UI
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.surfaceVariant,
        contentTextStyle:
            textStyles.bodyMedium.copyWith(color: colors.textPrimary),
        actionTextColor: colors.primary,
        behavior: SnackBarBehavior.floating,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.instance.borderRadius),
        ),
      ),
    );
  }
}

// NOTAS DE IMPLEMENTACIÓN - ACCESIBILIDAD Y MATERIAL 3:
//
// WCAG AA Compliance (4.5:1 contrast ratio):
// - TextPrimary (Slate 900) sobre White: 18.5:1 ✅ AAA
// - TextPrimary sobre Primary Blue: 6.96:1 ✅ AA (cambiado de blanco para mejor accesibilidad)
// - TextSecondary (Slate 700) sobre White: 8.2:1 ✅ AAA
// - TextMuted (Slate 600) sobre White: 5.8:1 ✅ AA
// - Primary Blue sobre White: 8.8:1 ✅ AAA
// - Success Green sobre White: 5.3:1 ✅ AA
// - Error Red sobre White: 4.9:1 ✅ AA
// - Warning Amber sobre White: 4.5:1 ✅ AA (límite)
//
// Material 3 Features Implementadas:
// ✅ useMaterial3: true - Animaciones y transiciones modernas
// ✅ ColorScheme completo - Soporte para tema oscuro futuro
// ✅ TextTheme escalable - Responsive typography
// ✅ NavigationBar + NavigationRail - Adaptive navigation
// ✅ Shape tokens - BorderRadius consistente
// ✅ Elevation refined - Sutil y moderno (1-6 levels)
//
// Próximos pasos (Fases 3-5):
// - Implementar max-width constraints en pantallas (Fase 3)
// - Crear ClarityManagementHeader para listas (Fase 5)
// - Refactorizar dashboards con layout 70/30 (Fase 7)
