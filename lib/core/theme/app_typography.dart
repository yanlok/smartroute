import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static TextStyle _jakartaStyle({
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
    Color? color,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: height,
      color: color,
    );
  }

  static TextStyle _monoStyle({
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
    Color? color,
  }) {
    return GoogleFonts.dmMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: height,
      color: color,
    );
  }

  static TextStyle get displayLarge =>
      _monoStyle(fontSize: 30, fontWeight: FontWeight.w900);

  static TextStyle get headlineLarge =>
      _jakartaStyle(fontSize: 24, fontWeight: FontWeight.w900, height: 1.25);

  static TextStyle get headlineMedium => _jakartaStyle(
    fontSize: 20,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.5,
  );

  static TextStyle get headlineSmall =>
      _jakartaStyle(fontSize: 18, fontWeight: FontWeight.w900, height: 1.0);

  static TextStyle get titleLarge =>
      _jakartaStyle(fontSize: 15, fontWeight: FontWeight.w900);

  static TextStyle get titleMedium =>
      _jakartaStyle(fontSize: 15, fontWeight: FontWeight.w900);

  static TextStyle get bodyLarge =>
      _jakartaStyle(fontSize: 14, fontWeight: FontWeight.w700);

  static TextStyle get bodyMedium =>
      _jakartaStyle(fontSize: 14, fontWeight: FontWeight.w500);

  static TextStyle get bodySmall =>
      _jakartaStyle(fontSize: 12, fontWeight: FontWeight.w700);

  static TextStyle get labelLarge =>
      _jakartaStyle(fontSize: 11, fontWeight: FontWeight.w600);

  static TextStyle get labelMedium =>
      _jakartaStyle(fontSize: 11, fontWeight: FontWeight.w500);

  static TextStyle get labelSmallBold =>
      _jakartaStyle(fontSize: 11, fontWeight: FontWeight.w700);

  static TextStyle get captionBlack => _jakartaStyle(
    fontSize: 10,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.2,
  );

  static TextStyle get captionBold =>
      _jakartaStyle(fontSize: 10, fontWeight: FontWeight.w700);

  static TextStyle get captionMedium =>
      _jakartaStyle(fontSize: 10, fontWeight: FontWeight.w500);

  static TextStyle get overline =>
      _jakartaStyle(fontSize: 8, fontWeight: FontWeight.w900);

  static TextStyle get monoLarge =>
      _monoStyle(fontSize: 20, fontWeight: FontWeight.w900);

  static TextStyle get monoMedium =>
      _monoStyle(fontSize: 14, fontWeight: FontWeight.w900);

  static TextStyle get monoSmallBold =>
      _monoStyle(fontSize: 11, fontWeight: FontWeight.w700);

  static TextStyle get logo => _jakartaStyle(
    fontSize: 18,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.5,
    height: 1.0,
  );

  static TextStyle get logoSubtitle => _jakartaStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 2.0,
  );

  static TextStyle get headerLabel =>
      _jakartaStyle(fontSize: 14, fontWeight: FontWeight.w600);

  static TextStyle get description =>
      _jakartaStyle(fontSize: 13, fontWeight: FontWeight.w500);
}
