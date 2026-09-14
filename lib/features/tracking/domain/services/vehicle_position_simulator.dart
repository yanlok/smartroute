import 'dart:math' as math;

import '../../../../core/utils/transit_presentation.dart';
import '../../../../shared/models/transit_models.dart';

/// Represents a single discrete step in a round-trip transit simulation:
/// either a station dwell pause or movement between stations.
class SimulationTimelineStep {
  final double duration;
  final bool isDwell;
  final int stopIndex;
  final double startFraction;
  final double endFraction;
  final bool isReturn;

  const SimulationTimelineStep({
    required this.duration,
    required this.isDwell,
    required this.stopIndex,
    required this.startFraction,
    required this.endFraction,
    required this.isReturn,
  });
}

/// Real-time station proximity and journey direction for a simulated vehicle.
class VehicleStationStatus {
  final String stationName;
  final bool isAtStation;
  final String statusText;
  final String towardsTerminus;
  final int vehicleIndex;

  const VehicleStationStatus({
    required this.stationName,
    required this.isAtStation,
    required this.statusText,
    required this.towardsTerminus,
    required this.vehicleIndex,
  });
}

/// A simulated vehicle position derived from GTFS schedule data.
///
/// No live GPS is involved — the position is mathematically interpolated
/// from the pattern's [startSeconds], [headwaySeconds], and [offsetMinutes].
class SimulatedVehicle {
  final String vehicleId;
  final TransitCoordinate position;

  /// Progress through the route, in the range [0.0, 1.0].
  final double positionFraction;

  /// Heading angle in degrees clockwise from North (0.0 to 360.0).
  final double bearing;

  /// Whether the vehicle is on the return trip (heading from destination back to origin).
  final bool isReturnTrip;

  /// Whether the vehicle is currently stopped at a station.
  final bool isAtStation;

  /// If stopped or nearest to a stop, the stop index in pattern.stopIds.
  final int? currentStopIndex;

  /// If in transit between stations, the upcoming stop index in pattern.stopIds.
  final int? nextStopIndex;

  const SimulatedVehicle({
    required this.vehicleId,
    required this.position,
    required this.positionFraction,
    this.bearing = 0.0,
    this.isReturnTrip = false,
    this.isAtStation = false,
    this.currentStopIndex,
    this.nextStopIndex,
  });
}

/// Pure-Dart service for computing simulated vehicle positions.
///
/// This class has no Flutter or network dependencies and is fully unit-testable.
/// It uses the bundled GTFS schedule data ([TransitPattern]) to infer where
/// vehicles *should* be right now based on scheduled departure times and headways.
///
/// Results are always labelled SCHEDULED — never presented as live telemetry.
class VehiclePositionSimulator {
  const VehiclePositionSimulator._();

  /// Linearly interpolates a coordinate position along [shape] at [fraction].
  ///
  /// [fraction] must be in [0.0, 1.0].
  /// Segment lengths are approximated with flat Euclidean distance, which is
  /// accurate enough for the short inter-stop distances in the Klang Valley.
  static TransitCoordinate interpolatePolyline(
    List<TransitCoordinate> shape,
    double fraction,
  ) {
    if (shape.isEmpty) return const TransitCoordinate(3.139, 101.687);
    if (shape.length == 1) return shape.first;

    final t = fraction.clamp(0.0, 1.0);
    if (t <= 0.0) return shape.first;
    if (t >= 1.0) return shape.last;

    double totalLength = 0.0;
    final segmentLengths = List<double>.filled(shape.length - 1, 0.0);
    for (var i = 0; i < shape.length - 1; i++) {
      final dx = shape[i + 1].longitude - shape[i].longitude;
      final dy = shape[i + 1].latitude - shape[i].latitude;
      final len = math.sqrt(dx * dx + dy * dy);
      segmentLengths[i] = len;
      totalLength += len;
    }

    if (totalLength == 0.0) return shape.first;

    final target = t * totalLength;
    double accumulated = 0.0;

    for (var i = 0; i < segmentLengths.length; i++) {
      final segLen = segmentLengths[i];
      if (accumulated + segLen >= target) {
        final segT = segLen == 0.0 ? 0.0 : (target - accumulated) / segLen;
        final start = shape[i];
        final end = shape[i + 1];
        return TransitCoordinate(
          start.latitude + (end.latitude - start.latitude) * segT,
          start.longitude + (end.longitude - start.longitude) * segT,
        );
      }
      accumulated += segLen;
    }

    return shape.last;
  }

