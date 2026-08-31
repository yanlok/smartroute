import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/live_vehicle.dart';
import 'line_badge.dart';
import 'transit_line_color_resolver.dart';

/// Renders the "current vehicle" card at the top of the tracking
/// screen: icon, line badge, vehicle id, platform, ETA.
///
/// This widget is presentation-only; it consumes a [LiveVehicle]
/// snapshot and a [lineCode] / [colorToken] from the parent.
class VehicleInfoCard extends StatelessWidget {
  final LiveVehicle vehicle;
  final String lineCode;
  final String colorToken;

  const VehicleInfoCard({
    super.key,
    required this.vehicle,
    required this.lineCode,
    required this.colorToken,
  });

  @override
  Widget build(BuildContext context) {
    final accent = TransitLineColorResolver.resolve(colorToken);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.iconContainer),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(Icons.train_rounded, color: accent, size: 20),
          ),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    LineBadge(code: lineCode, colorToken: colorToken),
                    const SizedBox(width: AppSpacing.md),
                    Flexible(
                      child: Text(
                        'Train ${vehicle.vehicleId}',
                        style: AppTypography.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Platform ${(vehicle.vehicleId.hashCode.abs() % 4) + 1} '
                  '· Towards ${vehicle.direction.name}',
                  style: AppTypography.labelMedium,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('ETA', style: AppTypography.captionMedium),
              Text(
                '${vehicle.etaMinutes}m',
                style: AppTypography.monoLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
