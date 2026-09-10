import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_fonts.dart';

/// Reusable text styles. Widgets should use these (or Theme.of(context)
/// text theme entries) instead of building TextStyles inline.
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle largeAmount = TextStyle(
    fontFamily: AppFonts.heading,
    fontSize: 40,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryText,
    letterSpacing: -1.0,
    height: 1.1,
  );

  static const TextStyle amount = TextStyle(
    fontFamily: AppFonts.heading,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryText,
    letterSpacing: -0.5,
  );

  static const TextStyle heading = TextStyle(
    fontFamily: AppFonts.heading,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryText,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle title = TextStyle(
    fontFamily: AppFonts.heading,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryText,
    letterSpacing: -0.2,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: AppFonts.heading,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryText,
  );

  static const TextStyle body = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.primaryText,
    height: 1.4,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryText,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.secondaryText,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    color: AppColors.secondaryText,
  );

  static const TextStyle label = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.secondaryText,
    letterSpacing: 0.2,
  );

  static const TextStyle button = TextStyle(
    fontFamily: AppFonts.heading,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.onPrimary,
    letterSpacing: 0.1,
  );
}
