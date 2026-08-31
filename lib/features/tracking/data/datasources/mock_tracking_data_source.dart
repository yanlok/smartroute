import 'dart:async';
import 'dart:math';

import '../../domain/models/arrival_estimate.dart';
import '../../domain/models/live_vehicle.dart';
import '../../domain/models/tracking_station.dart';
import '../../domain/models/transit_direction.dart';
import 'mock_line_directory_data_source.dart';

/// In-app, timer-driven mock implementation of live vehicle
/// telemetry. Every emitted `LiveVehicle` and `ArrivalEstimate`
/// has `isLive == false` (per `docs/design.md` §8 — we never
/// present simulated motion as production live data).
///
/// **Lifecycle**: each call to [watchVehicles] / [watchArrivals]
/// creates an independent `Timer.periodic` that is cancelled when
/// the consumer cancels its `StreamSubscription`. The data
/// source is therefore safe to use from multiple controllers
/// concurrently.
class MockTrackingDataSource {
  final MockLineDirectoryDataSource _directory;

  /// Tunable simulation speed. Defaults to 1.0 (one full trip
  /// takes ~`_avgTripMinutes` of wall-clock minutes, compressed
  /// into a sequence of ticks). Increase to speed up the demo.
  final double speedFactor;

  /// Average trip duration in minutes, used to derive ETAs.
  static const int _avgTripMinutes = 18;

  /// Number of simultaneous simulated trains on a line.
  static const int _trainsPerLine = 3;

  MockTrackingDataSource({
    MockLineDirectoryDataSource? directory,
    this.speedFactor = 1.0,
  }) : _directory = directory ?? const MockLineDirectoryDataSource();

  /// Emits a fresh snapshot of the line's simulated trains every
  /// [tickInterval]. The list always contains the same number of
  /// vehicles ([_trainsPerLine]) — only their positions and ETAs
  /// change.
  Stream<List<LiveVehicle>> watchVehicles(
    String lineId, {
    Duration tickInterval = const Duration(milliseconds: 300),
  }) async* {
    final stations = _directory.getStationsForLineSync(lineId);
    if (stations.isEmpty) {
      yield const <LiveVehicle>[];
      return;
    }

    final state = _seedState(lineId);
    // Per-tick fraction delta. One full trip = 1.0 of position,
    // spread over (avgTripMinutes minutes of ticks).
    final perTickDelta = _perTickDelta(tickInterval);

    yield _vehicleSnapshot(state, lineId);

    final timer = Timer.periodic(tickInterval, (_) {
      _advance(state, perTickDelta);
    });

    try {
      // Drive the stream manually so the timer keeps running until
      // the consumer cancels the subscription.
      while (true) {
        await Future<void>.delayed(tickInterval);
        yield _vehicleSnapshot(state, lineId);
      }
    } finally {
      timer.cancel();
    }
  }

  /// Emits upcoming arrivals at the given station. ETA is derived
  /// from each train's current position relative to the station.
  Stream<List<ArrivalEstimate>> watchArrivals({
    required String lineId,
    required String stationId,
    Duration tickInterval = const Duration(seconds: 10),
  }) async* {
    final stations = _directory.getStationsForLineSync(lineId);
    TrackingStation? station;
    for (final s in stations) {
      if (s.id == stationId) {
        station = s;
        break;
      }
    }
    if (station == null) {
      yield const <ArrivalEstimate>[];
      return;
    }

    final state = _seedState(lineId);
    final perTickDelta = _perTickDelta(tickInterval);

    yield _arrivalsSnapshot(state, lineId, station);

    final timer = Timer.periodic(tickInterval, (_) {
      _advance(state, perTickDelta);
    });

    try {
      while (true) {
        await Future<void>.delayed(tickInterval);
        yield _arrivalsSnapshot(state, lineId, station);
      }
    } finally {
      timer.cancel();
    }
  }

  // ── Internal state ──────────────────────────────────────────────────

