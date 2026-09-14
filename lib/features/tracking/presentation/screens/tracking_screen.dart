import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/transit_presentation.dart';
import '../../../../shared/models/arrival_reminder.dart';
import '../../../../shared/models/journey_models.dart';
import '../../../../shared/models/transit_models.dart';
import '../../../../shared/widgets/app_page_header.dart';
import '../../../../shared/widgets/transit_google_map.dart';
import '../../application/tracking_controller.dart';
import '../../domain/models/live_vehicle.dart';
import '../../domain/services/vehicle_position_simulator.dart';

class TrackingScreen extends StatefulWidget {
  final String lineId;
  final TrackingController controller;
  final TransitNetwork network;
  final JourneyOption? journey;
  final ArrivalReminder? demoArrivalReminder;
  final VoidCallback onBack;

  const TrackingScreen({
    super.key,
    required this.lineId,
    required this.controller,
    required this.network,
    required this.onBack,
    this.journey,
    this.demoArrivalReminder,
  });

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen>
    with SingleTickerProviderStateMixin {
  // ── GPS tween animation ─────────────────────────────────────────────────
  late AnimationController _gpsAnimController;

  /// Last known coordinate per vehicleId (start of current tween).
  final Map<String, TransitCoordinate> _fromPositions = {};

  /// Target coordinate per vehicleId (end of current tween).
  final Map<String, TransitCoordinate> _toPositions = {};

  // ── Continuous moving simulation (5x speed) ─────────────────────────────
  Timer? _simTimer;
  double _simProgress = 0.0;
  List<SimulatedVehicle> _simulatedVehicles = [];

  /// Currently selected vehicle index for focused tracking (0 = LRT 1, 1 = LRT 2).
  int _selectedVehicleIndex = 0;

  /// Custom circular badge icons for vehicles (Vehicle 1 = Primary, Vehicle 2 = Indigo).
  BitmapDescriptor? _vehicleCustomIcon;
  BitmapDescriptor? _vehicle1Icon;
  BitmapDescriptor? _vehicle2Icon;

  /// When false (default), intermediate stop pointer pins are hidden so the
  /// route line and moving vehicles are clean and uncluttered.
  bool _showAllStops = false;

  @override
  void initState() {
    super.initState();
    _gpsAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addListener(_onAnimTick);

    widget.controller.addListener(_onControllerChanged);
    widget.controller.selectLine(widget.lineId);
    _loadVehicleIcons();

    // If starting on a line without live vehicles (e.g. rail), start moving simulation immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !widget.controller.hasLiveVehicles) {
        _startContinuousSimulation();
      }
    });
  }

  void _loadVehicleIcons() {
    final route = widget.network.routesById[widget.lineId];
    final isBus =
        route?.mode == TransitMode.bus || route?.mode == TransitMode.brt;
    final primaryColor = route != null
        ? TransitPresentation.routeColor(route)
        : const Color(0xFF009FE3);
    const returnColor = Color(0xFF2563EB); // Royal Indigo for Vehicle 2

    TransitVehicleIconFactory.getVehicleIcon(
      isBus: isBus,
      color: primaryColor,
      vehicleNumber: 1,
    ).then((icon) {
      if (mounted && icon != null) {
        setState(() {
          _vehicle1Icon = icon;
          _vehicleCustomIcon = icon;
        });
      }
    });

    TransitVehicleIconFactory.getVehicleIcon(
      isBus: isBus,
      color: returnColor,
      vehicleNumber: 2,
    ).then((icon) {
      if (mounted && icon != null) {
        setState(() => _vehicle2Icon = icon);
      }
    });
  }

  @override
  void didUpdateWidget(covariant TrackingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lineId != widget.lineId ||
        oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
      _resetAnimation();
      widget.controller.selectLine(widget.lineId);
      _loadVehicleIcons();
    }
  }

  @override
  void dispose() {
    _gpsAnimController.dispose();
    widget.controller.removeListener(_onControllerChanged);
    _simTimer?.cancel();
    super.dispose();
  }

  // ── Animation helpers ───────────────────────────────────────────────────

  void _onAnimTick() {
    if (mounted) setState(() {});
  }

  /// Called whenever [TrackingController] notifies. Decides whether to run
  /// GPS tween animation or continuous moving simulation based on [isLive] state.
  void _onControllerChanged() {
    if (!mounted || widget.controller.isLoading) return;

    final liveVehicles = widget.controller.vehicles
        .where((v) => v.isLive && v.latitude != null && v.longitude != null)
        .toList();

    if (liveVehicles.isNotEmpty) {
      // Live GPS data available — animate markers, stop simulation loop.
      _simTimer?.cancel();
      if (mounted) setState(() => _simulatedVehicles = []);
      _updateGpsAnimation(liveVehicles);
    } else {
      // No live data — run continuous moving simulation loop.
      _gpsAnimController.stop();
      _fromPositions.clear();
      _toPositions.clear();
      _startContinuousSimulation();
    }
  }

  void _startContinuousSimulation() {
    _simTimer?.cancel();
    _updateSimulation();
    // 100ms interval: smooth progression across station dwells (few-second stops) and inter-station travel
    // Reduced speed by 40% more (from 0.00162 to 0.00097 per 100ms tick) for calm, realistic viewing pace
    _simTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      _simProgress = (_simProgress + 0.00097) % 1.0;
      _updateSimulation();
    });
  }

  /// Diffs new vehicle positions against previous and starts a smooth tween
  /// for any vehicle whose position has changed by more than ~10 metres.
  void _updateGpsAnimation(List<LiveVehicle> newVehicles) {
    bool anyMoved = false;
    for (final v in newVehicles) {
      final newCoord = TransitCoordinate(v.latitude!, v.longitude!);
      final oldTarget = _toPositions[v.vehicleId];
      final moved =
          oldTarget == null ||
          (oldTarget.latitude - newCoord.latitude).abs() > 0.0001 ||
          (oldTarget.longitude - newCoord.longitude).abs() > 0.0001;
      if (moved) {
        _fromPositions[v.vehicleId] = _currentGpsPosition(v.vehicleId);
        _toPositions[v.vehicleId] = newCoord;
        anyMoved = true;
      }
    }
    // Remove vehicles no longer in the feed.
    final ids = newVehicles.map((v) => v.vehicleId).toSet();
    _fromPositions.removeWhere((k, _) => !ids.contains(k));
    _toPositions.removeWhere((k, _) => !ids.contains(k));

    if (anyMoved) _gpsAnimController.forward(from: 0);
  }

  /// Returns the current interpolated GPS coordinate for [vehicleId].
  TransitCoordinate _currentGpsPosition(String vehicleId) {
    final from = _fromPositions[vehicleId];
    final to = _toPositions[vehicleId];
    if (to == null) return from ?? const TransitCoordinate(0, 0);
    if (from == null) return to;
    final t = _gpsAnimController.value;
    return TransitCoordinate(
      from.latitude + (to.latitude - from.latitude) * t,
      from.longitude + (to.longitude - from.longitude) * t,
    );
  }

  void _updateSimulation() {
    if (!mounted) return;
    final route = widget.network.routesById[widget.lineId];
    if (route == null) {
      if (mounted) setState(() => _simulatedVehicles = []);
      return;
    }
    final pattern = _pattern(route);
    final simulated = VehiclePositionSimulator.simulatedVehiclesForProgress(
      route: route,
      globalProgress: _simProgress,
      count: 2,
      pattern: pattern,
      stopsById: widget.network.stopsById,
    );
    if (mounted) setState(() => _simulatedVehicles = simulated);
  }

  void _resetAnimation() {
    _simTimer?.cancel();
    _gpsAnimController.stop();
    _fromPositions.clear();
    _toPositions.clear();
    _simProgress = 0.0;
    setState(() {
      _simulatedVehicles = [];
    });
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
                action: _TruthBadge(
                  live: live,
                  isLoading: widget.controller.isLoading,
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: widget.controller.retry,
                  color: AppColors.primary,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    scrollCacheExtent: ScrollCacheExtent.pixels(1000),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.pageHorizontal,
                      AppSpacing.sectionLg,
                      AppSpacing.pageHorizontal,
                      AppSpacing.pageBottom,
                    ),
                    children: [
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
                          pattern: pattern,
                          network: widget.network,
                          simulatedVehicles: _simulatedVehicles,
                          selectedVehicleIndex: _selectedVehicleIndex,
                          onVehicleSelected: (idx) {
                            setState(() => _selectedVehicleIndex = idx);
                          },
                        ),
                      if (widget.demoArrivalReminder != null) ...[
                        const SizedBox(height: AppSpacing.sectionLg),
                        _DemoArrivalNotification(
                          reminder: widget.demoArrivalReminder!,
                          network: widget.network,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sectionLg),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          boxShadow: AppShadows.card,
                        ),
                        child: _map(route, pattern, vehicles),
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
                      _buildStopSequence(route: route, pattern: pattern),
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

    // ── Build vehicle markers ────────────────────────────────────────────
    final vehicleMarkers = <TransitMapMarker>[];

    if (vehicles.isNotEmpty) {
      // Animated GPS markers — use interpolated positions from the tween.
      for (final vehicle in vehicles.take(20)) {
        if (vehicle.latitude == null || vehicle.longitude == null) continue;
        vehicleMarkers.add(
          TransitMapMarker(
            id: 'vehicle-${vehicle.vehicleId}',
            label:
                'Live · ${vehicle.label ?? vehicle.vehicleId} · '
                'updated ${TimeOfDay.fromDateTime(vehicle.lastUpdated.toLocal()).format(context)}',
            coordinate: _currentGpsPosition(vehicle.vehicleId),
            kind: TransitMapMarkerKind.vehicle,
            iconOverride: _vehicleCustomIcon,
            anchor: const Offset(0.5, 0.5),
            flat: false,
          ),
        );
      }
    } else if (_simulatedVehicles.isNotEmpty) {
      final selectedVehicleIndex = _selectedVehicleIndex
          .clamp(0, _simulatedVehicles.length - 1)
          .toInt();
      // Smooth moving simulation — vertically fixed bus/train icons with distinct colors and numbers (1 vs 2)
      for (var i = 0; i < _simulatedVehicles.length; i++) {
        if (i != selectedVehicleIndex) continue;
        final sim = _simulatedVehicles[i];
        final icon = i == 0
            ? (_vehicle1Icon ?? _vehicleCustomIcon)
            : (_vehicle2Icon ?? _vehicleCustomIcon);
        final vehicleLabel =
            '${route.mode == TransitMode.bus ? 'Bus' : 'LRT'} ${i + 1}';
        final directionText = sim.isReturnTrip
            ? 'Towards Origin'
            : 'Towards Destination';
        vehicleMarkers.add(
          TransitMapMarker(
            id: sim.vehicleId,
            label:
                '$vehicleLabel · $directionText · ${(sim.positionFraction * 100).round()}%',
            coordinate: sim.position,
            kind: TransitMapMarkerKind.simulatedVehicle,
            iconOverride: icon,
            anchor: const Offset(0.5, 0.5),
            flat: false,
            onTap: () {
              setState(() => _selectedVehicleIndex = i);
            },
          ),
        );
      }
    }

    // ── Build stop markers (Decluttered: Origin & Destination only by default) ──
    final stopMarkers = <TransitMapMarker>[];
    if (stopIds.isNotEmpty) {
      if (_showAllStops) {
        // User opted into viewing all individual stop pins
        for (var i = 0; i < stopIds.length; i++) {
          if (widget.network.stopsById[stopIds[i]] case final stop?) {
            stopMarkers.add(
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
            );
          }
        }
      } else {
        // Clean uncluttered view: Only Terminus endpoints (Start & End)
        if (widget.network.stopsById[stopIds.first] case final firstStop?) {
          stopMarkers.add(
            TransitMapMarker(
              id: firstStop.id,
              label:
                  'Origin: ${TransitPresentation.formatStopName(firstStop.name)}',
              coordinate: firstStop.coordinate,
              kind: TransitMapMarkerKind.origin,
            ),
          );
        }
        if (stopIds.length > 1) {
          if (widget.network.stopsById[stopIds.last] case final lastStop?) {
            stopMarkers.add(
              TransitMapMarker(
                id: lastStop.id,
                label:
                    'Destination: ${TransitPresentation.formatStopName(lastStop.name)}',
                coordinate: lastStop.coordinate,
                kind: TransitMapMarkerKind.destination,
              ),
            );
          }
        }
      }
    }

    return Stack(
      children: [
        TransitGoogleMap(
          key: ValueKey('tracking-map-${route.id}'),
          markers: [...stopMarkers, ...vehicleMarkers],
          lines: [
            TransitMapLine(
              id: route.id,
              color: TransitPresentation.routeColor(route),
              points: route.shape,
            ),
          ],
          initialCenter: route.shape.firstOrNull,
          enableInteractionControls: true,
          height: 240,
        ),
        // Declutter overlay toggle: tap to show all stations if needed
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            color: AppColors.surface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(AppRadius.circular),
            elevation: 2,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.circular),
              onTap: () => setState(() => _showAllStops = !_showAllStops),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showAllStops
                          ? Icons.layers_rounded
                          : Icons.layers_outlined,
                      size: 14,
                      color: _showAllStops
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _showAllStops ? 'Hide stops' : 'Show stops',
                      style: AppTypography.captionBold.copyWith(
                        color: _showAllStops
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
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

  Widget _buildStopSequence({
    required TransitRoute route,
    required TransitPattern? pattern,
  }) {
    if (pattern == null || pattern.stopIds.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.sectionLg),
        child: Text('No stop sequence is available for this route.'),
      );
    }

    final activeVehicle = _simulatedVehicles.length > _selectedVehicleIndex
        ? _simulatedVehicles[_selectedVehicleIndex]
        : null;

    final isReturn = activeVehicle?.isReturnTrip ?? false;
    final stopIds = isReturn
        ? pattern.stopIds.reversed.toList()
        : pattern.stopIds;

    final routeColor = _selectedVehicleIndex == 0
        ? TransitPresentation.routeColor(route)
        : const Color(0xFF2563EB);

    VehicleStationStatus? stationStatus;
    if (activeVehicle != null) {
      stationStatus = VehiclePositionSimulator.computeStationStatus(
        vehicle: activeVehicle,
        pattern: pattern,
        stopsById: widget.network.stopsById,
        vehicleIndex: _selectedVehicleIndex,
      );
    }

    int activeStopIndex = -1;
    if (stationStatus != null) {
      for (var i = 0; i < stopIds.length; i++) {
        final stop = widget.network.stopsById[stopIds[i]];
        if (stop != null &&
            TransitPresentation.formatStopName(stop.name).toLowerCase() ==
                stationStatus.stationName.toLowerCase()) {
          activeStopIndex = i;
          break;
        }
      }
    }

    return Column(
      children: [
        for (var index = 0; index < stopIds.length; index++)
          if (widget.network.stopsById[stopIds[index]] case final stop?) ...[
            if (index == activeStopIndex && stationStatus != null)
              _ActiveTrainStopCard(
                key: ValueKey('active-stop-${stop.id}'),
                index: index,
                totalStops: stopIds.length,
                stop: stop,
                route: route,
                vehicleIndex: _selectedVehicleIndex,
                status: stationStatus,
                accentColor: routeColor,
              )
            else if (activeStopIndex != -1 && index < activeStopIndex)
              _PassedStopRow(
                index: index,
                totalStops: stopIds.length,
                stop: stop,
                route: route,
              )
            else
              _StopRow(
                index: index,
                totalStops: stopIds.length,
                stop: stop,
                route: route,
                active: _isJourneyStop(stop.id),
                isOrigin: _isJourneyOrigin(stop.id, index),
                isDestination: _isJourneyDestination(
                  stop.id,
                  index,
                  stopIds.length,
                ),
              ),
          ],
      ],
    );
  }
}

