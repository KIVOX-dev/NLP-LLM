import 'package:flutter/material.dart';

/// Vercel/Geist-inspired token system: primitive → semantic layering.
/// Monochrome-first (black/white carries all primary UI weight); color is
/// reserved for semantic status only (confidence, success/warning/danger).
abstract final class AppColors {
  // ---- Primitives (raw neutral ramp) ----
  static const Color _black = Color(0xFF000000);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _gray50 = Color(0xFFFAFAFA);
  static const Color _gray200 = Color(0xFFEAEAEA);
  static const Color _gray500 = Color(0xFF8F8F8F);
  static const Color _gray600 = Color(0xFF666666);
  static const Color _gray800 = Color(0xFF333333);
  static const Color _gray900 = Color(0xFF111111);
  static const Color _gray950 = Color(0xFF0A0A0A);

  // ---- Semantic: accent (monochrome — flips with theme) ----
  static const Color accent = _black;
  static const Color accentDark = _white;

  // ---- Semantic: surfaces ----
  static const Color lightBackground = _white;
  static const Color lightSurface = _white;
  static const Color lightSurfaceAlt = _gray50;
  static const Color lightBorder = _gray200;
  static const Color lightTextPrimary = _gray950;
  static const Color lightTextSecondary = _gray600;

  static const Color darkBackground = _black;
  static const Color darkSurface = _gray950;
  static const Color darkSurfaceAlt = _gray900;
  static const Color darkBorder = _gray800;
  static const Color darkTextPrimary = _gray50;
  static const Color darkTextSecondary = _gray500;

  // ---- Semantic: status ----
  static const Color success = Color(0xFF12805C);
  static const Color warning = Color(0xFFB45309);
  static const Color danger = Color(0xFFE5484D);

  static const Color confidenceHigh = success;
  static const Color confidenceMedium = warning;
  static const Color confidenceLow = danger;
}
