import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/arrival_estimate.dart';
import 'line_badge.dart';

class CountdownTile extends StatelessWidget {
  final ArrivalEstimate arrival;
  final String lineCode;

  const CountdownTile({
    super.key,
    required this.arrival,
    required this.lineCode,
  });

  @override
  Widget build(BuildContext context) {
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
          LineBadge(
            code: lineCode,
            colorToken: _tokenForLineId(arrival.lineId),
          ),
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(arrival.platformCode, style: AppTypography.bodyLarge),
                const SizedBox(height: 2),
                Text(
                  arrival.vehicleId,
                  style: AppTypography.labelMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${arrival.etaMinutes} min',
                style: AppTypography.monoMedium,
              ),
              const SizedBox(height: 2),
              const _SimulatedPill(),
            ],
          ),
        ],
      ),
    );
  }

  String _tokenForLineId(String lineId) {
    switch (lineId) {
      case 'kj':
        return 'kjLine';
      case 'ag':
      case 'ph':
        return 'spLine';
      case 'kgl':
        return 'mkLine';
      case 'pyl':
        return 'mpLine';
      case 'mr':
        return 'mlLine';
      case 'brt':
        return 'brLine';
      case 'sa':
        return 'kjLine';
      default:
        return 'kjLine';
    }
  }
}

class _SimulatedPill extends StatelessWidget {
  const _SimulatedPill();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Simulated arrival — not real-time data.',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.amberBg,
          borderRadius: BorderRadius.circular(AppRadius.circular),
        ),
        child: Text(
          'SIM',
          style: AppTypography.captionBold.copyWith(color: AppColors.amber),
        ),
      ),
    );
  }
}
