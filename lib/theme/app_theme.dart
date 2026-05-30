// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppColors {
  static const teal = Color(0xFF3ECFB2);
  static const tealLight = Color(0xFFE8F8F5);
  static const orange = Color(0xFFFF7043);
  static const orangeLight = Color(0xFFFFF3EF);
  static const background = Color(0xFFF5F6FA);
  static const cardBg = Color(0xFFFFFFFF);
  static const textDark = Color(0xFF1A1A2E);
  static const textGrey = Color(0xFF8A8FA3);
  static const border = Color(0xFFEEEFF4);

  // Category colors
  static const equilibreColor = Color(0xFF9B59B6);
  static const equilibreBg = Color(0xFFF5EEF8);
  static const renforcementColor = Color(0xFF3498DB);
  static const renforcementBg = Color(0xFFEBF5FB);
  static const mobiliteColor = Color(0xFF27AE60);
  static const mobiliteBg = Color(0xFFEAF7EF);
  static const etirementColor = Color(0xFFE67E22);
  static const etirementBg = Color(0xFFFEF5EC);
  static const cardioColor = Color.fromARGB(193, 182, 11, 5);
  static const cardioBg = Color(0xFFFEF5EC);
  static const autreColor = Color(0xFF95A5A6);
  static const autreBg = Color(0xFFF2F3F4);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.teal,
      primary: AppColors.teal,
      background: AppColors.background,
    ),
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: false,
      foregroundColor: AppColors.textDark,
      titleTextStyle: TextStyle(
        color: AppColors.textDark,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.teal, width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle:
            const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.teal,
      unselectedItemColor: AppColors.textGrey,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
  );
}
