import 'package:flutter/material.dart';

class AppColors {
  static const green = Color(0xFF1F6F4A);
  static const greenDark = Color(0xFF17583A);
  static const greenSoft = Color(0xFFE4F0E8);
  static const greenBorder = Color(0xFFBBD8C6);
  static const background = Color(0xFFF4F6F0);
  static const surface = Colors.white;
  static const border = Color(0xFFDDE2DA);
  static const text = Color(0xFF1B241F);
  static const textMuted = Color(0xFF6A746D);
  static const error = Color(0xFFC0392B);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.green,
      primary: AppColors.green,
      surface: AppColors.surface,
    ),
    scaffoldBackgroundColor: AppColors.background,
  );

  OutlineInputBorder border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c),
      );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      border: border(AppColors.border),
      enabledBorder: border(AppColors.border),
      focusedBorder: border(AppColors.green),
      errorBorder: border(AppColors.error),
      focusedErrorBorder: border(AppColors.error),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      side: const BorderSide(color: AppColors.border, width: 1.5),
    ),
  );
}
