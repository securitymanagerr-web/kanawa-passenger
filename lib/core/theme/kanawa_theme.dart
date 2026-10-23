// KANAWA - Tema global (Material 3)
// Usa os tokens de cores e espaçamento

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'kanawa_colors.dart';

class KanawaTheme {
  KanawaTheme._();

  // ═══════════════════════════════════════════════════════
  // TEMA CLARO (padrão do KANAWA)
  // ═══════════════════════════════════════════════════════
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
    );

    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: KanawaColors.textBase,
      displayColor: KanawaColors.textStrong,
    );

    return base.copyWith(
      scaffoldBackgroundColor: KanawaColors.bgApp,
      textTheme: textTheme,

      // ─── ColorScheme ───
      colorScheme: ColorScheme.fromSeed(
        seedColor: KanawaColors.brand,
        brightness: Brightness.light,
      ).copyWith(
        primary: KanawaColors.brand,
        onPrimary: Colors.white,
        surface: KanawaColors.bgCard,
        onSurface: KanawaColors.textStrong,
        error: KanawaColors.danger,
        outline: KanawaColors.border,
      ),

      // ─── AppBar ───
      appBarTheme: AppBarTheme(
        backgroundColor: KanawaColors.bgApp,
        foregroundColor: KanawaColors.textStrong,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: KanawaColors.textStrong,
        ),
      ),

      // ─── Botão principal ───
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: KanawaColors.brand,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ─── Botão secundário (outlined) ───
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: KanawaColors.textBase,
          side: const BorderSide(color: KanawaColors.borderStrong),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // ─── Botão de texto ───
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: KanawaColors.brand,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ─── Inputs ───
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: KanawaColors.bgCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: KanawaColors.borderStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: KanawaColors.borderStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: KanawaColors.brand, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: KanawaColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: KanawaColors.danger, width: 2),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          color: KanawaColors.textMuted,
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: KanawaColors.textDisabled,
        ),
        errorStyle: GoogleFonts.inter(
          fontSize: 12,
          color: KanawaColors.danger,
        ),
      ),

      // ─── Cards ───
      cardTheme: CardThemeData(
        color: KanawaColors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: KanawaColors.border),
        ),
        margin: EdgeInsets.zero,
      ),

      // ─── Divider ───
      dividerTheme: const DividerThemeData(
        color: KanawaColors.border,
        thickness: 1,
        space: 1,
      ),

      // ─── Snackbar ───
      snackBarTheme: SnackBarThemeData(
        backgroundColor: KanawaColors.textStrong,
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}