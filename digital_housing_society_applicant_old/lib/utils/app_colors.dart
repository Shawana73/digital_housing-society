import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primaryPurple = Color(0xFF7C4DFF);
  static const Color secondaryPurple = Color(0xFFA970FF);
  static const Color deepPurple = Color(0xFF5B2EEA);
  static const Color lavender = Color(0xFFC9B6FF);
  static const Color lightPurpleBackground = Color(0xFFEDE7FF);

  static const Color pageBackground = Color(0xFFF7F7FC);
  static const Color cardColor = Color(0xFFFFFFFF);

  static const Color primaryText = Color(0xFF1F2937);
  static const Color secondaryText = Color(0xFF6B7280);
  static const Color hintText = Color(0xFF9CA3AF);

  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color shadowColor = Color(0xFFD8CCFF);

  static const Color successGreen = Color(0xFF22C55E);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color warningOrange = Color(0xFFF59E0B);

  static const Color successLightBackground = Color(0xFFE7F9EE);
  static const Color errorLightBackground = Color(0xFFFDECEC);
  static const Color warningLightBackground = Color(0xFFFEF3E2);

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color inactiveGrey = Color(0xFF9CA3AF);
  static const Color darkNavy = Color(0xFF111827);
  static const Color infoBlue = Color(0xFF3B82F6);
  static const Color infoLightBackground = Color(0xFFEFF6FF);
  static const Color gold = Color(0xFFFBBF24);
  static const Color reservedGrey = Color(0xFF9CA3AF);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryPurple, deepPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient softPurpleGradient = LinearGradient(
    colors: [secondaryPurple, primaryPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static List<BoxShadow> premiumShadow({
    double opacity = 0.4,
    double blurRadius = 16,
    Offset offset = const Offset(0, 6),
  }) {
    return [
      BoxShadow(
        color: shadowColor.withValues(alpha: opacity),
        blurRadius: blurRadius,
        offset: offset,
      ),
    ];
  }
}
