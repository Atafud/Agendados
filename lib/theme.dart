import 'package:flutter/material.dart';

/// Paleta medida (semana 4, corregida). Ratios sobre blanco:
/// primario 6,15 · error 6,54 · éxito 6,75 · secundario 9,02.
class AppColors {
  static const text = Color(0xFF000000);
  static const textSecondary = Color(0xFF4C4848);
  static const primary = Color(0xFF7241D3);
  static const onPrimary = Color(0xFFFFFFFF);
  static const selectedBg = Color(0xFFE9DDFB); // texto negro 16,2:1
  static const error = Color(0xFFB3261E);
  static const success = Color(0xFF14693A);
  static const successBg = Color(0xFFE4F4EA);
  static const urgent = Color(0xFFB3261E);
  static const disabled = Color(0xFF6B6666); // 5,65:1
}

const double kMinTarget = 48; // objetivo táctil mínimo
const double kGap = 8; // separación mínima entre controles

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    error: AppColors.error,
    surface: Colors.white,
    onSurface: AppColors.text,
  );
  const minSize = Size(kMinTarget, kMinTarget);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.white,
    // Sin textScaler fijo: se respeta el escalado del sistema.
    textTheme: const TextTheme(
      headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text),
      titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text),
      bodyLarge: TextStyle(fontSize: 16, color: AppColors.text),
      bodyMedium: TextStyle(fontSize: 15, color: AppColors.textSecondary),
      labelSmall: TextStyle(fontSize: 14, color: AppColors.textSecondary),
    ),
    materialTapTargetSize: MaterialTapTargetSize.padded,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: minSize,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        disabledBackgroundColor: Colors.white,
        disabledForegroundColor: AppColors.disabled,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: minSize,
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 2),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: minSize,
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary, width: 2)),
      enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary, width: 2)),
      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary, width: 3)),
      errorBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.error, width: 3)),
      focusedErrorBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.error, width: 3)),
      errorStyle: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w700, fontSize: 15),
    ),
  );
}
