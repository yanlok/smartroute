import 'transit_mode.dart';

class TransitLine {
  final String id;

  final String code;

  final String name;

  final TransitMode mode;

  final String colorToken;

  final List<String> orderedStationIds;

  const TransitLine({
    required this.id,
    required this.code,
    required this.name,
    required this.mode,
    required this.colorToken,
    required this.orderedStationIds,
  });

  int get stationCount => orderedStationIds.length;

  TransitLine copyWith({
    String? id,
    String? code,
    String? name,
    TransitMode? mode,
    String? colorToken,
    List<String>? orderedStationIds,
  }) {
    return TransitLine(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      mode: mode ?? this.mode,
      colorToken: colorToken ?? this.colorToken,
      orderedStationIds: orderedStationIds ?? this.orderedStationIds,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransitLine &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          code == other.code &&
          name == other.name &&
          mode == other.mode &&
          colorToken == other.colorToken &&
          _listEquals(orderedStationIds, other.orderedStationIds);

  @override
  int get hashCode => Object.hash(
    id,
    code,
    name,
    mode,
    colorToken,
    Object.hashAll(orderedStationIds),
  );

  @override
  String toString() =>
      'TransitLine(id: $id, code: $code, name: $name, mode: $mode, '
      'stationCount: $stationCount)';
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
