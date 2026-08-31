import 'transit_direction.dart';

class LiveVehicle {
  final String vehicleId;

  final String lineId;

  final TransitDirection direction;

  final double positionFraction;

  final int etaMinutes;

  final DateTime lastUpdated;

  final bool isLive;

  final double? latitude;
  final double? longitude;
  final String? tripId;
  final String? label;

  const LiveVehicle({
    required this.vehicleId,
    required this.lineId,
    required this.direction,
    required this.positionFraction,
    required this.etaMinutes,
    required this.lastUpdated,
    required this.isLive,
    this.latitude,
    this.longitude,
    this.tripId,
    this.label,
  }) : assert(
         positionFraction >= 0.0 && positionFraction <= 1.0,
         'positionFraction must be in [0.0, 1.0]; got $positionFraction',
       );

  factory LiveVehicle.clamped({
    required String vehicleId,
    required String lineId,
    required TransitDirection direction,
    required double rawPositionFraction,
    required int etaMinutes,
    required DateTime lastUpdated,
    required bool isLive,
    double? latitude,
    double? longitude,
    String? tripId,
    String? label,
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
      latitude: latitude,
      longitude: longitude,
      tripId: tripId,
      label: label,
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
    double? latitude,
    double? longitude,
    String? tripId,
    String? label,
  }) {
    return LiveVehicle(
      vehicleId: vehicleId ?? this.vehicleId,
      lineId: lineId ?? this.lineId,
      direction: direction ?? this.direction,
      positionFraction: positionFraction ?? this.positionFraction,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isLive: isLive ?? this.isLive,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      tripId: tripId ?? this.tripId,
      label: label ?? this.label,
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
          isLive == other.isLive &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          tripId == other.tripId &&
          label == other.label;

  @override
  int get hashCode => Object.hash(
    vehicleId,
    lineId,
    direction,
    positionFraction,
    etaMinutes,
    lastUpdated,
    isLive,
    latitude,
    longitude,
    tripId,
    label,
  );

  @override
  String toString() =>
      'LiveVehicle(vehicleId: $vehicleId, lineId: $lineId, '
      'direction: $direction, positionFraction: $positionFraction, '
      'etaMinutes: $etaMinutes, isLive: $isLive)';
}
