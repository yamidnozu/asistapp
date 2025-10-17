import 'package:flutter/widgets.dart';

/// Tema tipográfico consistente para tema oscuro
class AppTextStyles {
  // Display
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.2,
    color: Color(0xFFEDEDED),
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.25,
    color: Color(0xFFEDEDED),
  );

  // Headline
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: Color(0xFFEDEDED),
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: Color(0xFFEDEDED),
  );

  // Title
  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: Color(0xFFEDEDED),
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: Color(0xFFEDEDED),
  );

  // Body
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: Color(0xFFCCCCCC),
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.43,
    color: Color(0xFFCCCCCC),
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.33,
    color: Color(0xFF9E9E9E),
  );

  // Label
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.43,
    color: Color(0xFFEDEDED),
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.33,
    color: Color(0xFFCCCCCC),
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.45,
    color: Color(0xFF9E9E9E),
  );
}

/// Colores consistentes para tema oscuro
class AppColors {
  // Primarios
  static const Color primary = Color(0xFF35A0FF);
  static const Color primaryDark = Color(0xFF1E7FCC);
  static const Color primaryLight = Color(0xFF5BB3FF);

  // Secundarios
  static const Color secondary = Color(0xFF757575);
  static const Color secondaryLight = Color(0xFF9E9E9E);

  // Estados
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Superficies oscuras
  static const Color surface = Color(0xFF151515);
  static const Color surfaceLight = Color(0xFF1E1E1E);
  static const Color background = Color(0xFF0B0B0B);
  static const Color backgroundLight = Color(0xFF151515);

  // Texto
  static const Color textPrimary = Color(0xFFEDEDED);
  static const Color textSecondary = Color(0xFFCCCCCC);
  static const Color textMuted = Color(0xFF9E9E9E);

  // Bordes y separadores
  static const Color border = Color(0xFF2A2A2A);
  static const Color borderLight = Color(0xFF3A3A3A);

  // Neutros (para compatibilidad)
  static const Color white = Color(0xFFEDEDED);
  static const Color black = Color(0xFF0B0B0B);
  static const Color grey = Color(0xFF2A2A2A);
  static const Color greyDark = Color(0xFF1E1E1E);
}

/// Espacios consistentes
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}
