import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/transit_presentation.dart';
import '../../../shared/models/journey_models.dart';
import '../../../shared/models/transit_models.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/transit_google_map.dart';
import '../../alerts/application/notice_controller.dart';
import '../../planner/application/planner_controller.dart';
import '../../user_management/application/saved_journey_controller.dart';
import '../../user_management/domain/models/saved_journey.dart';

class RouteDetailScreen extends StatelessWidget {
  final PlannerController planner;
  final SavedJourneyController savedJourneys;
  final NoticeController notices;
  final String userId;
  final bool showCurrentLocation;
  final VoidCallback onBack;
  final ValueChanged<String> onOpenTransit;
  final ValueChanged<String> onOpenProgress;

  const RouteDetailScreen({
    super.key,
    required this.planner,
    required this.savedJourneys,
    required this.notices,
    required this.userId,
    required this.showCurrentLocation,
    required this.onBack,
    required this.onOpenTransit,
    required this.onOpenProgress,
  });

  @override
  Widget build(BuildContext context) {
    final journey = planner.selectedRoute;
    final network = planner.network;
    if (journey == null || network == null) {
      return Column(
        children: [
          AppPageHeader(title: 'Route detail', onBack: onBack),
          const Expanded(child: Center(child: Text('No route selected.'))),
        ],
      );
    }
    return ListenableBuilder(
      listenable: Listenable.merge([savedJourneys, notices]),
      builder: (context, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            AppPageHeader(
              title: 'Route detail',
              subtitle: journey.objective.label,
              onBack: onBack,
              action: IconButton(
                tooltip: savedJourneys.containsJourney(journey)
                    ? 'Remove saved journey'
                    : 'Save journey',
                onPressed: savedJourneys.isSaving
                    ? null
                    : () => _toggleFavorite(journey, network),
                icon: Icon(
                  savedJourneys.containsJourney(journey)
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: AppColors.primary,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pageHorizontal,
                  AppSpacing.sectionLg,
                  AppSpacing.pageHorizontal,
                  AppSpacing.pageBottom,
                ),
                children: [
                  JourneyGoogleMap(
                    journey: journey,
                    network: network,
                    showCurrentLocation: showCurrentLocation,
                    height: 260,
                  ),
                  const SizedBox(height: AppSpacing.sectionLg),
                  _Summary(journey: journey),
                  const SizedBox(height: AppSpacing.sectionXl),
                  Text('JOURNEY STEPS', style: AppTypography.captionBlack),
                  const SizedBox(height: AppSpacing.gapMd),
                  for (
                    var index = 0;
                    index < journey.segments.length;
                    index++
                  ) ...[
                    _SegmentCard(
                      index: index,
                      segment: journey.segments[index],
                      network: network,
                      notices: notices,
                      onOpenTransit: onOpenTransit,
                      onOpenProgress: onOpenProgress,
                    ),
                    const SizedBox(height: AppSpacing.gapXl),
                  ],
                  if (savedJourneys.errorMessage != null)
                    Text(
                      savedJourneys.errorMessage!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(
    JourneyOption journey,
    TransitNetwork network,
  ) async {
    FavoriteJourney? existing;
    for (final favorite in savedJourneys.favorites) {
      if (favorite.originStopId == journey.originStopId &&
          favorite.destinationStopId == journey.destinationStopId &&
          favorite.objective == journey.objective) {
        existing = favorite;
        break;
      }
    }
    if (existing == null) {
      await savedJourneys.saveFavorite(
        userId: userId,
        journey: journey,
        network: network,
      );
    } else {
      await savedJourneys.removeFavorite(existing);
    }
  }
}

class _Summary extends StatelessWidget {
  final JourneyOption journey;

  const _Summary({required this.journey});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.cardPadding),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      boxShadow: AppShadows.card,
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _SummaryValue(value: '${journey.durationMinutes}', label: 'MINUTES'),
        _SummaryValue(value: '${journey.transferCount}', label: 'TRANSFERS'),
        _SummaryValue(value: '${journey.walkingMetres}m', label: 'WALK'),
      ],
    ),
  );
}

class _SummaryValue extends StatelessWidget {
  final String value;
  final String label;

  const _SummaryValue({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: AppTypography.monoLarge),
      Text(label, style: AppTypography.captionMedium),
    ],
  );
}

class _SegmentCard extends StatelessWidget {
  final int index;
  final JourneySegment segment;
  final TransitNetwork network;
  final NoticeController notices;
  final ValueChanged<String> onOpenTransit;
  final ValueChanged<String> onOpenProgress;

  const _SegmentCard({
    required this.index,
    required this.segment,
    required this.network,
    required this.notices,
    required this.onOpenTransit,
    required this.onOpenProgress,
  });

  @override
  Widget build(BuildContext context) {
    final from = network.stopsById[segment.fromStopId];
    final to = network.stopsById[segment.toStopId];
    final route = segment.routeId == null
        ? null
        : network.routesById[segment.routeId];
    final pattern = route == null
        ? null
        : network.patternForRouteAndStop(route.id, segment.fromStopId);
    final departure = pattern?.nextDeparture(
      segment.fromStopId,
      DateTime.now(),
    );
    final activeNotices = route == null
        ? const []
        : notices.notices
              .where(
                (notice) =>
                    notice.routeId == route.id &&
                    notice.isActiveAt(DateTime.now()),
              )
              .toList();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: route == null
                    ? AppColors.mutedBg
                    : TransitPresentation.routeColor(route),
                child: Icon(
                  route == null
                      ? Icons.directions_walk_rounded
                      : TransitPresentation.modeIcon(route.mode),
                  size: 16,
                  color: route == null
                      ? AppColors.textSecondary
                      : AppColors.surface,
                ),
              ),
              const SizedBox(width: AppSpacing.gapXl),
              Expanded(
                child: Text(
                  route == null ? 'Walk connection' : route.displayName,
                  style: AppTypography.bodyLarge,
                ),
              ),
              Text(
                '${segment.durationMinutes} min',
                style: AppTypography.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sectionLg),
          Text(
            'Board · ${TransitPresentation.formatStopName(from?.name ?? segment.fromStopId)}',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            route == null
                ? '${segment.walkingMetres} m walking transfer'
                : '${segment.stopCount} stops · Towards ${pattern?.headsign.isNotEmpty == true ? pattern!.headsign : TransitPresentation.formatStopName(to?.name ?? 'destination')}',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Alight · ${TransitPresentation.formatStopName(to?.name ?? segment.toStopId)}',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (departure != null) ...[
            const SizedBox(height: AppSpacing.gapMd),
            Text(
              'Scheduled departure · ${TimeOfDay.fromDateTime(departure).format(context)}',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.secondary,
              ),
            ),
          ],
          if (activeNotices.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.gapMd),
            Text(
              activeNotices.first.title,
              style: AppTypography.labelLarge.copyWith(color: AppColors.amber),
            ),
          ],
          if (route != null) ...[
            const Divider(height: AppSpacing.sectionXl),
            Row(
              children: [
                TextButton(
                  onPressed: () => onOpenTransit(route.id),
                  child: const Text('Line & stops'),
                ),
                const Spacer(),
                FilledButton.tonalIcon(
                  onPressed: () => onOpenProgress(route.id),
                  icon: Icon(
                    route.mode == TransitMode.bus ||
                            route.mode == TransitMode.brt
                        ? Icons.location_searching_rounded
                        : Icons.timeline_rounded,
                  ),
                  label: Text(
                    route.mode == TransitMode.bus ||
                            route.mode == TransitMode.brt
                        ? 'Track service'
                        : 'Journey progress',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
