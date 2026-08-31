import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import 'transit_line_color_resolver.dart';

/// Coloured chip that identifies a transit line. Used in headers,
/// vehicle cards, station lists, etc.
///
/// The chip is sized to fit its [code] (e.g. `"KJ"`, `"MRT-K"`)
/// and is rendered in the line's brand colour via
/// [TransitLineColorResolver].
class LineBadge extends StatelessWidget {
  /// The line's user-facing code, e.g. `"KJ"`, `"MRT-K"`.
  final String code;

  /// The line's `colorToken` (e.g. `"kjLine"`).
  final String colorToken;

  /// Optional override of the chip's foreground colour. Defaults
  /// to white, which is readable on every brand colour.
  final Color? foreground;

  const LineBadge({
    super.key,
    required this.code,
    required this.colorToken,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: TransitLineColorResolver.resolve(colorToken),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        code,
        style: AppTypography.captionBold.copyWith(
          color: foreground ?? Colors.white,
        ),
      ),
    );
  }
}