class _TruthBadge extends StatelessWidget {
  final bool live;
  final bool isLoading;

  const _TruthBadge({required this.live, required this.isLoading});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.gapMd,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: live
          ? AppColors.greenLiveBg
          : (isLoading ? AppColors.mutedBg : AppColors.secondaryLight),
      borderRadius: BorderRadius.circular(AppRadius.circular),
    ),
    child: Text(
      live ? 'LIVE' : (isLoading ? 'CHECKING' : 'SCHEDULED'),
      style: AppTypography.captionBold.copyWith(
        color: live
            ? AppColors.greenLive
            : (isLoading ? AppColors.textSecondary : AppColors.secondary),
        letterSpacing: 0.5,
      ),
    ),
  );
}

class _LiveSummary extends StatelessWidget {
  final List<LiveVehicle> vehicles;

  const _LiveSummary({required this.vehicles});

  @override
  Widget build(BuildContext context) {
    final latestUpdate = vehicles
        .map((vehicle) => vehicle.lastUpdated)
        .reduce((latest, value) => value.isAfter(latest) ? value : latest);
    final visibleVehicles = vehicles.take(3).toList();
    return Container(
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
                  'Live vehicle positions',
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${vehicles.length} official vehicle position${vehicles.length == 1 ? '' : 's'} · last updated ${TimeOfDay.fromDateTime(latestUpdate.toLocal()).format(context)}.',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.gapMd),
                Wrap(
                  spacing: AppSpacing.gapSm,
                  runSpacing: AppSpacing.gapSm,
                  children: [
                    for (final vehicle in visibleVehicles)
                      _VehicleChip(label: vehicle.label ?? vehicle.vehicleId),
                    if (vehicles.length > visibleVehicles.length)
                      _VehicleChip(
                        label:
                            '+${vehicles.length - visibleVehicles.length} more',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleChip extends StatelessWidget {
  final String label;

  const _VehicleChip({required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.gapSm,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.circular),
      border: Border.all(color: AppColors.greenLiveBorder),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.directions_bus_filled_rounded, size: 14),
        const SizedBox(width: AppSpacing.xs),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 120),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.captionBold,
          ),
        ),
      ],
    ),
  );
}

