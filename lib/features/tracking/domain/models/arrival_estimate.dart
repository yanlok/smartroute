class ArrivalEstimate {
  final String stationId;

  final String platformCode;

  final String lineId;

  final String vehicleId;

  final int etaMinutes;

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
