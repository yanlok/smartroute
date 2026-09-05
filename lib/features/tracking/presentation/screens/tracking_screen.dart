import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/transit_presentation.dart';
import '../../../../shared/models/journey_models.dart';
import '../../../../shared/models/transit_models.dart';
import '../../../../shared/widgets/app_page_header.dart';
import '../../../../shared/widgets/transit_google_map.dart';
import '../../application/tracking_controller.dart';
import '../../domain/models/live_vehicle.dart';

class TrackingScreen extends StatefulWidget {
  final String lineId;
  final TrackingController controller;
  final TransitNetwork network;
  final JourneyOption? journey;
  final VoidCallback onBack;

  const TrackingScreen({
    super.key,
    required this.lineId,
    required this.controller,
    required this.network,
    required this.onBack,
    this.journey,
  });

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.selectLine(widget.lineId);
  }

  @override
  void didUpdateWidget(covariant TrackingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lineId != widget.lineId ||
        oldWidget.controller != widget.controller) {
      widget.controller.selectLine(widget.lineId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final route = widget.network.routesById[widget.lineId];
        if (route == null) {
          return Column(
            children: [
              AppPageHeader(title: 'Journey progress', onBack: widget.onBack),
              const Expanded(child: Center(child: Text('Route not found.'))),
            ],
          );
        }
        final vehicles = widget.controller.vehicles
            .where((vehicle) => vehicle.isLive)
            .toList();
        final live = vehicles.isNotEmpty;
        final pattern = _pattern(route);
        final nextDeparture = pattern == null ? null : _nextDeparture(pattern);
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              AppPageHeader(
                title: route.displayName,
                subtitle: route.mode.label,
                onBack: widget.onBack,
                action: _TruthBadge(live: live),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: widget.controller.retry,
                  color: AppColors.primary,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pageHorizontal,
                      AppSpacing.sectionLg,
                      AppSpacing.pageHorizontal,
                      AppSpacing.pageBottom,
                    ),
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          boxShadow: AppShadows.card,
                        ),
                        child: _map(route, pattern, vehicles),
                      ),
                      const SizedBox(height: AppSpacing.sectionLg),
                      if (widget.controller.isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: AppSpacing.gapLg,
                          ),
                          child: LinearProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
                      else if (live)
                        _LiveSummary(vehicles: vehicles)
                      else
                        _ScheduledSummary(
                          route: route,
                          nextDeparture: nextDeparture,
                          journey: widget.journey,
                          providerTemporarilyUnavailable:
                              widget.controller.errorMessage != null,
                        ),
                      const SizedBox(height: AppSpacing.sectionXl),
                      Text(
                        'STATION / STOP SEQUENCE',
                        style: AppTypography.captionBlack.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.gapMd),
                      if (pattern == null || pattern.stopIds.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(AppSpacing.sectionLg),
                          child: Text(
                            'No stop sequence is available for this route.',
                          ),
                        )
                      else
                        for (
                          var index = 0;
                          index < pattern.stopIds.length;
                          index++
                        )
                          if (widget.network.stopsById[pattern.stopIds[index]]
                              case final stop?)
                            _StopRow(
                              index: index,
                              totalStops: pattern.stopIds.length,
                              stop: stop,
                              route: route,
                              active: _isJourneyStop(stop.id),
                              isOrigin: _isJourneyOrigin(stop.id, index),
                              isDestination: _isJourneyDestination(
                                stop.id,
                                index,
                                pattern.stopIds.length,
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _map(
    TransitRoute route,
    TransitPattern? pattern,
    List<LiveVehicle> vehicles,
  ) {
    final stopIds = pattern?.stopIds ?? const <String>[];
    return TransitGoogleMap(
      markers: [
        for (var i = 0; i < stopIds.length; i++)
          if (widget.network.stopsById[stopIds[i]] case final stop?)
            TransitMapMarker(
              id: stop.id,
              label: TransitPresentation.formatStopName(stop.name),
              coordinate: stop.coordinate,
              kind: i == 0
                  ? TransitMapMarkerKind.origin
                  : (i == stopIds.length - 1
                        ? TransitMapMarkerKind.destination
                        : TransitMapMarkerKind.stop),
            ),
        for (final vehicle in vehicles)
          if (vehicle.latitude != null && vehicle.longitude != null)
            TransitMapMarker(
              id: 'vehicle-${vehicle.vehicleId}',
              label:
                  'Live vehicle ${vehicle.label ?? vehicle.vehicleId} · updated ${TimeOfDay.fromDateTime(vehicle.lastUpdated.toLocal()).format(context)}',
              coordinate: TransitCoordinate(
                vehicle.latitude!,
                vehicle.longitude!,
              ),
              kind: TransitMapMarkerKind.vehicle,
            ),
      ],
      lines: [
        TransitMapLine(
          id: route.id,
          color: TransitPresentation.routeColor(route),
          points: route.shape,
        ),
      ],
      initialCenter: route.shape.firstOrNull,
      height: 260,
    );
  }

  TransitPattern? _pattern(TransitRoute route) {
    final journey = widget.journey;
    if (journey != null) {
      for (final segment in journey.segments) {
        if (segment.routeId == route.id) {
          return widget.network.patternForRouteAndStop(
            route.id,
            segment.fromStopId,
          );
        }
      }
    }
    return widget.network.patterns
        .where((pattern) => pattern.routeId == route.id)
        .firstOrNull;
  }

  DateTime? _nextDeparture(TransitPattern pattern) {
    final journey = widget.journey;
    if (journey != null) {
      for (final segment in journey.segments) {
        if (segment.routeId == widget.lineId) {
          return pattern.nextDeparture(segment.fromStopId, DateTime.now());
        }
      }
    }
    return pattern.stopIds.isEmpty
        ? null
        : pattern.nextDeparture(pattern.stopIds.first, DateTime.now());
  }

  bool _isJourneyStop(String stopId) {
    final journey = widget.journey;
    if (journey == null) return false;
    return journey.segments.any(
      (segment) =>
          segment.routeId == widget.lineId && segment.stopIds.contains(stopId),
    );
  }

  bool _isJourneyOrigin(String stopId, int index) {
    final journey = widget.journey;
    if (journey == null) return index == 0;
    return journey.segments.any(
      (segment) =>
          segment.routeId == widget.lineId && segment.fromStopId == stopId,
    );
  }

  bool _isJourneyDestination(String stopId, int index, int total) {
    final journey = widget.journey;
    if (journey == null) return index == total - 1;
    return journey.segments.any(
      (segment) =>
          segment.routeId == widget.lineId && segment.toStopId == stopId,
    );
  }
}

class _TruthBadge extends StatelessWidget {
  final bool live;

  const _TruthBadge({required this.live});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.gapMd,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: live ? AppColors.greenLiveBg : AppColors.secondaryLight,
      borderRadius: BorderRadius.circular(AppRadius.circular),
    ),
    child: Text(
      live ? 'LIVE' : 'SCHEDULED',
      style: AppTypography.captionBold.copyWith(
        color: live ? AppColors.greenLive : AppColors.secondary,
        letterSpacing: 0.5,
      ),
    ),
  );
}