class _DemoArrivalNotification extends StatelessWidget {
  final ArrivalReminder reminder;
  final TransitNetwork network;

  const _DemoArrivalNotification({
    required this.reminder,
    required this.network,
  });

  @override
  Widget build(BuildContext context) {
    final station = network.stopsById[reminder.stationId];
    final route = network.routesById[reminder.routeId];
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.notifications_active_rounded,
            color: AppColors.secondary,
          ),
          const SizedBox(width: AppSpacing.gapMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Demo arrival notification',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${station == null ? reminder.stationId : TransitPresentation.formatStopName(station.name)} is the next stop on ${route?.displayName ?? reminder.routeId}. The example reminder is triggered and ready in Alerts.',
                  style: AppTypography.bodySmall.copyWith(
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
}

class _ScheduledSummary extends StatelessWidget {
  final TransitRoute route;
  final DateTime? nextDeparture;
  final JourneyOption? journey;
  final TransitPattern? pattern;
  final TransitNetwork network;
  final List<SimulatedVehicle> simulatedVehicles;
  final int selectedVehicleIndex;
  final ValueChanged<int> onVehicleSelected;

  const _ScheduledSummary({
    required this.route,
    required this.nextDeparture,
    required this.journey,
    required this.pattern,
    required this.network,
    required this.simulatedVehicles,
    required this.selectedVehicleIndex,
    required this.onVehicleSelected,
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

    final totalMins =
        segment?.durationMinutes ??
        (pattern != null && pattern!.offsetMinutes.isNotEmpty
            ? pattern!.offsetMinutes.last
            : 30);

    // Selected vehicle reference
    final selectedVehicle = simulatedVehicles.length > selectedVehicleIndex
        ? simulatedVehicles[selectedVehicleIndex]
        : (simulatedVehicles.isNotEmpty ? simulatedVehicles.first : null);

    // Stops and station names
    final isReturn = selectedVehicle?.isReturnTrip ?? false;
    final stopIds = pattern != null
        ? (isReturn ? pattern!.stopIds.reversed.toList() : pattern!.stopIds)
        : const <String>[];

    String departingStopName = 'First Station';
    String arrivingStopName = 'Destination';

    if (segment != null) {
      final fromStop = network.stopsById[segment.fromStopId];
      final toStop = network.stopsById[segment.toStopId];
      if (fromStop != null) {
        departingStopName = TransitPresentation.formatStopName(fromStop.name);
      }
      if (toStop != null) {
        arrivingStopName = TransitPresentation.formatStopName(toStop.name);
      }
    } else if (stopIds.isNotEmpty) {
      final fromStop = network.stopsById[stopIds.first];
      final toStop = network.stopsById[stopIds.last];
      if (fromStop != null) {
        departingStopName = TransitPresentation.formatStopName(fromStop.name);
      }
      if (toStop != null) {
        arrivingStopName = TransitPresentation.formatStopName(toStop.name);
      }
    }

    // Departure countdown / boarding status for the selected vehicle
    String? departureCountdown;
    if (selectedVehicle != null && pattern != null && stopIds.isNotEmpty) {
      final boardingId = segment?.fromStopId ?? stopIds.first;
      final bIdx = stopIds.indexOf(boardingId);
      final totalStops = stopIds.length;

      if (bIdx >= 0 && totalStops > 1) {
        final bFraction = bIdx / (totalStops - 1);
        final rem = VehiclePositionSimulator.remainingMinutesToTarget(
          vehicle: selectedVehicle,
          targetFraction: bFraction,
          tripDurationMinutes: totalMins,
        );

        final isAtBoarding =
            (selectedVehicle.positionFraction - bFraction).abs() < 0.05;
        if (isAtBoarding) {
          departureCountdown = 'Boarding now';
        } else if (selectedVehicle.positionFraction > bFraction &&
            !selectedVehicle.isReturnTrip) {
          departureCountdown = 'Departed';
        } else if (rem <= 1) {
          departureCountdown = 'Arriving in 1 min';
        } else {
          departureCountdown = 'Arriving in $rem min';
        }
      }
    }

    // Expected arrival time calculation
    DateTime? expectedArrival;
    String? arrivalSubtitle;
    if (selectedVehicle != null && pattern != null) {
      final remMins = VehiclePositionSimulator.remainingMinutesToTarget(
        vehicle: selectedVehicle,
        targetFraction: 1.0,
        tripDurationMinutes: totalMins,
      );
      expectedArrival = DateTime.now().add(Duration(minutes: remMins));
      arrivalSubtitle = remMins == 0 ? 'Arrived' : '~$remMins min remaining';
    } else if (nextDeparture != null && segment != null) {
      expectedArrival = nextDeparture!.add(
        Duration(minutes: segment.durationMinutes),
      );
      arrivalSubtitle = '~${segment.durationMinutes} min trip';
    }

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: const BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.schedule_rounded,
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
                      'Scheduled times shown',
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Simulated transit tracking enabled',
                      style: AppTypography.captionMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (simulatedVehicles.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.gapLg),
            _VehicleSelectorTabs(
              vehicles: simulatedVehicles.take(2).toList(),
              route: route,
              selectedIndex: selectedVehicleIndex,
              onSelect: onVehicleSelected,
            ),
          ],
          const SizedBox(height: AppSpacing.sectionLg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ScheduleStationValue(
                  label: 'DEPARTING FROM',
                  stationName: departingStopName,
                  timeText: nextDeparture == null
                      ? 'Check timetable'
                      : TimeOfDay.fromDateTime(
                          nextDeparture!.toLocal(),
                        ).format(context),
                  badgeText: departureCountdown,
                  badgeColor: departureCountdown == 'Boarding now'
                      ? AppColors.success
                      : AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.gapMd),
              Expanded(
                child: _ScheduleStationValue(
                  label: 'ARRIVING AT',
                  stationName: arrivingStopName,
                  timeText: expectedArrival == null
                      ? '—'
                      : TimeOfDay.fromDateTime(
                          expectedArrival.toLocal(),
                        ).format(context),
                  badgeText: arrivalSubtitle,
                  badgeColor: AppColors.secondary,
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

class _VehicleSelectorTabs extends StatelessWidget {
  final List<SimulatedVehicle> vehicles;
  final TransitRoute route;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _VehicleSelectorTabs({
    required this.vehicles,
    required this.route,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final routeColor = TransitPresentation.routeColor(route);
    const vehicle2Color = Color(0xFF2563EB); // Royal Indigo
    final isBus = route.mode == TransitMode.bus;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (var i = 0; i < vehicles.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: _VehicleTabItem(
                index: i,
                isSelected: selectedIndex == i,
                badgeColor: i == 0 ? routeColor : vehicle2Color,
                isBus: isBus,
                onTap: () => onSelect(i),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VehicleTabItem extends StatelessWidget {
  final int index;
  final bool isSelected;
  final Color badgeColor;
  final bool isBus;
  final VoidCallback onTap;

  const _VehicleTabItem({
    required this.index,
    required this.isSelected,
    required this.badgeColor,
    required this.isBus,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final vehicleLabel = '${isBus ? 'Bus' : 'LRT'} ${index + 1}';

    return Material(
      color: isSelected ? AppColors.surface : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      elevation: isSelected ? 1 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: isSelected
                ? Border.all(
                    color: badgeColor.withValues(alpha: 0.5),
                    width: 1.5,
                  )
                : Border.all(color: Colors.transparent, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(AppRadius.circular),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isBus
                          ? Icons.directions_bus_rounded
                          : Icons.train_rounded,
                      color: Colors.white,
                      size: 11,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${index + 1}',
                      style: AppTypography.captionBold.copyWith(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                vehicleLabel,
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduleStationValue extends StatelessWidget {
  final String label;
  final String stationName;
  final String timeText;
  final String? badgeText;
  final Color badgeColor;

  const _ScheduleStationValue({
    required this.label,
    required this.stationName,
    required this.timeText,
    this.badgeText,
    this.badgeColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.captionBlack.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          stationName,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          timeText,
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (badgeText != null) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.gapSm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: Text(
              badgeText!,
              style: AppTypography.labelSmallBold.copyWith(
                color: badgeColor,
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}

class _ActiveTrainStopCard extends StatelessWidget {
  final int index;
  final int totalStops;
  final TransitStop stop;
  final TransitRoute route;
  final int vehicleIndex;
  final VehicleStationStatus status;
  final Color accentColor;

  const _ActiveTrainStopCard({
    super.key,
    required this.index,
    required this.totalStops,
    required this.stop,
    required this.route,
    required this.vehicleIndex,
    required this.status,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final display = TransitPresentation.formatStopName(stop.name);
    final isBus = route.mode == TransitMode.bus;
    final vehicleName = '${isBus ? 'Bus' : 'LRT'} ${vehicleIndex + 1}';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: accentColor.withValues(alpha: 0.6), width: 2),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.gapMd,
          vertical: AppSpacing.gapXs,
        ),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: accentColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              isBus ? Icons.directions_bus_rounded : Icons.train_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                display,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.circular),
              ),
              child: Text(
                vehicleName,
                style: AppTypography.captionBold.copyWith(
                  color: accentColor,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: status.isAtStation ? AppColors.success : accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeIn,
                  switchOutCurve: Curves.easeOut,
                  layoutBuilder: (child, previous) => Stack(
                    alignment: Alignment.centerLeft,
                    children: [...previous, ?child],
                  ),
                  child: Text(
                    status.statusText,
                    key: ValueKey(status.statusText),
                    style: AppTypography.labelSmallBold.copyWith(
                      color: status.isAtStation
                          ? AppColors.success
                          : accentColor,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Text(
                'Stop ${index + 1} of $totalStops',
                style: AppTypography.captionMedium.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PassedStopRow extends StatelessWidget {
  final int index;
  final int totalStops;
  final TransitStop stop;
  final TransitRoute route;

  const _PassedStopRow({
    required this.index,
    required this.totalStops,
    required this.stop,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    final display = TransitPresentation.formatStopName(stop.name);

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 0,
        ),
        leading: const CircleAvatar(
          radius: 11,
          backgroundColor: AppColors.mutedBg,
          child: Icon(
            Icons.check_rounded,
            size: 13,
            color: AppColors.textSecondary,
          ),
        ),
        title: Text(
          display,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Text(
          'Passed',
          style: AppTypography.captionMedium.copyWith(
            color: AppColors.textTertiary,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
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
