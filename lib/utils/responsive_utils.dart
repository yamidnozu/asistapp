import 'package:flutter/material.dart';
import '../theme/app_constants.dart';

/// Utilidades para diseño responsive
class ResponsiveUtils {
  static final AppConstants _constants = AppConstants.instance;

  /// Obtiene valores responsive basados en el tipo de pantalla
  static Map<String, dynamic> getResponsiveValues(BoxConstraints constraints) {
    final screenType = _constants.getScreenType(constraints.maxWidth);
    final maxWidth = _constants.getMaxWidth(constraints.maxWidth);

    // Paddings horizontales
    final horizontalPadding = switch (screenType) {
      ScreenType.mobileSmall => 16.0,
      ScreenType.mobileLarge => 24.0,
      ScreenType.tablet => 32.0,
      ScreenType.desktop => 48.0,
      ScreenType.largeDesktop => 64.0,
    };

    // Paddings verticales
    final verticalPadding = switch (screenType) {
      ScreenType.mobileSmall => 24.0,
      ScreenType.mobileLarge => 32.0,
      ScreenType.tablet => 48.0,
      ScreenType.desktop => 64.0,
      ScreenType.largeDesktop => 80.0,
    };

    // Espaciados entre elementos
    final elementSpacing = switch (screenType) {
      ScreenType.mobileSmall => 16.0,
      ScreenType.mobileLarge => 20.0,
      ScreenType.tablet => 24.0,
      ScreenType.desktop => 32.0,
      ScreenType.largeDesktop => 40.0,
    };

    // Tamaños de fuente base
    final titleFontSize = switch (screenType) {
      ScreenType.mobileSmall => 24.0,
      ScreenType.mobileLarge => 28.0,
      ScreenType.tablet => 32.0,
      ScreenType.desktop => 40.0,
      ScreenType.largeDesktop => 48.0,
    };

    final subtitleFontSize = switch (screenType) {
      ScreenType.mobileSmall => 14.0,
      ScreenType.mobileLarge => 16.0,
      ScreenType.tablet => 18.0,
      ScreenType.desktop => 20.0,
      ScreenType.largeDesktop => 24.0,
    };

    final bodyFontSize = switch (screenType) {
      ScreenType.mobileSmall => 14.0,
      ScreenType.mobileLarge => 16.0,
      ScreenType.tablet => 16.0,
      ScreenType.desktop => 18.0,
      ScreenType.largeDesktop => 20.0,
    };

    // Anchos de botones
    final buttonWidth = switch (screenType) {
      ScreenType.mobileSmall => double.infinity,
      ScreenType.mobileLarge => 280.0,
      ScreenType.tablet => 320.0,
      ScreenType.desktop => 360.0,
      ScreenType.largeDesktop => 400.0,
    };

    // Alturas mínimas para mantener proporciones
    final minHeight = switch (screenType) {
      ScreenType.mobileSmall => 600.0,
      ScreenType.mobileLarge => 700.0,
      ScreenType.tablet => 800.0,
      ScreenType.desktop => 900.0,
      ScreenType.largeDesktop => 1000.0,
    };

    return {
      'screenType': screenType,
      'maxWidth': maxWidth,
      'horizontalPadding': horizontalPadding,
      'verticalPadding': verticalPadding,
      'elementSpacing': elementSpacing,
      'titleFontSize': titleFontSize,
      'subtitleFontSize': subtitleFontSize,
      'bodyFontSize': bodyFontSize,
      'buttonWidth': buttonWidth,
      'minHeight': minHeight,
      'isSmallScreen': screenType == ScreenType.mobileSmall,
      'isMobile': screenType == ScreenType.mobileSmall || screenType == ScreenType.mobileLarge,
      'isTablet': screenType == ScreenType.tablet,
      'isDesktop': screenType == ScreenType.desktop || screenType == ScreenType.largeDesktop,
      'isLargeDesktop': screenType == ScreenType.largeDesktop,
    };
  }

  /// Crea un contenedor responsive con padding y ancho máximo
  static Widget buildResponsiveContainer({
    required BuildContext context,
    required Widget child,
    double? maxWidth,
    EdgeInsets? padding,
    bool centerContent = true,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final responsive = getResponsiveValues(constraints);
        final containerMaxWidth = maxWidth ?? responsive['maxWidth'];
        final containerPadding = padding ?? EdgeInsets.symmetric(
          horizontal: responsive['horizontalPadding'],
          vertical: responsive['verticalPadding'],
        );

        final content = ConstrainedBox(
          constraints: BoxConstraints(maxWidth: containerMaxWidth),
          child: child,
        );

        return Container(
          width: double.infinity,
          padding: containerPadding,
          constraints: BoxConstraints(minHeight: responsive['minHeight']),
          child: centerContent ? Center(child: content) : content,
        );
      },
    );
  }

  /// Crea un texto responsive
  static TextStyle getResponsiveTextStyle(
    TextStyle baseStyle,
    ScreenType screenType, {
    double? fontSize,
  }) {
    final scaleFactor = switch (screenType) {
      ScreenType.mobileSmall => 0.8,
      ScreenType.mobileLarge => 0.9,
      ScreenType.tablet => 1.0,
      ScreenType.desktop => 1.1,
      ScreenType.largeDesktop => 1.2,
    };

    final scaledFontSize = fontSize ?? (baseStyle.fontSize ?? 14.0) * scaleFactor;

    return baseStyle.copyWith(fontSize: scaledFontSize);
  }

  /// Crea un grid responsive para cards
  static SliverGridDelegate getResponsiveGridDelegate(ScreenType screenType) {
    return switch (screenType) {
      ScreenType.mobileSmall => const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
      ScreenType.mobileLarge => const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
      ScreenType.tablet => const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 1.0,
        ),
      ScreenType.desktop => const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          childAspectRatio: 0.9,
        ),
      ScreenType.largeDesktop => const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 28,
          mainAxisSpacing: 28,
          childAspectRatio: 0.8,
        ),
    };
  }
}