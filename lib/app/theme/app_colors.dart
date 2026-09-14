// ─────────────────────────────────────────────
//  app_colors.dart
//  Central colour palette for Raksha+.
//  All UI components reference these constants
//  so changing a colour here updates the whole app.
// ─────────────────────────────────────────────
import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // prevent instantiation

  // ── Backgrounds ──────────────────────────────
  static const Color scaffoldBg   = Color(0xFF0D0D1A); // deepest dark bg
  static const Color cardBg       = Color(0xFF1A1A2E); // card surfaces
  static const Color inputBg      = Color(0xFF252540); // text-field fill
  static const Color divider      = Color(0xFF2A2A45); // subtle separator

  // ── Brand / Accent ───────────────────────────
  static const Color primary      = Color(0xFFE91E63); // pink rose primary
  static const Color primaryLight = Color(0xFFFF4081); // hover / lighter
  static const Color primaryDark  = Color(0xFFC2185B); // pressed / darker

  // ── Text ─────────────────────────────────────
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0CC);
  static const Color textHint      = Color(0xFF6B6B8A);

  // ── Status ───────────────────────────────────
  static const Color success  = Color(0xFF4CAF50);
  static const Color warning  = Color(0xFFFFC107);
  static const Color error    = Color(0xFFE53935);
  static const Color liveGreen= Color(0xFF00E676);

  // ── Gradient stops ───────────────────────────
  static const List<Color> pinkGradient = [
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
  ];

  static const List<Color> bgGradient = [
    Color(0xFF0D0D1A),
    Color(0xFF1A1A2E),
  ];
}
