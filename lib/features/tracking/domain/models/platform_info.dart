class PlatformInfo {
  final String stationId;

  final String platformCode;

  final String lineId;

  final bool isAccessible;

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

const Object _sentinel = Object();
