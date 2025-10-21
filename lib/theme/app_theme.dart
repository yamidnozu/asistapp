import 'package:flutter/widgets.dart';

/// Tema tipográfico consistente para tema oscuro
class AppTextStyles {
  // Display - Títulos principales
  static const TextStyle displayLarge = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.bold,
    height: 1.2,
    letterSpacing: 0.4,
    color: Color(0xFFFFFFFF),
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.25,
    letterSpacing: 0.36,
    color: Color(0xFFFFFFFF),
  );

  // Headline - Encabezados de sección
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.35,
    color: Color(0xFFFFFFFF),
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.25,
    color: Color(0xFFFFFFFF),
  );

  // Title - Títulos de tarjetas
  static const TextStyle titleLarge = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: -0.41,
    color: Color(0xFFFFFFFF),
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: -0.24,
    color: Color(0xFFFFFFFF),
  );

  // Body - Texto de contenido
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.normal,
    height: 1.47,
    letterSpacing: -0.41,
    color: Color(0xFFEBEBF5),
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    height: 1.47,
    letterSpacing: -0.24,
    color: Color(0xFFEBEBF5),
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    height: 1.38,
    letterSpacing: -0.08,
    color: Color(0xFF8E8E93),
  );

  // Label - Etiquetas y botones
  static const TextStyle labelLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.43,
    letterSpacing: -0.5,
    color: Color(0xFFFFFFFF),
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.38,
    letterSpacing: -0.08,
    color: Color(0xFFEBEBF5),
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.36,
    letterSpacing: 0.06,
    color: Color(0xFF8E8E93),
  );
}

/// Colores consistentes para tema oscuro
class AppColors {
  // Primarios - Azul más vibrante y legible
  static const Color primary = Color(0xFF3B9CFF);
  static const Color primaryDark = Color(0xFF2680E0);
  static const Color primaryLight = Color(0xFF5DB4FF);

  // Secundarios
  static const Color secondary = Color(0xFF8E8E93);
  static const Color secondaryLight = Color(0xFFAEAEB2);

  // Estados con mejor contraste
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFFB800);
  static const Color error = Color(0xFFFF453A);
  static const Color info = Color(0xFF007AFF);

  // Superficies con mejor jerarquía visual
  static const Color surface = Color(0xFF1C1C1E);
  static const Color surfaceLight = Color(0xFF2C2C2E);
  static const Color background = Color(0xFF000000);
  static const Color backgroundLight = Color(0xFF1C1C1E);

  // Texto con mejor contraste
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFEBEBF5);
  static const Color textMuted = Color(0xFF8E8E93);

  // Bordes y separadores más sutiles
  static const Color border = Color(0xFF38383A);
  static const Color borderLight = Color(0xFF48484A);

  // Neutros
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey = Color(0xFF48484A);
  static const Color greyDark = Color(0xFF2C2C2E);
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
