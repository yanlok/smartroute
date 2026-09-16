import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
import '../../application/tracking_session_controller.dart';
import '../../domain/models/live_vehicle.dart';
import '../../domain/services/vehicle_position_simulator.dart';
import '../../presentation/widgets/tracking_history_sheet.dart';

class TrackingScreen extends StatefulWidget {
  final String lineId;
  final TrackingController controller;
  final TrackingSessionController sessionController;
  final TransitNetwork network;
  final JourneyOption? journey;
  final VoidCallback onBack;

  const TrackingScreen({
    super.key,
    required this.lineId,
    required this.controller,
    required this.sessionController,
    required this.network,
    required this.onBack,
    this.journey,
  });

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _gpsAnimController;

  final Map<String, TransitCoordinate> _fromPositions = {};

  final Map<String, TransitCoordinate> _toPositions = {};

  Timer? _simTimer;
  double _simProgress = 0.0;
  List<SimulatedVehicle> _simulatedVehicles = [];

  int _selectedVehicleIndex = 0;

  int _sessionOriginIndex = 0;

  BitmapDescriptor? _vehicleCustomIcon;
  BitmapDescriptor? _vehicle1Icon;
  BitmapDescriptor? _vehicle2Icon;

  bool _showAllStops = false;

  @override
  void initState() {
    super.initState();
    _gpsAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addListener(_onAnimTick);

    widget.controller.addListener(_onControllerChanged);
    widget.sessionController.addListener(_onSessionChanged);
    widget.controller.selectLine(widget.lineId);
    _loadVehicleIcons();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !widget.controller.hasLiveVehicles) {
        _startContinuousSimulation();
      }
      if (mounted) {
        unawaited(_ensureTrackingSession());
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
    const returnColor = Color(0xFF2563EB);

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
      unawaited(_ensureTrackingSession());
    }
  }

  @override
  void dispose() {
    _gpsAnimController.dispose();
    widget.controller.removeListener(_onControllerChanged);
    widget.sessionController.removeListener(_onSessionChanged);
    _simTimer?.cancel();
    super.dispose();
  }

  void _onSessionChanged() {
    if (mounted) setState(() {});
  }

  void _onAnimTick() {
    if (mounted) setState(() {});
  }

  void _onControllerChanged() {
    if (!mounted || widget.controller.isLoading) return;

    final liveVehicles = widget.controller.vehicles
        .where((v) => v.isLive && v.latitude != null && v.longitude != null)
        .toList();

    if (liveVehicles.isNotEmpty) {
      _simTimer?.cancel();
      if (mounted) setState(() => _simulatedVehicles = []);
      _updateGpsAnimation(liveVehicles);
    } else {
      _gpsAnimController.stop();
      _fromPositions.clear();
      _toPositions.clear();
      _startContinuousSimulation();
    }
  }

  void _startContinuousSimulation() {
    _simTimer?.cancel();
    _updateSimulation();
    _simTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      _simProgress = (_simProgress + 0.00097) % 1.0;
      _updateSimulation();
    });
  }

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
    final ids = newVehicles.map((v) => v.vehicleId).toSet();
    _fromPositions.removeWhere((k, _) => !ids.contains(k));
    _toPositions.removeWhere((k, _) => !ids.contains(k));

    if (anyMoved) _gpsAnimController.forward(from: 0);
  }

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
    _recordSessionProgress(simulated);
  }

  /// Creates (or adopts) the Supabase tracking session for the opened route.
  /// Start follows the selected simulated train's current position and end
  /// follows the terminus it is heading towards, so the commute recorded
  /// mirrors the live simulation.
  Future<void> _ensureTrackingSession() async {
    final route = widget.network.routesById[widget.lineId];
    if (route == null) return;
    final pattern = _pattern(route);
    if (pattern == null || pattern.stopIds.length < 2) return;

    JourneySegment? segment;
    for (final candidate
        in widget.journey?.segments ?? const <JourneySegment>[]) {
      if (candidate.routeId == route.id) {
        segment = candidate;
        break;
      }
    }

    final (originIndex, destinationIndex) = _sessionStopRange(pattern, segment);
    _sessionOriginIndex = originIndex;
    final originStop = widget.network.stopsById[pattern.stopIds[originIndex]];
    final destinationStop =
        widget.network.stopsById[pattern.stopIds[destinationIndex]];
    if (originStop == null) return;

    await widget.sessionController.ensureActiveSession(
      routeId: route.id,
      routeName: route.displayName,
      mode: route.mode.label,
      originStopId: originStop.id,
      originStopName: TransitPresentation.formatStopName(originStop.name),
      destinationStopId: destinationStop?.id,
      destinationStopName: destinationStop == null
          ? null
          : TransitPresentation.formatStopName(destinationStop.name),
      totalStops: (destinationIndex - originIndex).abs(),
    );
  }

  /// Resolves the commute's stop indexes from the live simulation state.
  /// Start is the station the selected train is at (or approaching); end is
  /// the terminus it is currently heading towards, so the recorded commute
  /// always follows the simulation direction.
  (int, int) _sessionStopRange(
    TransitPattern pattern,
    JourneySegment? segment,
  ) {
    final stopIds = pattern.stopIds;
    var originIndex = 0;
    var destinationIndex = stopIds.length - 1;

    if (_simulatedVehicles.isNotEmpty) {
      final selectedIndex = _selectedVehicleIndex.clamp(
        0,
        _simulatedVehicles.length - 1,
      );
      final vehicle = _simulatedVehicles[selectedIndex];

      final currentIndex = vehicle.isAtStation
          ? vehicle.currentStopIndex
          : vehicle.nextStopIndex;
      if (currentIndex != null &&
          currentIndex >= 0 &&
          currentIndex < stopIds.length) {
        originIndex = currentIndex;
      }

      destinationIndex = vehicle.isReturnTrip ? 0 : stopIds.length - 1;

      if (destinationIndex == originIndex) {
        destinationIndex = originIndex == stopIds.length - 1
            ? 0
            : stopIds.length - 1;
      }
    } else {
      // No simulation yet (first frame): fall back to the planned journey
      // destination, or the line terminus.
      final segmentDestinationId = segment?.toStopId;
      if (segmentDestinationId != null) {
        final segmentIndex = stopIds.indexOf(segmentDestinationId);
        if (segmentIndex != -1) destinationIndex = segmentIndex;
      }
    }

    return (originIndex, destinationIndex);
  }

  /// Feeds simulated train movement into the active tracking session.
  void _recordSessionProgress(List<SimulatedVehicle> simulated) {
    if (simulated.isEmpty) return;
    final route = widget.network.routesById[widget.lineId];
    if (route == null) return;
    final pattern = _pattern(route);
    if (pattern == null || pattern.stopIds.isEmpty) return;

    final selectedIndex = _selectedVehicleIndex.clamp(0, simulated.length - 1);
    final vehicle = simulated[selectedIndex];
    final stopIndex = vehicle.currentStopIndex;
    if (!vehicle.isAtStation || stopIndex == null) return;
    if (stopIndex < 0 || stopIndex >= pattern.stopIds.length) return;
    final stop = widget.network.stopsById[pattern.stopIds[stopIndex]];
    if (stop == null) return;

    unawaited(
      widget.sessionController.recordStationArrival(
        stopId: stop.id,
        stationName: TransitPresentation.formatStopName(stop.name),
        stopsCompleted: (stopIndex - _sessionOriginIndex).abs(),
      ),
    );
  }

  Future<void> _confirmEndCommute() async {
    final notesController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          'End this commute?',
          style: AppTypography.headlineSmall.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        content: TextField(
          controller: notesController,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: 'Add a note (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('End Commute'),
          ),
        ],
      ),
    );
    final notes = notesController.text.trim();
    notesController.dispose();
    if (confirmed != true) return;

    final endStop = _currentEndStop();
    final saved = await widget.sessionController.endCommute(
      notes: notes.isEmpty ? null : notes,
      endStopId: endStop?.$1,
      endStopName: endStop?.$2,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Commute saved to your history.'
              : widget.sessionController.errorMessage ??
                    'The commute could not be completed.',
        ),
      ),
    );
  }

  /// Resolves where the selected simulated train is right now, so the ended
  /// commute records the station the rider actually got off at (the current
  /// stop when dwelling, otherwise the stop it is arriving at next).
  (String, String)? _currentEndStop() {
    if (_simulatedVehicles.isEmpty) return null;
    final route = widget.network.routesById[widget.lineId];
    if (route == null) return null;
    final pattern = _pattern(route);
    if (pattern == null || pattern.stopIds.isEmpty) return null;

    final selectedIndex = _selectedVehicleIndex.clamp(
      0,
      _simulatedVehicles.length - 1,
    );
    final vehicle = _simulatedVehicles[selectedIndex];
    final stopIndex = vehicle.isAtStation
        ? vehicle.currentStopIndex
        : vehicle.nextStopIndex;
    if (stopIndex == null ||
        stopIndex < 0 ||
        stopIndex >= pattern.stopIds.length) {
      return null;
    }
    final stop = widget.network.stopsById[pattern.stopIds[stopIndex]];
    if (stop == null) return null;
    return (stop.id, TransitPresentation.formatStopName(stop.name));
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
                    cacheExtent: 1000,
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
                      const SizedBox(height: AppSpacing.sectionLg),
                      _SessionCard(
                        controller: widget.sessionController,
                        onEndCommute: _confirmEndCommute,
                        onRetry: () => unawaited(_ensureTrackingSession()),
                        onStart: () => unawaited(_ensureTrackingSession()),
                      ),
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

    final vehicleMarkers = <TransitMapMarker>[];

    if (vehicles.isNotEmpty) {
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

    final stopMarkers = <TransitMapMarker>[];
    if (stopIds.isNotEmpty) {
      if (_showAllStops) {
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

class _SessionCard extends StatelessWidget {
  final TrackingSessionController controller;
  final VoidCallback onEndCommute;
  final VoidCallback onRetry;
  final VoidCallback onStart;

  const _SessionCard({
    required this.controller,
    required this.onEndCommute,
    required this.onRetry,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.userId == null) return const SizedBox.shrink();

        final session = controller.activeSession;
        if (session == null) {
          if (controller.errorMessage != null) {
            return _SessionFrame(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.errorMessage!,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.gapMd),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Retry'),
                    ),
                  ),
                ],
              ),
            );
          }
          if (controller.isSaving) {
            return const _SessionFrame(
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: AppSpacing.gapMd),
                  Text('Starting tracking session…'),
                ],
              ),
            );
          }
          return _SessionFrame(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Icon(
                        Icons.pause_rounded,
                        color: AppColors.textSecondary,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.gapMd),
                    Expanded(
                      child: Text(
                        'No active tracking session',
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.gapMd),
                Text(
                  'Start tracking this line again or review your past commutes.',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.gapLg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => TrackingHistorySheet.show(
                          context,
                          controller: controller,
                        ),
                        icon: const Icon(Icons.history_rounded, size: 18),
                        label: const Text('History'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.gapMd),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                        ),
                        onPressed: onStart,
                        icon: const Icon(Icons.play_arrow_rounded, size: 18),
                        label: const Text('Start Tracking'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        final total = session.totalStops;
        final progressText = total > 0
            ? '${session.stopsCompleted} of $total stations passed'
            : 'Tracking in progress';
        final atText = session.currentStationName == null
            ? 'Waiting for the next station'
            : 'Train at ${session.currentStationName}';

        return _SessionFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.route_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.gapMd),
                  Expanded(
                    child: Text(
                      'Tracking session active',
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (controller.isSaving)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.gapMd),
              Text(
                'Session active · $progressText · $atText',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.gapSm),
              const SizedBox(height: AppSpacing.gapLg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: controller.isSaving
                          ? null
                          : () => TrackingHistorySheet.show(
                              context,
                              controller: controller,
                            ),
                      icon: const Icon(Icons.history_rounded, size: 18),
                      label: const Text('History'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.gapMd),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      onPressed: controller.isSaving ? null : onEndCommute,
                      icon: const Icon(Icons.flag_rounded, size: 18),
                      label: const Text('End Commute'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SessionFrame extends StatelessWidget {
  final Widget child;

  const _SessionFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sectionLg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.card,
        ),
        child: child,
      ),
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

    final selectedVehicle = simulatedVehicles.length > selectedVehicleIndex
        ? simulatedVehicles[selectedVehicleIndex]
        : (simulatedVehicles.isNotEmpty ? simulatedVehicles.first : null);

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
    const vehicle2Color = Color(0xFF2563EB);
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
      statusSubtitle = 'Start here';
    } else if (isDestination) {
      statusSubtitle = 'Destination here';
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
