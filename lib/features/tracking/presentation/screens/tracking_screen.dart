import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
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
        return Column(
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
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageHorizontal,
                    AppSpacing.sectionLg,
                    AppSpacing.pageHorizontal,
                    AppSpacing.pageBottom,
                  ),
                  children: [
                    _map(route, pattern, vehicles),
                    const SizedBox(height: AppSpacing.sectionLg),
                    if (widget.controller.isLoading)
                      const LinearProgressIndicator(color: AppColors.primary)
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
                      style: AppTypography.captionBlack,
                    ),
                    const SizedBox(height: AppSpacing.gapMd),
                    if (pattern == null || pattern.stopIds.isEmpty)
                      const Text(
                        'No stop sequence is available for this route.',
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
                            stop: stop,
                            route: route,
                            active: _isJourneyStop(stop.id),
                          ),
                  ],
                ),
              ),
            ),
          ],
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
        for (final stopId in stopIds)
          if (widget.network.stopsById[stopId] case final stop?)
            TransitMapMarker(
              id: stop.id,
              label: stop.name,
              coordinate: stop.coordinate,
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
      height: 270,
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
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${vehicles.length} official vehicle position${vehicles.length == 1 ? '' : 's'}',
          style: AppTypography.bodyLarge,
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
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            providerTemporarilyUnavailable
                ? 'Scheduled times shown'
                : 'Scheduled journey progress',
            style: AppTypography.bodyLarge,
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
            Text(
              '${segment.stopCount} stops · approximately ${segment.durationMinutes} minutes',
              style: AppTypography.labelLarge,
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
      Text(label, style: AppTypography.captionMedium),
      const SizedBox(height: AppSpacing.xs),
      Text(value, style: AppTypography.bodyLarge),
    ],
  );
}

class _StopRow extends StatelessWidget {
  final int index;
  final TransitStop stop;
  final TransitRoute route;
  final bool active;

  const _StopRow({
    required this.index,
    required this.stop,
    required this.route,
    required this.active,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: CircleAvatar(
      radius: active ? 15 : 12,
      backgroundColor: active
          ? TransitPresentation.routeColor(route)
          : AppColors.mutedBg,
      child: Text(
        '${index + 1}',
        style: AppTypography.captionBold.copyWith(
          color: active ? AppColors.surface : AppColors.textSecondary,
        ),
      ),
    ),
    title: Text(stop.name),
    subtitle: active ? const Text('Part of your selected journey') : null,
  );
}
