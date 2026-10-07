// Design tokens (design-spec §2): the single source of color/type/spacing.
// No hardcoded values outside these tokens (design principle 5).

import 'package:flutter/material.dart';

abstract final class DesignTokens {
  // --- color roles: resolve per brightness ---
  static Color surfacePrimary(BuildContext context) =>
      Theme.of(context).colorScheme.surface;
  static Color surfaceSecondary(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerLow;
  static Color surfaceTertiary(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerHighest;
  static Color textPrimary(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;
  static Color textSecondary(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;
  static Color textTertiary(BuildContext context) =>
      Theme.of(context).colorScheme.outline;
  static Color accentPrimary(BuildContext context) =>
      Theme.of(context).colorScheme.primary;
  static Color accentOnAccent(BuildContext context) =>
      Theme.of(context).colorScheme.onPrimary;
  static Color success(BuildContext context) =>
      Theme.of(context).colorScheme.tertiary;
  static Color warning(BuildContext context) =>
      Theme.of(context).extension<WeatherColors>()!.warning;
  static Color error(BuildContext context) =>
      Theme.of(context).colorScheme.error;
  static Color errorSurface(BuildContext context) =>
      Theme.of(context).colorScheme.errorContainer;
  static Color focusRing(BuildContext context) =>
      Theme.of(context).extension<WeatherColors>()!.focusRing;
  static Color onErrorSurface(BuildContext context) =>
      Theme.of(context).colorScheme.onErrorContainer;

  // --- raw palette (design-spec §2.1) ---
  static const Color _lightWarning = Color(0xFFB54708);
  static const Color _darkWarning = Color(0xFFF5A524);
  static const Color _lightFocusRing = Color(0xFF0E6FF2);
  static const Color _darkFocusRing = Color(0xFF5EA3FF);

  static ThemeExtension<WeatherColors> extensionFor(Brightness brightness) =>
      WeatherColors(
        warning:
            brightness == Brightness.light ? _lightWarning : _darkWarning,
        focusRing: brightness == Brightness.light
            ? _lightFocusRing
            : _darkFocusRing,
      );

  // --- spacing scale (4 pt base) ---
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s48 = 48;

  static const double cardRadius = 16;
  static const double buttonRadius = 12;

  // --- themes ---
  static ThemeData lightTheme() => _build(Brightness.light);
  static ThemeData darkTheme() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final bool light = brightness == Brightness.light;
    final ColorScheme scheme = ColorScheme(
      brightness: brightness,
      primary: light ? const Color(0xFF0E6FF2) : const Color(0xFF5EA3FF),
      onPrimary: light ? Colors.white : const Color(0xFF06203F),
      secondary: light ? const Color(0xFF475467) : const Color(0xFFA8B4C6),
      onSecondary: Colors.white,
      tertiary: light ? const Color(0xFF12805C) : const Color(0xFF3FBF8F),
      onTertiary: Colors.white,
      error: light ? const Color(0xFFB42318) : const Color(0xFFF97066),
      onError: Colors.white,
      errorContainer:
          light ? const Color(0xFFFDECEC) : const Color(0xFF2A1518),
      onErrorContainer:
          light ? const Color(0xFFB42318) : const Color(0xFFF97066),
      surface: light ? Colors.white : const Color(0xFF0D1420),
      onSurface: light ? const Color(0xFF101828) : const Color(0xFFF5F8FC),
      surfaceContainerLow:
          light ? const Color(0xFFF2F5F9) : const Color(0xFF16202F),
      surfaceContainerHighest:
          light ? const Color(0xFFE8EDF4) : const Color(0xFF1F2B3D),
      onSurfaceVariant:
          light ? const Color(0xFF475467) : const Color(0xFFA8B4C6),
      outline: light ? const Color(0xFF667085) : const Color(0xFF7B8BA1),
    );
    // Platform fonts: system default (San Francisco / Roboto) — no fontFamily
    // set. Tabular figures on numeric styles (design §2.1).
    TextStyle s(double size, FontWeight w, double lh, {bool tabular = false}) =>
        TextStyle(
          fontSize: size,
          fontWeight: w,
          height: lh / size,
          fontFeatures:
              tabular ? const <FontFeature>[FontFeature.tabularFigures()] : null,
        );
    final TextTheme text = TextTheme(
      displayLarge: s(64, FontWeight.w600, 72, tabular: true), // display-xl
      displayMedium: s(48, FontWeight.w600, 56, tabular: true), // display-l
      headlineSmall: s(24, FontWeight.w700, 32), // heading-l
      titleLarge: s(20, FontWeight.w600, 28), // heading-m
      titleMedium: s(16, FontWeight.w600, 24), // heading-s
      bodyLarge: s(16, FontWeight.w400, 24), // body-l
      bodyMedium: s(14, FontWeight.w400, 20), // body-m
      bodySmall: s(12, FontWeight.w400, 16, tabular: true), // body-s
      labelLarge: s(14, FontWeight.w600, 20), // label-m
      labelSmall: s(12, FontWeight.w600, 16), // label-s
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: text,
      extensions: <ThemeExtension<dynamic>>[extensionFor(brightness)],
      // 48 dp minimum touch targets (R-15).
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
    );
  }
}

@immutable
class WeatherColors extends ThemeExtension<WeatherColors> {
  final Color warning;
  final Color focusRing;

  const WeatherColors({required this.warning, required this.focusRing});

  @override
  WeatherColors copyWith({Color? warning, Color? focusRing}) =>
      WeatherColors(
        warning: warning ?? this.warning,
        focusRing: focusRing ?? this.focusRing,
      );

  @override
  WeatherColors lerp(ThemeExtension<WeatherColors>? other, double t) {
    if (other is! WeatherColors) return this;
    return WeatherColors(
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      focusRing: Color.lerp(focusRing, other.focusRing, t) ?? focusRing,
    );
  }
}
