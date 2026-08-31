import 'transit_direction.dart';

/// An immutable snapshot of a single in-service vehicle on a line.
///
/// `positionFraction` is a value in `[0.0, 1.0]` indicating how far
/// the vehicle is along its line, where 0.0 = origin station
/// (first id in [TransitLine.orderedStationIds]) and 1.0 = terminal
/// station (last id). The direction field tells the consumer whether
/// the fraction is increasing or decreasing over time.
///
/// **Honesty invariant:** the data layer MUST set [isLive] to `false`
/// for any vehicle that originates from a simulated data source, and
/// the presentation layer MUST use [isLive] to render a "Simulated"
/// pill rather than "Live" (per `docs/design.md` §8).
class LiveVehicle {
  /// Stable vehicle id, e.g. `"KJL-2847"`.
  final String vehicleId;

  /// The [TransitLine.id] this vehicle is running on.
  final String lineId;

  /// Direction the vehicle is currently travelling.
  final TransitDirection direction;

  /// Position along the line, clamped to `[0.0, 1.0]`.
  ///
  /// Stored clamped. Construct via [LiveVehicle.clamped] for
  /// untrusted inputs (e.g. mock timers that may overshoot).
  final double positionFraction;

  /// Estimated minutes until the vehicle reaches its terminal
  /// station. May be 0 when the vehicle is at the terminal.
  final int etaMinutes;

  /// When this snapshot was produced.
  final DateTime lastUpdated;

  /// `true` only if the snapshot originates from a real live feed.
  /// The mock data source MUST emit `false`.
  final bool isLive;

  const LiveVehicle({
    required this.vehicleId,
    required this.lineId,
    required this.direction,
    required this.positionFraction,
    required this.etaMinutes,
    required this.lastUpdated,
    required this.isLive,
  }) : assert(
         positionFraction >= 0.0 && positionFraction <= 1.0,
         'positionFraction must be in [0.0, 1.0]; got $positionFraction',
       );

  /// Constructs a [LiveVehicle] while clamping [rawPositionFraction]
  /// to the valid range `[0.0, 1.0]`. Use this when accepting values
  /// from external / computed sources that may overshoot (e.g. a
  /// running timer that increments past the terminal).
  factory LiveVehicle.clamped({
    required String vehicleId,
    required String lineId,
    required TransitDirection direction,
    required double rawPositionFraction,
    required int etaMinutes,
    required DateTime lastUpdated,
    required bool isLive,
  }) {
    final clamped = rawPositionFraction.clamp(0.0, 1.0).toDouble();
    return LiveVehicle(
      vehicleId: vehicleId,
      lineId: lineId,
      direction: direction,
      positionFraction: clamped,
      etaMinutes: etaMinutes < 0 ? 0 : etaMinutes,
      lastUpdated: lastUpdated,
      isLive: isLive,
    );
  }

  LiveVehicle copyWith({
    String? vehicleId,
    String? lineId,
    TransitDirection? direction,
    double? positionFraction,
    int? etaMinutes,
    DateTime? lastUpdated,
    bool? isLive,
  }) {
    return LiveVehicle(
      vehicleId: vehicleId ?? this.vehicleId,
      lineId: lineId ?? this.lineId,
      direction: direction ?? this.direction,
      positionFraction: positionFraction ?? this.positionFraction,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isLive: isLive ?? this.isLive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LiveVehicle &&
          runtimeType == other.runtimeType &&
          vehicleId == other.vehicleId &&
          lineId == other.lineId &&
          direction == other.direction &&
          positionFraction == other.positionFraction &&
          etaMinutes == other.etaMinutes &&
          lastUpdated == other.lastUpdated &&
          isLive == other.isLive;

  @override
  int get hashCode => Object.hash(
    vehicleId,
    lineId,
    direction,
    positionFraction,
    etaMinutes,
    lastUpdated,
    isLive,
  );

  @override
  String toString() =>
      'LiveVehicle(vehicleId: $vehicleId, lineId: $lineId, '
      'direction: $direction, positionFraction: $positionFraction, '
      'etaMinutes: $etaMinutes, isLive: $isLive)';
}
