import 'package:flutter/material.dart';
import 'app_colors.dart';

/// All gradient definitions from the Relapse design system.
class AppGradients {
  AppGradients._();

  /// Background gradient (topCenter → bottomCenter)
  static const LinearGradient background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.gradientStart,
      AppColors.gradientMiddle,
      AppColors.gradientEnd,
    ],
  );

  /// Button/pill gradient (centerLeft → centerRight)
  static const LinearGradient button = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      AppColors.gradientStart,
      AppColors.gradientMiddle,
    ],
  );

  /// Icon/text gradient (topLeft → bottomRight)
  static const LinearGradient iconText = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.gradientStart,
      AppColors.gradientMiddle,
      AppColors.gradientEnd,
    ],
  );

  /// Card border gradient (topLeft → bottomRight)
  static const LinearGradient cardBorder = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.gradientStart,
      AppColors.gradientMiddle,
      AppColors.gradientEnd,
    ],
  );

  /// Primary action gradient (topLeft → bottomRight)
  static const LinearGradient primaryAction = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.gradientStart,
      AppColors.gradientMiddle,
      AppColors.gradientEnd,
    ],
  );

  /// Text gradient (centerLeft → centerRight) — used with ShaderMask
  static const LinearGradient text = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      AppColors.gradientStart,
      AppColors.gradientMiddle,
      AppColors.gradientEnd,
    ],
  );
}
