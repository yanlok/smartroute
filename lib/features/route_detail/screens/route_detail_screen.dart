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
                    enableInteractionControls: true,
                    height: 210,
                  ),
                  const SizedBox(height: AppSpacing.sectionLg),
                  _Summary(journey: journey),
                  const SizedBox(height: AppSpacing.sectionXl),
                  Text('JOURNEY STEPS', style: AppTypography.captionBlack),
                  const SizedBox(height: AppSpacing.gapMd),
                  _JourneyTimeline(
                    segments: journey.segments,
                    network: network,
                    notices: notices,
                    onOpenTransit: onOpenTransit,
                    onOpenProgress: onOpenProgress,
                  ),
                  if (savedJourneys.errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.gapMd),
                    Text(
                      savedJourneys.errorMessage!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
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
    padding: const EdgeInsets.all(AppSpacing.containerPadding),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: AppColors.borderLight),
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

class _JourneyTimeline extends StatelessWidget {
  final List<JourneySegment> segments;
  final TransitNetwork network;
  final NoticeController notices;
  final ValueChanged<String> onOpenTransit;
  final ValueChanged<String> onOpenProgress;

  const _JourneyTimeline({
    required this.segments,
    required this.network,
    required this.notices,
    required this.onOpenTransit,
    required this.onOpenProgress,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: AppColors.border),
      boxShadow: AppShadows.card,
    ),
    child: Stack(
      children: [
        if (segments.length > 1)
          Positioned(
            left: 31,
            top: 46,
            bottom: 46,
            child: Container(width: 2, color: AppColors.border),
          ),
        Column(
          children: [
            for (var index = 0; index < segments.length; index++) ...[
              Padding(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                child: _JourneyTimelineStep(
                  segment: segments[index],
                  network: network,
                  notices: notices,
                  onOpenTransit: onOpenTransit,
                  onOpenProgress: onOpenProgress,
                ),
              ),
              if (index < segments.length - 1)
                const Padding(
                  padding: EdgeInsets.only(left: 48, right: AppSpacing.md),
                  child: Divider(height: 1, color: AppColors.borderLight),
                ),
            ],
          ],
        ),
      ],
    ),
  );
}

class _JourneyTimelineStep extends StatelessWidget {
  final JourneySegment segment;
  final TransitNetwork network;
  final NoticeController notices;
  final ValueChanged<String> onOpenTransit;
  final ValueChanged<String> onOpenProgress;

  const _JourneyTimelineStep({
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TimelineMarker(route: route),
        const SizedBox(width: AppSpacing.gapXl),
        Expanded(
          child: route == null
              ? _WalkingStep(to: to, segment: segment)
              : _TransitStep(
                  route: route,
                  segment: segment,
                  from: from,
                  to: to,
                  pattern: pattern,
                  departure: departure,
                  noticeTitle: activeNotices.isEmpty
                      ? null
                      : activeNotices.first.title,
                  onOpenTransit: onOpenTransit,
                  onOpenProgress: onOpenProgress,
                ),
        ),
      ],
    );
  }
}

class _TimelineMarker extends StatelessWidget {
  final TransitRoute? route;

  const _TimelineMarker({required this.route});

  @override
  Widget build(BuildContext context) {
    final isWalking = route == null;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isWalking
            ? AppColors.mutedBg
            : TransitPresentation.routeColor(route!),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surface, width: 3),
      ),
      child: Icon(
        isWalking
            ? Icons.directions_walk_rounded
            : TransitPresentation.modeIcon(route!.mode),
        size: 16,
        color: isWalking ? AppColors.textSecondary : AppColors.surface,
      ),
    );
  }
}

class _WalkingStep extends StatelessWidget {
  final TransitStop? to;
  final JourneySegment segment;

  const _WalkingStep({required this.to, required this.segment});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(child: Text('Walk', style: AppTypography.bodyLarge)),
          Text(
            '${segment.durationMinutes} min',
            style: AppTypography.labelLarge,
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        '${segment.walkingMetres} m transfer',
        style: AppTypography.labelMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      const SizedBox(height: AppSpacing.gapMd),
      Text(
        'Continue to ${TransitPresentation.formatStopName(to?.name ?? segment.toStopId)}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
      ),
    ],
  );
}

