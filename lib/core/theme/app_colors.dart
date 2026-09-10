import 'package:flutter/material.dart';

/// Semantic color palette for the SpendWise monochrome design.
///
/// Never use raw color literals in screens/widgets — always reference
/// these semantic names so the palette can be changed centrally.
class AppColors {
  AppColors._();

  // Base surfaces
  static const Color background = Color(0xFFF7F7F8);
  static const Color surface = Color(0xFFFFFFFF);

  // Text
  static const Color primaryText = Color(0xFF111111);
  static const Color secondaryText = Color(0xFF6B6B6B);
  static const Color tertiaryText = Color(0xFF9A9A9A);

  // Accents / structure
  static const Color primary = Color(0xFF111111);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE8E8E8);
  static const Color divider = Color(0xFFEFEFEF);

  // Fills
  static const Color subtleFill = Color(0xFFF1F1F2);
  static const Color darkFill = Color(0xFF111111);

  // Progress / charts (kept monochrome with subtle contrast)
  static const Color progressTrack = Color(0xFFEDEDEE);
  static const Color progressFill = Color(0xFF111111);
  static const Color chartBar = Color(0xFFD9D9DB);
  static const Color chartBarActive = Color(0xFF111111);

  // States
  static const Color error = Color(0xFFB3261E);
  static const Color overBudget = Color(0xFFB3261E);
  static const Color success = Color(0xFF111111);

  // Shadows
  static const Color shadow = Color(0x14000000);
}