  /// Returns all [SimulatedVehicle]s that should be on the route right [now].
  ///
  /// Uses [pattern.headwaySeconds] to enumerate every trip that started before
  /// [now] and has not yet completed. Returns an empty list when:
  /// - the pattern has no headway (single-trip routes or missing data)
  /// - the route has no shape coordinates
  /// - no trips are currently in service
  ///
  /// Caps at 20 vehicles to prevent performance issues on high-frequency routes.
  static List<SimulatedVehicle> simulatedPositions({
    required TransitPattern pattern,
    required TransitRoute route,
    required DateTime now,
  }) {
    final headway = pattern.headwaySeconds;
    if (headway == null || headway <= 0) return const [];
    if (route.shape.isEmpty) return const [];
    if (pattern.offsetMinutes.isEmpty) return const [];

    final tripDurationSeconds = pattern.offsetMinutes.last * 60;
    if (tripDurationSeconds <= 0) return const [];

    final secondsSinceMidnight = now.hour * 3600 + now.minute * 60 + now.second;
    if (secondsSinceMidnight < pattern.startSeconds ||
        secondsSinceMidnight > pattern.endSeconds + tripDurationSeconds) {
      return const [];
    }

    // Jump directly to the earliest trip that could still be in transit.
    final earliestStart = (secondsSinceMidnight - tripDurationSeconds).clamp(
      pattern.startSeconds,
      pattern.endSeconds,
    );
    final tripsBefore = ((earliestStart - pattern.startSeconds) / headway)
        .floor();
    var tripStart = pattern.startSeconds + tripsBefore * headway;
    if (tripStart < pattern.startSeconds) tripStart = pattern.startSeconds;

    final simulated = <SimulatedVehicle>[];

    while (tripStart <= pattern.endSeconds &&
        tripStart <= secondsSinceMidnight &&
        simulated.length < 20) {
      final tripEnd = tripStart + tripDurationSeconds;

      if (secondsSinceMidnight <= tripEnd) {
        final elapsed = secondsSinceMidnight - tripStart;
        final fraction = (elapsed / tripDurationSeconds)
            .clamp(0.0, 1.0)
            .toDouble();
        final position = interpolatePolyline(route.shape, fraction);
        simulated.add(
          SimulatedVehicle(
            vehicleId: 'sim-${route.id}-$tripStart',
            position: position,
            positionFraction: fraction,
          ),
        );
      }

      tripStart += headway;
    }

    return simulated;
  }

  /// Calculates the forward azimuth / bearing in degrees (0.0 to 360.0)
  /// from [start] to [end] using spherical forward geodesy.
  static double calculateBearing(
    TransitCoordinate start,
    TransitCoordinate end,
  ) {
    final lat1 = start.latitude * math.pi / 180.0;
    final lat2 = end.latitude * math.pi / 180.0;
    final dLon = (end.longitude - start.longitude) * math.pi / 180.0;
    final y = math.sin(dLon) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final rad = math.atan2(y, x);
    return (rad * 180.0 / math.pi + 360.0) % 360.0;
  }

  /// Interpolates position AND bearing along [shape] at [fraction] (0.0 to 1.0).
  static ({TransitCoordinate position, double bearing})
  interpolatePolylineWithBearing(
    List<TransitCoordinate> shape,
    double fraction,
  ) {
    if (shape.isEmpty) {
      return (position: const TransitCoordinate(3.139, 101.687), bearing: 0.0);
    }
    if (shape.length == 1) {
      return (position: shape.first, bearing: 0.0);
    }

    final t = fraction.clamp(0.0, 1.0);
    double totalLength = 0.0;
    final segmentLengths = List<double>.filled(shape.length - 1, 0.0);
    for (var i = 0; i < shape.length - 1; i++) {
      final dx = shape[i + 1].longitude - shape[i].longitude;
      final dy = shape[i + 1].latitude - shape[i].latitude;
      final len = math.sqrt(dx * dx + dy * dy);
      segmentLengths[i] = len;
      totalLength += len;
    }

    if (totalLength == 0.0) {
      return (position: shape.first, bearing: 0.0);
    }

    final target = t * totalLength;
    double accumulated = 0.0;

    for (var i = 0; i < segmentLengths.length; i++) {
      final segLen = segmentLengths[i];
      if (accumulated + segLen >= target || i == segmentLengths.length - 1) {
        final segT = segLen == 0.0 ? 0.0 : (target - accumulated) / segLen;
        final start = shape[i];
        final end = shape[i + 1];
        final coord = TransitCoordinate(
          start.latitude + (end.latitude - start.latitude) * segT,
          start.longitude + (end.longitude - start.longitude) * segT,
        );
        final bearing = calculateBearing(start, end);
        return (position: coord, bearing: bearing);
      }
      accumulated += segLen;
    }

    final bearing = calculateBearing(shape[shape.length - 2], shape.last);
    return (position: shape.last, bearing: bearing);
  }

