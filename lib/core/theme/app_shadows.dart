import 'package:flutter/material.dart';

class AppShadows {
  AppShadows._();

  static List<BoxShadow> get card => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get cardMd => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get cardLg => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get primaryButton => [
    BoxShadow(
      color: const Color(0xFFE31837).withValues(alpha: 0.42),
      blurRadius: 24,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get ctaButton => [
    BoxShadow(
      color: const Color(0xFFE31837).withValues(alpha: 0.38),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get trackButton => [
    BoxShadow(
      color: const Color(0xFFE31837).withValues(alpha: 0.35),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get loginCard => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.25),
      blurRadius: 25,
      offset: const Offset(0, 0),
    ),
  ];

  static List<BoxShadow> get header => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get panel => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, -4),
    ),
  ];

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
