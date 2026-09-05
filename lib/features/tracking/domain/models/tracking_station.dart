class TrackingStation {
  final String id;

  final String name;

  final String lineId;

  final int sequence;

  final double latitude;

  final double longitude;

  const TrackingStation({
    required this.id,
    required this.name,
    required this.lineId,
    required this.sequence,
    this.latitude = 0.0,
    this.longitude = 0.0,
  });

  TrackingStation copyWith({
    String? id,
    String? name,
    String? lineId,
    int? sequence,
    double? latitude,
    double? longitude,
  }) {
    return TrackingStation(
      id: id ?? this.id,
      name: name ?? this.name,
      lineId: lineId ?? this.lineId,
      sequence: sequence ?? this.sequence,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrackingStation &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          lineId == other.lineId &&
          sequence == other.sequence &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode =>
      Object.hash(id, name, lineId, sequence, latitude, longitude);

  @override
  String toString() =>
      'TrackingStation(id: $id, name: $name, lineId: $lineId, sequence: $sequence)';
}
