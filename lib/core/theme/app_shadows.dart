import 'package:flutter/material.dart';

/// Centralized shadow/elevation tokens extracted from the React SmartRoute application.
class AppShadows {
  AppShadows._();

  // ── Card Shadows ──────────────────────────────────────────────────────────

  /// Standard card shadow — subtle elevation
  static List<BoxShadow> get card => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  /// Card shadow with slightly more elevation
  static List<BoxShadow> get cardMd => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  /// Elevated card shadow
  static List<BoxShadow> get cardLg => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  // ── Button Shadows ────────────────────────────────────────────────────────

  /// Primary red button shadow
  static List<BoxShadow> get primaryButton => [
        BoxShadow(
          color: const Color(0xFFE31837).withValues(alpha: 0.42),
          blurRadius: 24,
          offset: const Offset(0, 6),
        ),
      ];

  /// Secondary CTA button shadow ("Find Best Routes")
  static List<BoxShadow> get ctaButton => [
        BoxShadow(
          color: const Color(0xFFE31837).withValues(alpha: 0.38),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];

  /// Track live button shadow
  static List<BoxShadow> get trackButton => [
        BoxShadow(
          color: const Color(0xFFE31837).withValues(alpha: 0.35),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  /// Login card shadow (shadow-2xl)
  static List<BoxShadow> get loginCard => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 25,
          offset: const Offset(0, 0),
        ),
      ];

  // ── Header / Surface ──────────────────────────────────────────────────────

  /// Screen header shadow
  static List<BoxShadow> get header => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  /// Station info panel shadow
  static List<BoxShadow> get panel => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, -4),
        ),
      ];

  // ── Phone Shell (Desktop) ─────────────────────────────────────────────────

  static List<BoxShadow> get phoneShell => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.32),
          blurRadius: 100,
          offset: const Offset(0, 40),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 0,
          offset: const Offset(0, 0),
          spreadRadius: 1.5,
        ),
      ];
}
