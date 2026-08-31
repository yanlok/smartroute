/// An immutable description of a single platform at a station,
/// including accessibility and optional notes.
///
/// Sourced from the GTFS static feed's `pathways.txt` /
/// `levels.txt` (Phase 2); kept on the domain model so the
/// presentation layer can render accessibility icons / notes
/// without re-querying.
class PlatformInfo {
  /// The [TrackingStation.id] this platform belongs to.
  final String stationId;

  /// Platform code shown to the user, e.g. `"Platform 2"`.
  final String platformCode;

  /// The [TransitLine.id] servicing this platform.
  final String lineId;

  /// Whether the platform is wheelchair / step-free accessible.
  final bool isAccessible;

  /// Free-form note, e.g. "Use lift from concourse".
  final String? notes;

  const PlatformInfo({
    required this.stationId,
    required this.platformCode,
    required this.lineId,
    required this.isAccessible,
    this.notes,
  });

  PlatformInfo copyWith({
    String? stationId,
    String? platformCode,
    String? lineId,
    bool? isAccessible,
    Object? notes = _sentinel,
  }) {
    return PlatformInfo(
      stationId: stationId ?? this.stationId,
      platformCode: platformCode ?? this.platformCode,
      lineId: lineId ?? this.lineId,
      isAccessible: isAccessible ?? this.isAccessible,
      notes: identical(notes, _sentinel) ? this.notes : notes as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlatformInfo &&
          runtimeType == other.runtimeType &&
          stationId == other.stationId &&
          platformCode == other.platformCode &&
          lineId == other.lineId &&
          isAccessible == other.isAccessible &&
          notes == other.notes;

  @override
  int get hashCode =>
      Object.hash(stationId, platformCode, lineId, isAccessible, notes);

  @override
  String toString() =>
      'PlatformInfo(stationId: $stationId, '
      'platformCode: $platformCode, lineId: $lineId, '
      'isAccessible: $isAccessible)';
}

/// Sentinel object used by [PlatformInfo.copyWith] to distinguish
/// "argument omitted" from "argument explicitly null", so callers
/// can clear an optional field by passing `null` explicitly.
const Object _sentinel = Object();
