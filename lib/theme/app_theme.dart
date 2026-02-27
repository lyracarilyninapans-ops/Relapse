import 'package:flutter/material.dart';
import 'app_colors.dart';

/// App theme built from Material 3 + Relapse design tokens.
class AppTheme {
  AppTheme._();

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: AppColors.primaryColor,
      onPrimary: AppColors.onPrimaryColor,
      primaryContainer: AppColors.primaryContainerColor,
      onPrimaryContainer: AppColors.onPrimaryContainerColor,
      secondary: AppColors.secondaryColor,
      onSecondary: AppColors.onSecondaryColor,
      secondaryContainer: AppColors.secondaryContainerColor,
      onSecondaryContainer: AppColors.onSecondaryContainerColor,
      tertiary: AppColors.tertiaryColor,
      onTertiary: AppColors.onTertiaryColor,
      error: AppColors.errorColor,
      onError: AppColors.onErrorColor,
      surface: AppColors.surfaceColor,
      onSurface: AppColors.onSurfaceColor,
    ),
    scaffoldBackgroundColor: AppColors.backgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.backgroundColor,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.gradientStart),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.onSurfaceColor,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceColor,
      hintStyle: TextStyle(color: Colors.black.withAlpha(128)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.gradientMiddle,
          width: 2,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
    ),
  );
}
