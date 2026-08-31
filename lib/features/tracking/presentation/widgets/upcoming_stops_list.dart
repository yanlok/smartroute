import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/tracking_station.dart';

/// Renders the "Upcoming stops" list shown below the vehicle card.
///
/// The first row is rendered as the current stop (with a "Current"
/// pill); subsequent rows are upcoming stops with a synthetic
/// "+N min" label based on their position in the list.
///
/// Tapping any row invokes [onStationTap], allowing the parent
/// screen to navigate to the per-station arrivals view.
class UpcomingStopsList extends StatelessWidget {
  /// Ordered list of upcoming stops. The first element is treated
  /// as the current stop.
  final List<TrackingStation> stops;

  /// Invoked when the user taps a stop row.
  final ValueChanged<TrackingStation>? onStationTap;

  /// Maximum number of rows to render. Defaults to 4.
  final int maxRows;

  const UpcomingStopsList({
    super.key,
    required this.stops,
    this.onStationTap,
    this.maxRows = 4,
  });

  @override
  Widget build(BuildContext context) {
    if (stops.isEmpty) {
      return const SizedBox.shrink();
    }
    final visible = stops.take(maxRows).toList();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          for (var i = 0; i < visible.length; i++)
            _StopRow(
              station: visible[i],
              isCurrent: i == 0,
              syntheticEtaMinutes: i * 3,
              isLast: i == visible.length - 1,
              onTap: onStationTap == null
                  ? null
                  : () => onStationTap!(visible[i]),
            ),
        ],
      ),
    );
  }
}

class _StopRow extends StatelessWidget {
  final TrackingStation station;
  final bool isCurrent;
  final int syntheticEtaMinutes;
  final bool isLast;
  final VoidCallback? onTap;

  const _StopRow({
    required this.station,
    required this.isCurrent,
    required this.syntheticEtaMinutes,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.cardPadding,
            vertical: AppSpacing.xl,
          ),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : const Border(
                    bottom: BorderSide(color: AppColors.borderLight),
                  ),
          ),
          child: Row(
            children: [
              Container(
                width: AppSpacing.dotMedium,
                height: AppSpacing.dotMedium,
                decoration: BoxDecoration(
                  color: isCurrent ? AppColors.primary : AppColors.iconGray,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        station.name,
                        style: isCurrent
                            ? AppTypography.bodyLarge
                            : AppTypography.labelMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(
                            AppRadius.circular,
                          ),
                        ),
                        child: Text(
                          'Current',
                          style: AppTypography.captionBold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!isCurrent)
                Text(
                  '+$syntheticEtaMinutes min',
                  style: AppTypography.labelSmallBold.copyWith(
                    color: AppColors.iconGray,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