  double _perTickDelta(Duration tickInterval) {
    // Total ticks in `_avgTripMinutes` minutes for one full trip.
    final ticksPerTrip =
        (_avgTripMinutes * 60 * 1000) / tickInterval.inMilliseconds;
    return (1.0 / ticksPerTrip) * speedFactor;
  }

  List<_TrainState> _seedState(String lineId) {
    final baseSeed = lineId.hashCode;
    return List<_TrainState>.generate(_trainsPerLine, (i) {
      // Spread initial positions evenly along the line.
      final initialFraction = (i + 0.5) / _trainsPerLine;
      final direction = i.isEven
          ? TransitDirection.forward
          : TransitDirection.reverse;
      final vehicleNumber = 1000 + (baseSeed.abs() % 9000) + i;
      return _TrainState(
        vehicleId: '${lineId.toUpperCase()}-$vehicleNumber',
        lineId: lineId,
        direction: direction,
        positionFraction: initialFraction,
      );
    });
  }

  void _advance(List<_TrainState> state, double delta) {
    for (final t in state) {
      if (t.direction == TransitDirection.forward) {
        t.positionFraction += delta;
        if (t.positionFraction >= 1.0) {
          t.positionFraction = 1.0;
          t.direction = TransitDirection.reverse;
        }
      } else {
        t.positionFraction -= delta;
        if (t.positionFraction <= 0.0) {
          t.positionFraction = 0.0;
          t.direction = TransitDirection.forward;
        }
      }
    }
  }

  List<LiveVehicle> _vehicleSnapshot(List<_TrainState> state, String lineId) {
    final now = DateTime.now();
    return [
      for (final t in state)
        LiveVehicle.clamped(
          vehicleId: t.vehicleId,
          lineId: lineId,
          direction: t.direction,
          rawPositionFraction: t.positionFraction,
          etaMinutes: _etaMinutes(t),
          lastUpdated: now,
          isLive: false,
        ),
    ];
  }

  List<ArrivalEstimate> _arrivalsSnapshot(
    List<_TrainState> state,
    String lineId,
    TrackingStation station,
  ) {
    // Treat the line as a unit segment from origin (0.0) to
    // terminal (1.0). The station sits at its `sequence / N`
    // fraction along that segment. For a 37-station line, the
    // 0-based `sequence` ranges from 0 to 36, so we divide by N-1.
    // When N == 1 we use 0.5 to avoid div-by-zero.
    final n = _directory.getStationsForLineSync(lineId).length;
    final denom = max(1, n - 1);
    final stationFraction = station.sequence / denom;

    final results = <ArrivalEstimate>[];
    for (var i = 0; i < state.length; i++) {
      final t = state[i];
      double ahead;
      if (t.direction == TransitDirection.forward) {
        ahead = stationFraction - t.positionFraction;
        if (ahead < 0) ahead += 1.0; // wrap-around to next trip
      } else {
        ahead = t.positionFraction - stationFraction;
        if (ahead < 0) ahead += 1.0;
      }
      final eta = (ahead * _avgTripMinutes).round();
      if (eta <= 0) continue;
      results.add(
        ArrivalEstimate(
          stationId: station.id,
          platformCode: 'Platform ${(i % 2) + 1}',
          lineId: lineId,
          vehicleId: t.vehicleId,
          etaMinutes: eta,
          isLive: false,
        ),
      );
    }
    results.sort((a, b) => a.etaMinutes.compareTo(b.etaMinutes));
    return results.take(5).toList();
  }

  int _etaMinutes(_TrainState t) {
    final remaining = t.direction == TransitDirection.forward
        ? 1.0 - t.positionFraction
        : t.positionFraction;
    return max(0, (remaining * _avgTripMinutes).round());
  }
}

class _TrainState {
  _TrainState({
    required this.vehicleId,
    required this.lineId,
    required this.direction,
    required this.positionFraction,
  });

  final String vehicleId;
  final String lineId;
  TransitDirection direction;
  double positionFraction;
}
