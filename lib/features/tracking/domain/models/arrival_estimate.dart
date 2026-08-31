/// An immutable estimate of an upcoming vehicle's arrival at a
/// specific platform of a specific station.
///
/// As with [LiveVehicle], [isLive] must be `false` for any estimate
/// produced by the mock data source.
class ArrivalEstimate {
  /// The [TrackingStation.id] this arrival is for.
  final String stationId;

  /// Platform code shown to the user, e.g. `"Platform 2"`.
  final String platformCode;

  /// The [TransitLine.id] servicing this platform.
  final String lineId;

  /// The [LiveVehicle.vehicleId] of the arriving vehicle.
  final String vehicleId;

  /// Estimated minutes until the vehicle arrives at the platform.
  /// May be 0 if the vehicle is currently at the platform.
  final int etaMinutes;

  /// `true` only for real live estimates. The mock data source
  /// MUST emit `false`.
  final bool isLive;

  const ArrivalEstimate({
    required this.stationId,
    required this.platformCode,
    required this.lineId,
    required this.vehicleId,
    required this.etaMinutes,
    required this.isLive,
  }) : assert(etaMinutes >= 0, 'etaMinutes must be >= 0; got $etaMinutes');

  ArrivalEstimate copyWith({
    String? stationId,
    String? platformCode,
    String? lineId,
    String? vehicleId,
    int? etaMinutes,
    bool? isLive,
  }) {
    return ArrivalEstimate(
      stationId: stationId ?? this.stationId,
      platformCode: platformCode ?? this.platformCode,
      lineId: lineId ?? this.lineId,
      vehicleId: vehicleId ?? this.vehicleId,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      isLive: isLive ?? this.isLive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArrivalEstimate &&
          runtimeType == other.runtimeType &&
          stationId == other.stationId &&
          platformCode == other.platformCode &&
          lineId == other.lineId &&
          vehicleId == other.vehicleId &&
          etaMinutes == other.etaMinutes &&
          isLive == other.isLive;

  @override
  int get hashCode => Object.hash(
    stationId,
    platformCode,
    lineId,
    vehicleId,
    etaMinutes,
    isLive,
  );

  @override
  String toString() =>
      'ArrivalEstimate(stationId: $stationId, '
      'platformCode: $platformCode, lineId: $lineId, '
      'vehicleId: $vehicleId, etaMinutes: $etaMinutes, isLive: $isLive)';
}