  /// Finds the fraction in [0.0, 1.0] along [shape] that is closest to [target].
  static double projectCoordinateToShapeFraction(
    List<TransitCoordinate> shape,
    TransitCoordinate target, {
    int startSegmentIndex = 0,
  }) {
    if (shape.isEmpty) return 0.0;
    if (shape.length == 1) return 0.0;

    double totalLength = 0.0;
    final segLengths = List<double>.filled(shape.length - 1, 0.0);
    for (var i = 0; i < shape.length - 1; i++) {
      final dx = shape[i + 1].longitude - shape[i].longitude;
      final dy = shape[i + 1].latitude - shape[i].latitude;
      final len = math.sqrt(dx * dx + dy * dy);
      segLengths[i] = len;
      totalLength += len;
    }

    if (totalLength == 0.0) return 0.0;

    double minDistanceSq = double.infinity;
    double bestArcLength = 0.0;
    double currentArc = 0.0;

    final startIndex = startSegmentIndex.clamp(0, shape.length - 2);
    for (var i = 0; i < startIndex; i++) {
      currentArc += segLengths[i];
    }

    for (var i = startIndex; i < shape.length - 1; i++) {
      final a = shape[i];
      final b = shape[i + 1];
      final segLen = segLengths[i];

      final dx = b.longitude - a.longitude;
      final dy = b.latitude - a.latitude;
      final l2 = dx * dx + dy * dy;

      double u = 0.0;
      if (l2 > 0.0) {
        u =
            ((target.longitude - a.longitude) * dx +
                (target.latitude - a.latitude) * dy) /
            l2;
        u = u.clamp(0.0, 1.0);
      }

      final projX = a.longitude + u * dx;
      final projY = a.latitude + u * dy;
      final distSq =
          (target.longitude - projX) * (target.longitude - projX) +
          (target.latitude - projY) * (target.latitude - projY);

      if (distSq < minDistanceSq) {
        minDistanceSq = distSq;
        bestArcLength = currentArc + u * segLen;
      }

      currentArc += segLen;
    }

    return (bestArcLength / totalLength).clamp(0.0, 1.0);
  }

