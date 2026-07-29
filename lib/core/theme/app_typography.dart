import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized typography tokens extracted from the React SmartRoute application.
///
/// Font families: Plus Jakarta Sans (primary), DM Mono (monospace for numbers).
class AppTypography {
  AppTypography._();

  // ── Helper ────────────────────────────────────────────────────────────────

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

  // ── Display / Headings ────────────────────────────────────────────────────

  /// 30px black — large savings amounts
  static TextStyle get displayLarge => _monoStyle(
        fontSize: 30,
        fontWeight: FontWeight.w900,
      );

  /// 24px black — login tagline
  static TextStyle get headlineLarge => _jakartaStyle(
        fontSize: 24,
        fontWeight: FontWeight.w900,
        height: 1.25,
      );

  /// 20px black — greeting name
  static TextStyle get headlineMedium => _jakartaStyle(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
      );

  /// 18px black — profile name
  static TextStyle get headlineSmall => _jakartaStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        height: 1.0,
      );

  // ── Titles ────────────────────────────────────────────────────────────────

  /// 15px black — section titles ("Service Status", "Favourite Routes")
  static TextStyle get titleLarge => _jakartaStyle(
        fontSize: 15,
        fontWeight: FontWeight.w900,
      );

  /// 15px black — page titles
  static TextStyle get titleMedium => _jakartaStyle(
        fontSize: 15,
        fontWeight: FontWeight.w900,
      );

  // ── Body Text ─────────────────────────────────────────────────────────────

  /// 14px semibold/bold — card titles, button text, input text
  static TextStyle get bodyLarge => _jakartaStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
      );

  /// 14px medium — body text
  static TextStyle get bodyMedium => _jakartaStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      );

  /// 12px bold — labels
  static TextStyle get bodySmall => _jakartaStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
      );

  // ── Small / Caption ───────────────────────────────────────────────────────

  /// 11px semibold — secondary descriptions, meta info
  static TextStyle get labelLarge => _jakartaStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
      );

  /// 11px medium — secondary text
  static TextStyle get labelMedium => _jakartaStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
      );

  /// 11px bold — small emphasized
  static TextStyle get labelSmallBold => _jakartaStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
      );

  /// 10px black — uppercase section labels
  static TextStyle get captionBlack => _jakartaStyle(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
      );

  /// 10px bold — small labels, chips
  static TextStyle get captionBold => _jakartaStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
      );

  /// 10px medium — meta info
  static TextStyle get captionMedium => _jakartaStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
      );

  /// 8px black — badge counts
  static TextStyle get overline => _jakartaStyle(
        fontSize: 8,
        fontWeight: FontWeight.w900,
      );

  // ── Mono (number/pricing specific) ────────────────────────────────────────

  /// 20px black mono — route detail values
  static TextStyle get monoLarge => _monoStyle(
        fontSize: 20,
        fontWeight: FontWeight.w900,
      );

  /// 14px black mono — card prices
  static TextStyle get monoMedium => _monoStyle(
        fontSize: 14,
        fontWeight: FontWeight.w900,
      );

  /// 11px bold mono — time estimates
  static TextStyle get monoSmallBold => _monoStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
      );

  // ── Special ───────────────────────────────────────────────────────────────

  /// 18px black — logo text
  static TextStyle get logo => _jakartaStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
        height: 1.0,
      );

  /// 10px tracking-wide — logo subtitle
  static TextStyle get logoSubtitle => _jakartaStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 2.0,
      );

  /// 14px semibold white — header greeting label
  static TextStyle get headerLabel => _jakartaStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      );

  /// 13px medium — body descriptions
  static TextStyle get description => _jakartaStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
      );
}
