import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_typography.dart';
import 'transit_line_color_resolver.dart';

class LineBadge extends StatelessWidget {
  final String code;

  final String colorToken;

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
