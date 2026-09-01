import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/transit_presentation.dart';
import '../models/transit_models.dart';

class JourneyComposerRail extends StatelessWidget {
  final TransitStop? origin;
  final TransitStop? destination;
  final VoidCallback onOriginTap;
  final VoidCallback onDestinationTap;
  final VoidCallback onSwap;
  final VoidCallback? onLocation;
  final bool isLocating;

  const JourneyComposerRail({
    super.key,
    required this.origin,
    required this.destination,
    required this.onOriginTap,
    required this.onDestinationTap,
    required this.onSwap,
    this.onLocation,
    this.isLocating = false,
  });

  @override
  Widget build(BuildContext context) {
    final originText = origin == null
        ? 'Choose origin stop or station'
        : TransitPresentation.formatStopName(origin!.name);
    final destinationText = destination == null
        ? 'Choose destination'
        : TransitPresentation.formatStopName(destination!.name);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.cardPadding,
              AppSpacing.cardPadding,
              AppSpacing.cardPadding,
              AppSpacing.sm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Spatial Route Rail Graphic
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.statusOnTime,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.statusOnTime.withValues(
                              alpha: 0.35,
                            ),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 38,
                      decoration: const BoxDecoration(color: AppColors.border),
                    ),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: AppSpacing.gapXl),

                // FROM and TO selection fields
                Expanded(
                  child: Column(
                    children: [
                      // Origin Field
                      InkWell(
                        onTap: onOriginTap,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xs,
                            horizontal: AppSpacing.xs,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'FROM',
                                      style: AppTypography.captionBlack
                                          .copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      originText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: origin == null
                                          ? AppTypography.bodyMedium.copyWith(
                                              color: AppColors.textTertiary,
                                            )
                                          : AppTypography.bodyLarge.copyWith(
                                              color: AppColors.textPrimary,
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.textTertiary,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: AppSpacing.gapXl, thickness: 1),

                      // Destination Field
                      InkWell(
                        onTap: onDestinationTap,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xs,
                            horizontal: AppSpacing.xs,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'TO',
                                      style: AppTypography.captionBlack
                                          .copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      destinationText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: destination == null
                                          ? AppTypography.bodyMedium.copyWith(
                                              color: AppColors.textTertiary,
                                            )
                                          : AppTypography.bodyLarge.copyWith(
                                              color: AppColors.textPrimary,
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.textTertiary,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: AppSpacing.gapSm),

                // Swap Button
                IconButton.filledTonal(
                  tooltip: 'Swap origin and destination',
                  onPressed: onSwap,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.mutedBg,
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.all(AppSpacing.gapMd),
                  ),
                  icon: const Icon(Icons.swap_vert_rounded, size: 20),
                ),
              ],
            ),
          ),

          if (onLocation != null) ...[
            const Divider(height: 1, thickness: 1),
            InkWell(
              onTap: isLocating ? null : onLocation,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(AppRadius.lg),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.cardPadding,
                  vertical: AppSpacing.gapMd,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(AppRadius.lg),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isLocating)
                      const SizedBox.square(
                        dimension: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.secondary,
                        ),
                      )
                    else
                      const Icon(
                        Icons.my_location_rounded,
                        size: 15,
                        color: AppColors.secondary,
                      ),
                    const SizedBox(width: AppSpacing.gapSm),
                    Text(
                      isLocating ? 'Locating nearest stop…' : 'Nearby origin',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
