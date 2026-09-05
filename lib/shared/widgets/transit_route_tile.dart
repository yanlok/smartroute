import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/transit_presentation.dart';
import '../models/transit_models.dart';

class TransitRouteTile extends StatelessWidget {
  final TransitRoute route;
  final int stopCount;
  final VoidCallback onTap;

  const TransitRouteTile({
    super.key,
    required this.route,
    required this.stopCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final routeColor = TransitPresentation.routeColor(route);
    final isRail =
        route.mode == TransitMode.lrt ||
        route.mode == TransitMode.mrt ||
        route.mode == TransitMode.monorail;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.gapMd),
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          child: isRail
              ? _buildRailLayout(routeColor)
              : _buildBusLayout(routeColor),
        ),
      ),
    );
  }

  Widget _buildRailLayout(Color routeColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gapMd,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: routeColor,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    TransitPresentation.modeIcon(route.mode),
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    route.shortName.isNotEmpty
                        ? route.shortName
                        : route.mode.label,
                    style: AppTypography.captionBold.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.gapMd),
            Expanded(
              child: Text(
                route.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.gapLg),

        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: routeColor,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: routeColor.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: routeColor,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: routeColor.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: routeColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.gapMd),

        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gapMd,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.mutedBg,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                '$stopCount stations',
                style: AppTypography.captionBold.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.gapMd),
            Text(
              route.operatorName,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBusLayout(Color routeColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 56,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.gapMd),
          decoration: BoxDecoration(
            color: routeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: routeColor.withValues(alpha: 0.35)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                TransitPresentation.modeIcon(route.mode),
                size: 16,
                color: routeColor,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                route.shortName.isNotEmpty ? route.shortName : route.mode.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.captionBold.copyWith(
                  color: routeColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.gapXl),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                route.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.mutedBg,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: Text(
                      '$stopCount stops',
                      style: AppTypography.captionBold.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.gapMd),
                  Expanded(
                    child: Text(
                      route.operatorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
      ],
    );
  }
}
