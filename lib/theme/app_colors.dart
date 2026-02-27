import 'package:flutter/material.dart';

/// All color tokens from the Relapse design system.
class AppColors {
  AppColors._();

  // Background Gradient Colors
  static const Color gradientStart = Color(0xFF90CAF9); // Blue 200
  static const Color gradientMiddle = Color(0xFF80CBC4); // Teal 200
  static const Color gradientEnd = Color(0xFFC8E6C9); // Green 100

  // Button Gradient Colors
  static const Color buttonGradientStart = Color(0xFF42A5F5);
  static const Color buttonGradientMiddle = Color(0xFF673AB7);
  static const Color buttonGradientEnd = Color(0xFFE91E63);

  // Material 3 Semantic Colors
  static const Color primaryColor = Color(0xFF386A20);
  static const Color onPrimaryColor = Color(0xFFFFFFFF);
  static const Color primaryContainerColor = Color(0xFFB8F398);
  static const Color onPrimaryContainerColor = Color(0xFF002201);

  static const Color secondaryColor = Color(0xFF53634E);
  static const Color onSecondaryColor = Color(0xFFFFFFFF);
  static const Color secondaryContainerColor = Color(0xFFD6E8CD);
  static const Color onSecondaryContainerColor = Color(0xFF111F0F);

  static const Color tertiaryColor = Color(0xFF38656B);
  static const Color onTertiaryColor = Color(0xFFFFFFFF);

  static const Color errorColor = Color(0xFFBA1A1A);
  static const Color onErrorColor = Color(0xFFFFFFFF);

  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color onSurfaceColor = Color(0xFF1A1C18);
  static const Color backgroundColor = Color(0xFFFDFDFB);

  // Status/Feedback Colors
  static const Color safeZoneInsideStart = Color(0xFF4CAF50);
  static const Color safeZoneInsideEnd = Color(0xFF66BB6A);
  static const Color safeZoneOutsideStart = Color(0xFFF44336);
  static const Color safeZoneOutsideEnd = Color(0xFFE57373);

  static const Color watchConnected = Color(0xFF2E7D32);
  static const Color watchDisconnected = Color(0xFFC62828);
}
