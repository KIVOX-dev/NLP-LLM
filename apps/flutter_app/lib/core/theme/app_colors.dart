import 'package:flutter/material.dart';

/// Brand-neutral palette for a "serious research/translation tool" look
/// (spec §48) — muted indigo accent, warm neutrals, no gradients.
abstract final class AppColors {
  static const Color accent = Color(0xFF4F5FE0);
  static const Color accentMuted = Color(0xFFE3E5FB);

  static const Color lightBackground = Color(0xFFFAFAF9);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFF1F1EF);
  static const Color lightBorder = Color(0xFFE4E4E1);
  static const Color lightTextPrimary = Color(0xFF1C1C1A);
  static const Color lightTextSecondary = Color(0xFF6B6B66);

  static const Color darkBackground = Color(0xFF17171A);
  static const Color darkSurface = Color(0xFF1F1F23);
  static const Color darkSurfaceAlt = Color(0xFF27272C);
  static const Color darkBorder = Color(0xFF34343A);
  static const Color darkTextPrimary = Color(0xFFF2F2F0);
  static const Color darkTextSecondary = Color(0xFFA6A6A2);

  static const Color success = Color(0xFF3E9B5C);
  static const Color warning = Color(0xFFB8802A);
  static const Color danger = Color(0xFFC24545);

  static const Color confidenceHigh = success;
  static const Color confidenceMedium = warning;
  static const Color confidenceLow = danger;
}