  /// Represents a single discrete event in a vehicle's round-trip journey:
  /// either a station dwell pause (stopping for passengers) or travel between stops.
  static List<SimulationTimelineStep> buildSimulationTimeline({
    required TransitPattern pattern,
    List<TransitCoordinate>? shape,
    Map<String, TransitStop>? stopsById,
    double dwellSeconds = 3.0,
    double terminusDwellSeconds = 4.0,
    double defaultTravelSeconds = 6.0,
  }) {
    final totalStops = pattern.stopIds.length;
    if (totalStops < 2) return const [];

    final stopFractions = List<double>.filled(totalStops, 0.0);

    if (stopsById != null && shape != null && shape.length >= 2) {
      var lastFraction = 0.0;
      for (var i = 0; i < totalStops; i++) {
        if (i == 0) {
          stopFractions[i] = 0.0;
          continue;
        }
        if (i == totalStops - 1) {
          stopFractions[i] = 1.0;
          continue;
        }

        final stop = stopsById[pattern.stopIds[i]];
        if (stop != null) {
          final frac = projectCoordinateToShapeFraction(shape, stop.coordinate);
          final clamped = frac >= lastFraction ? frac : lastFraction;
          stopFractions[i] = clamped.clamp(0.0, 1.0);
          lastFraction = stopFractions[i];
        } else {
          stopFractions[i] = (i / (totalStops - 1)).clamp(lastFraction, 1.0);
          lastFraction = stopFractions[i];
        }
      }
    } else {
      final hasOffsets =
          pattern.offsetMinutes.length == totalStops &&
          pattern.offsetMinutes.last > 0;
      final totalDuration = hasOffsets
          ? pattern.offsetMinutes.last.toDouble()
          : 1.0;

      for (var i = 0; i < totalStops; i++) {
        if (hasOffsets) {
          stopFractions[i] = pattern.offsetMinutes[i] / totalDuration;
        } else {
          stopFractions[i] = i / (totalStops - 1);
        }
      }
    }

    final steps = <SimulationTimelineStep>[];

    // 1. Outbound trip (Stop 0 -> Stop totalStops - 1)
    // Dwell at Origin
    steps.add(
      SimulationTimelineStep(
        duration: terminusDwellSeconds,
        isDwell: true,
        stopIndex: 0,
        startFraction: stopFractions[0],
        endFraction: stopFractions[0],
        isReturn: false,
      ),
    );

    for (var i = 0; i < totalStops - 1; i++) {
      // Travel i -> i + 1
      final diff = stopFractions[i + 1] - stopFractions[i];
      final travelSecs = (diff * 50.0).clamp(3.0, 12.0);
      steps.add(
        SimulationTimelineStep(
          duration: travelSecs,
          isDwell: false,
          stopIndex: i,
          startFraction: stopFractions[i],
          endFraction: stopFractions[i + 1],
          isReturn: false,
        ),
      );
      // Dwell at stop i + 1
      final isTerminus = i + 1 == totalStops - 1;
      steps.add(
        SimulationTimelineStep(
          duration: isTerminus ? terminusDwellSeconds : dwellSeconds,
          isDwell: true,
          stopIndex: i + 1,
          startFraction: stopFractions[i + 1],
          endFraction: stopFractions[i + 1],
          isReturn: false,
        ),
      );
    }

    // 2. Return trip (Stop totalStops - 1 -> Stop 0)
    for (var i = totalStops - 1; i > 0; i--) {
      // Travel i -> i - 1
      final diff = stopFractions[i] - stopFractions[i - 1];
      final travelSecs = (diff * 50.0).clamp(3.0, 12.0);
      steps.add(
        SimulationTimelineStep(
          duration: travelSecs,
          isDwell: false,
          stopIndex: i,
          startFraction: stopFractions[i],
          endFraction: stopFractions[i - 1],
          isReturn: true,
        ),
      );
      // Dwell at stop i - 1 (except stop 0 which is covered by origin dwell on next cycle)
      if (i - 1 > 0) {
        steps.add(
          SimulationTimelineStep(
            duration: dwellSeconds,
            isDwell: true,
            stopIndex: i - 1,
            startFraction: stopFractions[i - 1],
            endFraction: stopFractions[i - 1],
            isReturn: true,
          ),
        );
      }
    }

    return steps;
  }