class _LiveSummary extends StatelessWidget {
  final List<LiveVehicle> vehicles;

  const _LiveSummary({required this.vehicles});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.cardPadding),
    decoration: BoxDecoration(
      color: AppColors.greenLiveBg,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: AppColors.greenLiveBorder),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: const BoxDecoration(
            color: AppColors.greenLive,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.sensors_rounded,
            color: Colors.white,
            size: 16,
          ),
        ),
        const SizedBox(width: AppSpacing.gapMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${vehicles.length} official vehicle position${vehicles.length == 1 ? '' : 's'}',
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Updated ${TimeOfDay.fromDateTime(vehicles.first.lastUpdated.toLocal()).format(context)} · vehicle arrival predictions are not supplied by this official feed.',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ScheduledSummary extends StatelessWidget {
  final TransitRoute route;
  final DateTime? nextDeparture;
  final JourneyOption? journey;
  final bool providerTemporarilyUnavailable;

  const _ScheduledSummary({
    required this.route,
    required this.nextDeparture,
    required this.journey,
    required this.providerTemporarilyUnavailable,
  });

  @override
  Widget build(BuildContext context) {
    JourneySegment? segment;
    for (final candidate in journey?.segments ?? const <JourneySegment>[]) {
      if (candidate.routeId == route.id) {
        segment = candidate;
        break;
      }
    }
    final expectedArrival = nextDeparture == null || segment == null
        ? null
        : nextDeparture!.add(Duration(minutes: segment.durationMinutes));
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            providerTemporarilyUnavailable
                ? 'Scheduled times shown'
                : 'Scheduled journey progress',
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sectionLg),
          Row(
            children: [
              Expanded(
                child: _ScheduleValue(
                  label: 'NEXT DEPARTURE',
                  value: nextDeparture == null
                      ? 'Check timetable'
                      : TimeOfDay.fromDateTime(
                          nextDeparture!.toLocal(),
                        ).format(context),
                ),
              ),
              Expanded(
                child: _ScheduleValue(
                  label: 'EXPECTED ARRIVAL',
                  value: expectedArrival == null
                      ? '—'
                      : TimeOfDay.fromDateTime(
                          expectedArrival.toLocal(),
                        ).format(context),
                ),
              ),
            ],
          ),
          if (segment != null) ...[
            const SizedBox(height: AppSpacing.sectionLg),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gapXl,
                vertical: AppSpacing.gapSm,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                '${segment.stopCount} stops · approximately ${segment.durationMinutes} minutes',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScheduleValue extends StatelessWidget {
  final String label;
  final String value;

  const _ScheduleValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: AppTypography.captionBlack.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        value,
        style: AppTypography.headlineSmall.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
    ],
  );
}