class _TransitStep extends StatelessWidget {
  final TransitRoute route;
  final JourneySegment segment;
  final TransitStop? from;
  final TransitStop? to;
  final TransitPattern? pattern;
  final DateTime? departure;
  final String? noticeTitle;
  final ValueChanged<String> onOpenTransit;
  final ValueChanged<String> onOpenProgress;

  const _TransitStep({
    required this.route,
    required this.segment,
    required this.from,
    required this.to,
    required this.pattern,
    required this.departure,
    required this.noticeTitle,
    required this.onOpenTransit,
    required this.onOpenProgress,
  });

  bool get _isBus =>
      route.mode == TransitMode.bus || route.mode == TransitMode.brt;

  String get _trackingLabel => switch (route.mode) {
    TransitMode.bus => 'Track bus',
    TransitMode.brt => 'Track BRT',
    _ => 'View progress',
  };

  @override
  Widget build(BuildContext context) {
    final destination = TransitPresentation.formatStopName(
      to?.name ?? segment.toStopId,
    );
    final direction = pattern?.headsign.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    route.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    route.shortName.isEmpty
                        ? route.mode.label.toUpperCase()
                        : '${route.shortName} · ${route.mode.label.toUpperCase()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.captionBold.copyWith(
                      color: TransitPresentation.routeColor(route),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.gapMd),
            Text(
              '${segment.durationMinutes} min',
              style: AppTypography.labelLarge,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.gapMd),
        _StopInstruction(
          label: 'BOARD',
          stopName: TransitPresentation.formatStopName(
            from?.name ?? segment.fromStopId,
          ),
          color: AppColors.statusOnTime,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${segment.stopCount} stops · Towards ${direction?.isNotEmpty == true ? direction : destination}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        _StopInstruction(
          label: 'ALIGHT',
          stopName: destination,
          color: AppColors.primary,
        ),
        if (departure != null) ...[
          const SizedBox(height: AppSpacing.gapMd),
          _DetailPill(
            icon: Icons.schedule_rounded,
            label:
                'Scheduled ${TimeOfDay.fromDateTime(departure!).format(context)}',
            color: AppColors.secondary,
          ),
        ],
        if (noticeTitle != null) ...[
          const SizedBox(height: AppSpacing.gapMd),
          _DetailPill(
            icon: Icons.campaign_rounded,
            label: noticeTitle!,
            color: AppColors.amber,
          ),
        ],
        const SizedBox(height: AppSpacing.gapMd),
        Wrap(
          spacing: AppSpacing.gapSm,
          runSpacing: AppSpacing.gapSm,
          children: [
            TextButton.icon(
              onPressed: () => onOpenTransit(route.id),
              icon: const Icon(Icons.route_outlined, size: 17),
              label: const Text('Line & stops'),
            ),
            OutlinedButton.icon(
              onPressed: () => onOpenProgress(route.id),
              icon: Icon(
                _isBus
                    ? Icons.directions_bus_filled_rounded
                    : Icons.timeline_rounded,
                size: 17,
              ),
              label: Text(_trackingLabel),
            ),
          ],
        ),
      ],
    );
  }
}

class _StopInstruction extends StatelessWidget {
  final String label;
  final String stopName;
  final Color color;

  const _StopInstruction({
    required this.label,
    required this.stopName,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 50,
        child: Text(
          label,
          style: AppTypography.captionBlack.copyWith(color: color),
        ),
      ),
      Expanded(
        child: Text(
          stopName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );
}

class _DetailPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _DetailPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.gapMd,
      vertical: AppSpacing.gapSm,
    ),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(AppRadius.sm),
    ),
    child: Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: AppSpacing.gapSm),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.labelLarge.copyWith(color: color),
          ),
        ),
      ],
    ),
  );
}