  /// Generates a clean group of [count] moving vehicles (default 2)
  /// that travel continuously in a realistic round trip along the route:
  /// - Outbound (0.0 to 1.0): Origin -> Destination
  /// - Return (1.0 down to 0.0): Destination -> Origin
  ///
  /// When [pattern] is provided with at least 2 stops, vehicles realistically
  /// stop (dwell) for a few seconds at each intermediate station and terminus before continuing.
  /// When dwelling at a station, vehicles snap precisely to the station marker position.
  static List<SimulatedVehicle> simulatedVehiclesForProgress({
    required TransitRoute route,
    required double globalProgress,
    int count = 2,
    TransitPattern? pattern,
    Map<String, TransitStop>? stopsById,
  }) {
    if (route.shape.length < 2) return const [];

    if (pattern != null && pattern.stopIds.length >= 2) {
      final steps = buildSimulationTimeline(
        pattern: pattern,
        shape: route.shape,
        stopsById: stopsById,
      );
      if (steps.isNotEmpty) {
        final totalTimeline = steps.fold<double>(
          0.0,
          (sum, step) => sum + step.duration,
        );

        final vehicles = <SimulatedVehicle>[];

        for (var k = 0; k < count; k++) {
          final offsetSeconds = (k / count) * totalTimeline;
          final t =
              (globalProgress * totalTimeline + offsetSeconds) % totalTimeline;

          var accumulated = 0.0;
          for (final step in steps) {
            if (accumulated + step.duration > t || step == steps.last) {
              final stepT = step.duration <= 0
                  ? 0.0
                  : ((t - accumulated) / step.duration).clamp(0.0, 1.0);

              double legFraction;
              bool isAtStation;
              int? currentStopIndex;
              int? nextStopIndex;
              TransitCoordinate vehiclePos;

              if (step.isDwell) {
                legFraction = step.startFraction;
                isAtStation = true;
                currentStopIndex = step.stopIndex;
                nextStopIndex = null;

                final stop =
                    (stopsById != null &&
                        step.stopIndex >= 0 &&
                        step.stopIndex < pattern.stopIds.length)
                    ? stopsById[pattern.stopIds[step.stopIndex]]
                    : null;

                if (stop != null) {
                  // Direct exact placement on the station's blue marker
                  vehiclePos = stop.coordinate;
                } else {
                  vehiclePos = interpolatePolyline(route.shape, legFraction);
                }
              } else {
                legFraction =
                    step.startFraction +
                    stepT * (step.endFraction - step.startFraction);
                isAtStation = false;
                currentStopIndex = null;
                nextStopIndex = step.isReturn
                    ? step.stopIndex - 1
                    : step.stopIndex + 1;
                vehiclePos = interpolatePolyline(route.shape, legFraction);
              }

              final result = interpolatePolylineWithBearing(
                route.shape,
                legFraction,
              );
              final bearing = step.isReturn
                  ? (result.bearing + 180.0) % 360.0
                  : result.bearing;

              vehicles.add(
                SimulatedVehicle(
                  vehicleId: 'sim-${route.id}-$k',
                  position: vehiclePos,
                  positionFraction: legFraction,
                  bearing: bearing,
                  isReturnTrip: step.isReturn,
                  isAtStation: isAtStation,
                  currentStopIndex: currentStopIndex,
                  nextStopIndex: nextStopIndex,
                ),
              );
              break;
            }
            accumulated += step.duration;
          }
        }
        return vehicles;
      }
    }

    final vehicles = <SimulatedVehicle>[];

    for (var i = 0; i < count; i++) {
      final cycle = (globalProgress + (i / count)) % 1.0;
      final bool isReturn = cycle >= 0.5;
      // When cycle < 0.5: fraction goes from 0.0 -> 1.0 (Outbound)
      // When cycle >= 0.5: fraction goes from 1.0 -> 0.0 (Return)
      final double legFraction = isReturn
          ? (1.0 - (cycle - 0.5) * 2.0).clamp(0.0, 1.0)
          : (cycle * 2.0).clamp(0.0, 1.0);

      final result = interpolatePolylineWithBearing(route.shape, legFraction);
      vehicles.add(
        SimulatedVehicle(
          vehicleId: 'sim-${route.id}-$i',
          position: result.position,
          positionFraction: legFraction,
          bearing: isReturn ? (result.bearing + 180.0) % 360.0 : result.bearing,
          isReturnTrip: isReturn,
        ),
      );
    }

    return vehicles;
  }