class _StopRow extends StatelessWidget {
  final int index;
  final int totalStops;
  final TransitStop stop;
  final TransitRoute route;
  final bool active;
  final bool isOrigin;
  final bool isDestination;

  const _StopRow({
    required this.index,
    required this.totalStops,
    required this.stop,
    required this.route,
    required this.active,
    required this.isOrigin,
    required this.isDestination,
  });

  @override
  Widget build(BuildContext context) {
    final routeColor = TransitPresentation.routeColor(route);
    final display = TransitPresentation.formatStopName(stop.name);

    String? statusSubtitle;
    if (isOrigin) {
      statusSubtitle = 'Board here';
    } else if (isDestination) {
      statusSubtitle = 'Alight here';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: active ? AppColors.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 2,
          ),
          leading: CircleAvatar(
            radius: active || isOrigin || isDestination ? 14 : 11,
            backgroundColor: isOrigin
                ? AppColors.statusOnTime
                : (isDestination
                      ? AppColors.primary
                      : (active ? routeColor : AppColors.mutedBg)),
            child: Text(
              '${index + 1}',
              style: AppTypography.captionBold.copyWith(
                color: isOrigin || isDestination || active
                    ? Colors.white
                    : AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ),
          title: Text(
            display,
            style: AppTypography.bodyLarge.copyWith(
              fontWeight: isOrigin || isDestination || active
                  ? FontWeight.w800
                  : FontWeight.w500,
              color: isOrigin || isDestination || active
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
          subtitle: statusSubtitle != null
              ? Text(
                  statusSubtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: isOrigin
                        ? AppColors.statusOnTimeText
                        : AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : (stop.routeIds.length > 1
                    ? Text(
                        'Interchange · ${stop.routeIds.length} routes',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      )
                    : null),
        ),
      ),
    );
  }
}
