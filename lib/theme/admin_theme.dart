import 'package:flutter/material.dart';

class AdminColors {
  static const Color primary    = Color(0xFF7B4DFF);
  static const Color secondary  = Color(0xFF9C6BFF);
  static const Color background = Color(0xFFF7F6FF);
  static const Color darkText   = Color(0xFF1F1F39);
  static const Color greyText   = Color(0xFF8E8EA9);
  static const Color white      = Color(0xFFFFFFFF);
  static const Color success    = Color(0xFF22C55E);
  static const Color warning    = Color(0xFFF59E0B);
  static const Color rejected   = Color(0xFFEF4444);
  static const Color border     = Color(0xFFE6E1FF);
  static const double radius    = 30;

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AdminTheme {
  static ThemeData get theme {
    final scheme = ColorScheme.fromSeed(
      seedColor: AdminColors.primary,
      brightness: Brightness.light,
      primary: AdminColors.primary,
      secondary: AdminColors.secondary,
      surface: AdminColors.white,
      error: AdminColors.rejected,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AdminColors.background,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: AdminColors.primary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
        // ← fixed: was 30, now a balanced 20
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -.4,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AdminColors.darkText,
        contentTextStyle: const TextStyle(color: AdminColors.white, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 76,
        backgroundColor: AdminColors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AdminColors.primary.withOpacity(0.12),
        labelTextStyle: WidgetStateProperty.resolveWith(
              (states) => TextStyle(
            color: states.contains(WidgetState.selected) ? AdminColors.primary : AdminColors.greyText,
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
              (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? AdminColors.primary : AdminColors.greyText,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AdminColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AdminColors.radius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AdminColors.radius),
          borderSide: BorderSide(color: AdminColors.primary.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AdminColors.radius),
          borderSide: const BorderSide(color: AdminColors.primary, width: 1.4),
        ),
        hintStyle: const TextStyle(color: AdminColors.greyText, fontWeight: FontWeight.w600),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AdminColors.primary,
          foregroundColor: AdminColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AdminColors.primary,
          side: BorderSide(color: AdminColors.primary.withOpacity(0.28)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AdminColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
