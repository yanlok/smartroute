import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/transit_line.dart';
import 'line_badge.dart';

class LinePickerTile extends StatelessWidget {
  final TransitLine line;
  final int stationCount;
  final String statusLabel;
  final Color statusColor;
  final Color statusBackground;
  final VoidCallback onTap;

  const LinePickerTile({
    super.key,
    required this.line,
    required this.stationCount,
    required this.statusLabel,
    required this.statusColor,
    required this.statusBackground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: [
              LineBadge(code: line.code, colorToken: line.colorToken),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(line.name, style: AppTypography.bodyLarge),
                    const SizedBox(height: 2),
                    Text(
                      '$stationCount stations',
                      style: AppTypography.labelMedium,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: statusBackground,
                  borderRadius: BorderRadius.circular(AppRadius.circular),
                ),
                child: Text(
                  statusLabel,
                  style: AppTypography.captionBold.copyWith(color: statusColor),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.iconGray,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
