// ─────────────────────────────────────────────
//  app_theme.dart
//  Global MaterialApp ThemeData for Raksha+.
//  Uses Google Fonts (Poppins) and the colour
//  palette defined in app_colors.dart.
// ─────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    // Base text theme using Poppins for a modern, premium look
    final textTheme = GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme)
        .copyWith(
      displayLarge:  GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold,   color: AppColors.textPrimary),
      displayMedium: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold,   color: AppColors.textPrimary),
      headlineMedium:GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600,   color: AppColors.textPrimary),
      headlineSmall: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600,   color: AppColors.textPrimary),
      titleLarge:    GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600,   color: AppColors.textPrimary),
      titleMedium:   GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500,   color: AppColors.textPrimary),
      bodyLarge:     GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.normal, color: AppColors.textPrimary),
      bodyMedium:    GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.normal, color: AppColors.textSecondary),
      bodySmall:     GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.normal, color: AppColors.textHint),
      labelLarge:    GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600,   color: AppColors.textPrimary),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.scaffoldBg,
      colorScheme: const ColorScheme.dark(
        primary:   AppColors.primary,
        secondary: AppColors.primaryLight,
        surface:   AppColors.cardBg,
        error:     AppColors.error,
      ),
      textTheme: textTheme,

      // ── AppBar ──────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.scaffoldBg,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),

      // ── Cards ───────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.divider, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Elevated Button ─────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),

      // ── OutlinedButton ──────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // ── TextButton ──────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),

      // ── Input Fields ────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        hintStyle: GoogleFonts.poppins(color: AppColors.textHint, fontSize: 14),
        labelStyle: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 14),
      ),

      // ── Divider ─────────────────────────────
      dividerColor: AppColors.divider,

      // ── Icon ────────────────────────────────
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
    );
  }
}