  /// Computes the current or next station status for a [vehicle].
  ///
  /// Returns a [VehicleStationStatus] indicating whether the vehicle is
  /// currently at a station or approaching its next stop, along with its terminus direction.
  static VehicleStationStatus computeStationStatus({
    required SimulatedVehicle vehicle,
    required TransitPattern pattern,
    required Map<String, TransitStop> stopsById,
    required int vehicleIndex,
  }) {
    final stopIds = pattern.stopIds;
    if (stopIds.isEmpty) {
      return VehicleStationStatus(
        stationName: 'In Transit',
        isAtStation: false,
        statusText: 'In Transit',
        towardsTerminus: '',
        vehicleIndex: vehicleIndex,
      );
    }

    final originStop = stopsById[stopIds.first];
    final destStop = stopsById[stopIds.last];
    final originName = originStop != null
        ? TransitPresentation.formatStopName(originStop.name)
        : 'Origin';
    final destName = destStop != null
        ? TransitPresentation.formatStopName(destStop.name)
        : 'Destination';

    final towardsTerminus = vehicle.isReturnTrip
        ? 'Towards $originName'
        : 'Towards $destName';

    if (stopIds.length == 1) {
      return VehicleStationStatus(
        stationName: originName,
        isAtStation: true,
        statusText: 'Now at $originName',
        towardsTerminus: towardsTerminus,
        vehicleIndex: vehicleIndex,
      );
    }

    // 1. Direct station dwell check: vehicle is physically stopped at a station
    if (vehicle.isAtStation && vehicle.currentStopIndex != null) {
      final stopIdx = vehicle.currentStopIndex!.clamp(0, stopIds.length - 1);
      final stop = stopsById[stopIds[stopIdx]];
      final stopName = stop != null
          ? TransitPresentation.formatStopName(stop.name)
          : 'Stop ${stopIdx + 1}';
      return VehicleStationStatus(
        stationName: stopName,
        isAtStation: true,
        statusText: 'Now at $stopName',
        towardsTerminus: towardsTerminus,
        vehicleIndex: vehicleIndex,
      );
    }

    final totalStops = stopIds.length;
    final hasOffsets =
        pattern.offsetMinutes.length == totalStops &&
        pattern.offsetMinutes.last > 0;
    final totalDuration = hasOffsets
        ? pattern.offsetMinutes.last.toDouble()
        : 1.0;

    final stopFractions = List<double>.generate(totalStops, (i) {
      if (hasOffsets) {
        return pattern.offsetMinutes[i] / totalDuration;
      }
      return i / (totalStops - 1);
    });

    final t = vehicle.positionFraction.clamp(0.0, 1.0);

    // 2. If vehicle is marked at station (without explicit currentStopIndex):
    if (vehicle.isAtStation) {
      var closestIdx = 0;
      var minDiff = (t - stopFractions[0]).abs();
      for (var i = 1; i < totalStops; i++) {
        final diff = (t - stopFractions[i]).abs();
        if (diff < minDiff) {
          minDiff = diff;
          closestIdx = i;
        }
      }
      final closestStop = stopsById[stopIds[closestIdx]];
      final closestName = closestStop != null
          ? TransitPresentation.formatStopName(closestStop.name)
          : 'Stop ${closestIdx + 1}';
      return VehicleStationStatus(
        stationName: closestName,
        isAtStation: true,
        statusText: 'Now at $closestName',
        towardsTerminus: towardsTerminus,
        vehicleIndex: vehicleIndex,
      );
    }

    // 3. The vehicle is in transit / motion between stations.
    // It remains "Approaching" until it actually reaches and stops at the station.
    int targetIdx;
    if (vehicle.nextStopIndex != null) {
      targetIdx = vehicle.nextStopIndex!.clamp(0, totalStops - 1);
    } else if (!vehicle.isReturnTrip) {
      // Outbound: find the upcoming stop ahead of current fraction
      targetIdx = totalStops - 1;
      for (var i = 0; i < totalStops; i++) {
        if (stopFractions[i] >= t) {
          targetIdx = i;
          break;
        }
      }
    } else {
      // Return: find the upcoming stop behind current fraction (heading down to 0.0)
      targetIdx = 0;
      for (var i = totalStops - 1; i >= 0; i--) {
        if (stopFractions[i] <= t) {
          targetIdx = i;
          break;
        }
      }
    }

    final targetStop = stopsById[stopIds[targetIdx]];
    final targetStopName = targetStop != null
        ? TransitPresentation.formatStopName(targetStop.name)
        : 'Stop ${targetIdx + 1}';

    return VehicleStationStatus(
      stationName: targetStopName,
      isAtStation: false,
      statusText: 'Approaching $targetStopName',
      towardsTerminus: towardsTerminus,
      vehicleIndex: vehicleIndex,
    );
  }

  /// Computes the dynamic remaining minutes for [vehicle] to reach [targetFraction] along the route.
  ///
  /// [tripDurationMinutes] is the total duration of the route in minutes.
  static int remainingMinutesToTarget({
    required SimulatedVehicle vehicle,
    required double targetFraction,
    required int tripDurationMinutes,
  }) {
    if (tripDurationMinutes <= 0) return 0;
    final t = vehicle.positionFraction;
    double remainingFraction;
    if (!vehicle.isReturnTrip) {
      remainingFraction = targetFraction >= t
          ? (targetFraction - t)
          : (1.0 - t + targetFraction);
    } else {
      remainingFraction = targetFraction <= t
          ? (t - targetFraction)
          : (t + (1.0 - targetFraction));
    }
    final mins = (remainingFraction * tripDurationMinutes).round();
    return mins.clamp(1, tripDurationMinutes);
  }
}
