import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Custom Color Palette from Stitch Design System
  static const Color primaryNavy = Color(0xFF0F172A);
  static const Color actionBlue = Color(0xFF0058BE);
  static const Color backgroundLight = Color(0xFFF7F9FB);
  static const Color surfaceLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainer = Color(0xFFECEEF0);
  static const Color surfaceContainerLow = Color(0xFFF2F4F6);
  static const Color outlineGray = Color(0xFF76777D);
  static const Color outlineVariant = Color(0xFFC6C6CD);
  
  static const Color secondaryContainer = Color(0xFF2170E4);
  static const Color onSecondaryContainer = Color(0xFFFEFCFF);

  // Shared semantic accents (used across screens)
  static const Color accentBlueSoft = Color(0xFFEFF6FF);
  static const Color borderSubtle = Color(0xFFE2E8F0);
  static const Color surfaceContainerMuted = Color(0xFFF2F4F6);
  static const Color folderGold = Color(0xFF98805D);
  static const Color folderRed = Color(0xFFBA1A1A);
  
  static ThemeData get lightTheme {
    final base = ThemeData.light();
    
    return base.copyWith(
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primaryNavy,
        onPrimary: Colors.white,
        secondary: actionBlue,
        onSecondary: Colors.white,
        error: Color(0xFFBA1A1A),
        onError: Colors.white,
        surface: backgroundLight,
        onSurface: Color(0xFF191C1E),
        outline: outlineGray,
        outlineVariant: outlineVariant,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: onSecondaryContainer,
      ),
      scaffoldBackgroundColor: backgroundLight,
      
      // Typography
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 32.0,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.02,
          color: primaryNavy,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 24.0,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.01,
          color: primaryNavy,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 20.0,
          fontWeight: FontWeight.w600,
          color: primaryNavy,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 18.0,
          fontWeight: FontWeight.normal,
          color: const Color(0xFF191C1E),
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 16.0,
          fontWeight: FontWeight.normal,
          color: const Color(0xFF191C1E),
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 14.0,
          fontWeight: FontWeight.normal,
          color: const Color(0xFF45464D),
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 12.0,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.05,
          color: const Color(0xFF45464D),
        ),
      ),
      
      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: actionBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 24.0),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: actionBlue,
          side: const BorderSide(color: actionBlue, width: 1.5),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 24.0),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Input Fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLowest,
        contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: outlineVariant, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: outlineVariant, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: actionBlue, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 1.0),
        ),
        prefixIconColor: outlineGray,
        suffixIconColor: outlineGray,
        hintStyle: GoogleFonts.inter(
          color: outlineGray.withOpacity(0.6),
          fontSize: 15,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: surfaceLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
        ),
      ),
    );
  }
}
