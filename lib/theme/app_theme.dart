import 'package:flutter/material.dart';
import 'app_colors.dart';

/// App theme built from Material 3 + Relapse design tokens.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
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
    );
  }
}
