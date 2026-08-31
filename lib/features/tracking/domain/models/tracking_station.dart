/// An immutable, pure-Dart representation of a single station on a
/// transit line.
///
/// `latitude` / `longitude` are real-world WGS84 coordinates sourced
/// from the data.gov.my GTFS feed (Phase 2). They are kept on the
/// domain model so the presentation layer can project them onto the
/// network map canvas without re-fetching.
class TrackingStation {
  /// Stable id, e.g. `"kj-kl-sentral"`. Must match the id referenced
  /// in [TransitLine.orderedStationIds].
  final String id;

  /// User-facing name, e.g. `"KL Sentral"`.
  final String name;

  /// The [TransitLine.id] this station belongs to.
  final String lineId;

  /// Zero-based position along the line, 0 = origin, N-1 = terminal.
  final int sequence;

  /// Real-world WGS84 latitude. May be 0.0 if not yet populated
  /// (e.g. before the Phase 2 GTFS import runs).
  final double latitude;

  /// Real-world WGS84 longitude. May be 0.0 if not yet populated.
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
