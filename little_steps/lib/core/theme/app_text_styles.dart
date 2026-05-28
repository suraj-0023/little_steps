import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Lora — Serif for prominent headings and editorial visual identity
  static const TextStyle display = TextStyle(
    fontFamily: 'Lora',
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.25,
  );

  static const TextStyle headline = TextStyle(
    fontFamily: 'Lora',
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
    height: 1.35,
  );

  static const TextStyle title = TextStyle(
    fontFamily: 'Lora',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.45,
  );

  // Nunito — Clean Sans-Serif for body text and navigation UI elements
  static const TextStyle body = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    letterSpacing: 0.15,
    height: 1.6,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    letterSpacing: 0.15,
    height: 1.6,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    letterSpacing: 0.25,
    height: 1.5,
  );

  static const TextStyle label = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 1.0, // Spacious letter-spacing for premium feel
    height: 1.4,
  );

  static const TextStyle button = TextStyle(
    fontFamily: 'Nunito',
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2, // Clean tracking on button text
    height: 1.2,
  );

  // Lora — AI story / letters text (serif, highly readable & warm)
  static const TextStyle storyBody = TextStyle(
    fontFamily: 'Lora',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    letterSpacing: 0.1,
    height: 1.8, // Tall line height for high readability
  );

  static const TextStyle storyTitle = TextStyle(
    fontFamily: 'Lora',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
    height: 1.4,
  );
}
