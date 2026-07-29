import 'package:flutter/material.dart';

/// Centralized color tokens extracted from the React SmartRoute application.
///
/// Never use `Color(0xFF...)` directly in widgets — always reference AppColors.
class AppColors {
  AppColors._();

  // ── Brand Colors ──────────────────────────────────────────────────────────

  /// Primary brand red — buttons, gradients, links, active states
  static const Color primary = Color(0xFFE31837);

  /// Darker red for gradient ends
  static const Color primaryDark = Color(0xFFC41030);

  /// Deep red for gradient accents
  static const Color primaryDeep = Color(0xFF8B0000);

  /// Secondary blue — info cards, links, alternate actions
  static const Color secondary = Color(0xFF1B4FD8);

  /// Secondary blue light — tinted backgrounds
  static const Color secondaryLight = Color(0xFFEBF0FF);

  /// Primary red light — tinted backgrounds
  static const Color primaryLight = Color(0xFFFFF0F2);

  // ── Transport Line Colors ─────────────────────────────────────────────────

  static const Color kjLine = Color(0xFF009FE3);
  static const Color spLine = Color(0xFF00A550);
  static const Color mkLine = Color(0xFF003087);
  static const Color mpLine = Color(0xFF8B0000);
  static const Color mlLine = Color(0xFF7C3AED);
  static const Color brLine = Color(0xFFF59E0B);
  static const Color busLine = Color(0xFFF59E0B);

  // ── Status Colors ─────────────────────────────────────────────────────────

  static const Color statusOnTime = Color(0xFF22C55E);
  static const Color statusMinorDelay = Color(0xFFF59E0B);
  static const Color statusMajorDelay = Color(0xFFEF4444);
  static const Color statusSuspended = Color(0xFFB91C1C);

  static const Color statusOnTimeBg = Color(0xFFF0FDF4);
  static const Color statusOnTimeText = Color(0xFF15803D);
  static const Color statusMinorDelayBg = Color(0xFFFFFBEB);
  static const Color statusMinorDelayText = Color(0xFFB45309);
  static const Color statusMajorDelayBg = Color(0xFFFEF2F2);
  static const Color statusMajorDelayText = Color(0xFFB91C1C);
  static const Color statusSuspendedBg = Color(0xFFFEE2E2);
  static const Color statusSuspendedText = Color(0xFF991B1B);

  // ── Severity Colors ───────────────────────────────────────────────────────

  static const Color severityInfoBg = Color(0xFFEFF6FF);
  static const Color severityInfoColor = Color(0xFF1D4ED8);
  static const Color severityWarningBg = Color(0xFFFFFBEB);
  static const Color severityWarningColor = Color(0xFFD97706);
  static const Color severityCriticalBg = Color(0xFFFEF2F2);
  static const Color severityCriticalColor = Color(0xFFDC2626);

  // ── UI Colors ─────────────────────────────────────────────────────────────

  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF0F1419);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textPlaceholder = Color(0xFF9CA3AF);

  static const Color mutedBg = Color(0xFFF3F4F6);
  static const Color mutedForeground = Color(0xFF6B7280);

  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);

  static const Color inputBg = Color(0xFFF9FAFB);
  static const Color inputBorder = Color(0xFFE5E7EB);

  static const Color success = Color(0xFF16A34A);
  static const Color successBg = Color(0xFFF0FDF4);

  static const Color amberBg = Color(0xFFFFFBEB);
  static const Color amber = Color(0xFFD97706);

  static const Color iconGray = Color(0xFF9CA3AF);
  static const Color iconDark = Color(0xFF6B7280);

  static const Color tabActive = Color(0xFFE31837);
  static const Color tabInactive = Color(0xFF9CA3AF);
  static const Color tabActiveBg = Color(0x1AE31837);

  // ── Gradient Lists ────────────────────────────────────────────────────────

  /// Primary header/button gradient (red)
  static const List<Color> gradientPrimary = [
    Color(0xFFE31837),
    Color(0xFFC41030),
  ];

  /// Full header gradient with deep accent
  static const List<Color> gradientHeader = [
    Color(0xFFE31837),
    Color(0xFFC41030),
    Color(0xFF8B0000),
  ];

  /// Secondary blue gradient (savings card)
  static const List<Color> gradientBlue = [
    Color(0xFF1B4FD8),
    Color(0xFF4338CA),
  ];

  /// Profile card gradient
  static const List<Color> gradientProfile = [
    Color(0xFFE31837),
    Color(0xFF8B0000),
  ];

  // ── Misc ──────────────────────────────────────────────────────────────────

  static const Color divider = Color(0xFFE5E7EB);
  static const Color shimmerBase = Color(0xFFE8EBF0);
  static const Color white10 = Color(0x1AFFFFFF);
  static const Color white15 = Color(0x26FFFFFF);
  static const Color white20 = Color(0x33FFFFFF);
  static const Color white25 = Color(0x40FFFFFF);
  static const Color white55 = Color(0x8CFFFFFF);
  static const Color white65 = Color(0xA6FFFFFF);
  static const Color greenLive = Color(0xFF22C55E);
  static const Color greenLiveBg = Color(0xFFF0FDF4);
  static const Color greenLiveBorder = Color(0xFFBBF7D0);
  static const Color yellowBadge = Color(0xFFFBBF24);
  static const Color amber100 = Color(0xFFFEF3C7);
  static const Color amber600 = Color(0xFFD97706);
  static const Color desktopBg1 = Color(0xFFE8EBF0);
  static const Color desktopBg2 = Color(0xFFC9D6E8);
  static const Color desktopBg3 = Color(0xFFD8DCE6);
}
