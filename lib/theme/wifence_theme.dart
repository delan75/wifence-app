import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WiFenceColors {
  static const ink = Color(0xFF102030);
  static const deepSea = Color(0xFF13273A);
  static const cobalt = Color(0xFF2B63FF);
  static const sky = Color(0xFF4AB8FF);
  static const mint = Color(0xFF29B98A);
  static const coral = Color(0xFFF48A55);
  static const canvas = Color(0xFFF3EEE6);
  static const card = Color(0xFFFFFCF8);
  static const line = Color(0xFFE2D9CB);
  static const muted = Color(0xFF6D7B88);
  static const danger = Color(0xFFD45E52);
}

ThemeData buildWiFenceTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: WiFenceColors.cobalt,
      primary: WiFenceColors.cobalt,
      secondary: WiFenceColors.coral,
      surface: WiFenceColors.card,
      onSurface: WiFenceColors.ink,
      brightness: Brightness.light,
    ),
  );

  final bodyText = GoogleFonts.manropeTextTheme(base.textTheme);
  final textTheme = bodyText.copyWith(
    displayLarge: GoogleFonts.sora(
      fontSize: 48,
      fontWeight: FontWeight.w700,
      color: WiFenceColors.ink,
    ),
    displayMedium: GoogleFonts.sora(
      fontSize: 40,
      fontWeight: FontWeight.w700,
      color: WiFenceColors.ink,
    ),
    headlineLarge: GoogleFonts.sora(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: WiFenceColors.ink,
    ),
    headlineMedium: GoogleFonts.sora(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      color: WiFenceColors.ink,
    ),
    headlineSmall: GoogleFonts.sora(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: WiFenceColors.ink,
    ),
    titleLarge: GoogleFonts.sora(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: WiFenceColors.ink,
    ),
    titleMedium: GoogleFonts.sora(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: WiFenceColors.ink,
    ),
    bodyLarge: GoogleFonts.manrope(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: WiFenceColors.ink,
      height: 1.25,
    ),
    bodyMedium: GoogleFonts.manrope(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: WiFenceColors.muted,
      height: 1.35,
    ),
    bodySmall: GoogleFonts.manrope(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: WiFenceColors.muted,
      letterSpacing: 0.2,
    ),
  );

  return base.copyWith(
    textTheme: textTheme,
    scaffoldBackgroundColor: WiFenceColors.canvas,
    dividerColor: WiFenceColors.line,
    cardTheme: CardThemeData(
      color: WiFenceColors.card,
      shadowColor: Colors.black.withValues(alpha: 0.03),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: const BorderSide(color: WiFenceColors.line),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: WiFenceColors.ink,
      elevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: WiFenceColors.cobalt,
        foregroundColor: Colors.white,
        textStyle: GoogleFonts.sora(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: WiFenceColors.deepSea,
        side: const BorderSide(color: WiFenceColors.line),
        textStyle: GoogleFonts.sora(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: WiFenceColors.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: WiFenceColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: WiFenceColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: WiFenceColors.cobalt, width: 1.5),
      ),
    ),
  );
}
