import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  /// Shared control radius (buttons, inputs) — Vercel/Geist uses small,
  /// precise radii rather than heavily rounded "app" corners.
  static const double controlRadius = 8;

  /// Slightly larger radius for containers that hold controls (cards).
  static const double cardRadius = 10;

  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final background = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final surfaceAlt = isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final accent = isDark ? AppColors.accentDark : AppColors.accent;
    final onAccent = isDark ? AppColors.accent : AppColors.accentDark;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: accent,
      onPrimary: onAccent,
      secondary: surfaceAlt,
      onSecondary: textPrimary,
      error: AppColors.danger,
      onError: Colors.white,
      surface: surface,
      onSurface: textPrimary,
      outline: border,
    );

    final baseText = GoogleFonts.geistTextTheme();
    final textTheme = baseText.copyWith(
      headlineMedium: baseText.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: -0.6,
        height: 1.15,
      ),
      titleMedium: baseText.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: textPrimary),
      bodyLarge: baseText.bodyLarge?.copyWith(color: textPrimary, height: 1.55),
      bodyMedium: baseText.bodyMedium?.copyWith(color: textPrimary, height: 1.55),
      bodySmall: baseText.bodySmall?.copyWith(color: textSecondary),
      labelLarge: baseText.labelLarge?.copyWith(fontWeight: FontWeight.w500),
      labelSmall: baseText.labelSmall?.copyWith(
        color: textSecondary,
        letterSpacing: 0.8,
        fontWeight: FontWeight.w600,
      ),
    );

    final outlineBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(controlRadius),
      borderSide: BorderSide(color: border),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      fontFamily: GoogleFonts.geist().fontFamily,
      textTheme: textTheme,
      dividerColor: border,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: textPrimary.withValues(alpha: 0.04),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: outlineBorder,
        enabledBorder: outlineBorder,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide(color: textPrimary, width: 1.5),
        ),
        hintStyle: TextStyle(color: textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: onAccent,
          disabledBackgroundColor: surfaceAlt,
          disabledForegroundColor: textSecondary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(controlRadius)),
        ).copyWith(
          overlayColor: WidgetStateProperty.all(onAccent.withValues(alpha: 0.08)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(controlRadius)),
        ).copyWith(
          overlayColor: WidgetStateProperty.all(textPrimary.withValues(alpha: 0.04)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(controlRadius)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textSecondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(controlRadius)),
        ),
      ),
      iconTheme: IconThemeData(color: textSecondary, size: 20),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        side: BorderSide(color: border),
        labelStyle: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(controlRadius)),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      drawerTheme: DrawerThemeData(backgroundColor: surface),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: textPrimary,
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: TextStyle(color: background, fontSize: 12),
      ),
    );
  }
}
