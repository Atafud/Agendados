import 'package:flutter/material.dart';

/// Paletas medidas. Claro: ratios sobre blanco: primario 6,15 · error 6,54 ·
/// éxito 6,75 · secundario 9,02. Oscuro y alto contraste: todos los pares
/// texto/fondo >= 7:1 (el alto contraste busca >= 10:1 en texto principal).
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.surface, required this.text, required this.textSecondary,
    required this.primary, required this.onPrimary, required this.selectedBg,
    required this.error, required this.success, required this.successBg,
    required this.urgent, required this.disabled,
  });
  final Color surface, text, textSecondary, primary, onPrimary, selectedBg,
      error, success, successBg, urgent, disabled;

  static const light = AppColors(
    surface: Color(0xFFFFFFFF), text: Color(0xFF000000), textSecondary: Color(0xFF4C4848),
    primary: Color(0xFF7241D3), onPrimary: Color(0xFFFFFFFF),
    selectedBg: Color(0xFFE9DDFB), // texto negro 16,2:1
    error: Color(0xFFB3261E), success: Color(0xFF14693A), successBg: Color(0xFFE4F4EA),
    urgent: Color(0xFFB3261E), disabled: Color(0xFF6B6666), // 5,65:1
  );
  static const dark = AppColors(
    surface: Color(0xFF121212), text: Color(0xFFFFFFFF), textSecondary: Color(0xFFD0CCD0),
    primary: Color(0xFFCDB8FF), onPrimary: Color(0xFF1E0A4A),
    selectedBg: Color(0xFF3A2A66), error: Color(0xFFFFB4AB),
    success: Color(0xFF7FD99B), successBg: Color(0xFF0F2E1B),
    urgent: Color(0xFFFFB4AB), disabled: Color(0xFFB0ABB0),
  );
  static const highContrastLight = AppColors(
    surface: Color(0xFFFFFFFF), text: Color(0xFF000000), textSecondary: Color(0xFF000000),
    primary: Color(0xFF3F1C94), onPrimary: Color(0xFFFFFFFF),
    selectedBg: Color(0xFFDCC8FF), error: Color(0xFF8C0009),
    success: Color(0xFF0B4A27), successBg: Color(0xFFD3EEDC),
    urgent: Color(0xFF8C0009), disabled: Color(0xFF4C4848),
  );
  static const highContrastDark = AppColors(
    surface: Color(0xFF000000), text: Color(0xFFFFFFFF), textSecondary: Color(0xFFFFFFFF),
    primary: Color(0xFFE6DBFF), onPrimary: Color(0xFF000000),
    selectedBg: Color(0xFF4A3685), error: Color(0xFFFFCFC9),
    success: Color(0xFFA6F0BC), successBg: Color(0xFF0B3A1F),
    urgent: Color(0xFFFFCFC9), disabled: Color(0xFFD0CCD0),
  );

  static AppColors of(BuildContext context) => Theme.of(context).extension<AppColors>()!;

  // shortcut: la paleta no se interpola, cambia de golpe; si hay animación de tema, implementar lerp.
  @override
  AppColors copyWith() => this;
  @override
  AppColors lerp(AppColors? other, double t) => t < 0.5 || other == null ? this : other;
}

// shortcut: elección en memoria, se pierde al cerrar la app; si hace falta persistirla, guardar en shared_preferences.
final themeMode = ValueNotifier<ThemeMode>(ThemeMode.system);

const double kMinTarget = 48; // objetivo táctil mínimo
const double kGap = 8; // separación mínima entre controles

ThemeData buildTheme(AppColors c, {Brightness brightness = Brightness.light}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: c.primary,
    brightness: brightness,
    primary: c.primary,
    onPrimary: c.onPrimary,
    error: c.error,
    surface: c.surface,
    onSurface: c.text,
  );
  const minSize = Size(kMinTarget, kMinTarget);
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    extensions: [c],
    scaffoldBackgroundColor: c.surface,
    // Sin textScaler fijo: se respeta el escalado del sistema.
    textTheme: TextTheme(
      headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.text),
      titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.text),
      bodyLarge: TextStyle(fontSize: 16, color: c.text),
      bodyMedium: TextStyle(fontSize: 15, color: c.textSecondary),
      labelSmall: TextStyle(fontSize: 14, color: c.textSecondary),
    ),
    materialTapTargetSize: MaterialTapTargetSize.padded,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: minSize,
        backgroundColor: c.primary,
        foregroundColor: c.onPrimary,
        disabledBackgroundColor: c.surface,
        disabledForegroundColor: c.disabled,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: minSize,
        foregroundColor: c.primary,
        side: BorderSide(color: c.primary, width: 2),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: minSize,
        foregroundColor: c.primary,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderSide: BorderSide(color: c.primary, width: 2)),
      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: c.primary, width: 2)),
      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: c.primary, width: 3)),
      errorBorder: OutlineInputBorder(borderSide: BorderSide(color: c.error, width: 3)),
      focusedErrorBorder: OutlineInputBorder(borderSide: BorderSide(color: c.error, width: 3)),
      errorStyle: TextStyle(color: c.error, fontWeight: FontWeight.w700, fontSize: 15),
    ),
  );
}
