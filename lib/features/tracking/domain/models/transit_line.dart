import 'transit_mode.dart';

/// An immutable, pure-Dart representation of a public-transit line
/// (e.g. Kelana Jaya, MRT Kajang, Sri Petaling, MRT Putrajaya,
/// KL Monorail, BRT Sunway, Rapid KL bus).
///
/// Domain models intentionally avoid:
///   * raw hex color strings (use [colorToken] — e.g. `"kjLine"` —
///     and let the presentation layer map it to `AppColors.*`);
///   * any Flutter / SDK dependencies (so this file is pure Dart and
///     can be referenced from `lib/shared/contracts/` later).
class TransitLine {
  /// Stable internal id, e.g. `"kj"`, `"mk"`, `"sp"`, `"mp"`, `"ml"`,
  /// `"br"`, `"bus"`. Must remain stable across releases because
  /// cross-module contracts key on it.
  final String id;

  /// Short user-facing code, e.g. `"KJ"`, `"MRT-KJ"`.
  final String code;

  /// Full user-facing name, e.g. `"Kelana Jaya Line"`.
  final String name;

  /// High-level transport mode.
  final TransitMode mode;

  /// Token name in `AppColors` used to colour this line.
  /// e.g. `"kjLine"`, `"mkLine"`, `"spLine"`, `"mpLine"`, `"mlLine"`,
  /// `"brLine"` / `"busLine"`. The presentation layer is responsible
  /// for mapping the token to an actual `Color`.
  final String colorToken;

  /// Ordered list of station ids along the line, from sequence 0
  /// (origin / terminus A) to sequence N - 1 (terminus B).
  ///
  /// Order is significant: a [LiveVehicle.positionFraction] of 0.0
  /// corresponds to [orderedStationIds].first and 1.0 to the last.
  final List<String> orderedStationIds;

  const TransitLine({
    required this.id,
    required this.code,
    required this.name,
    required this.mode,
    required this.colorToken,
    required this.orderedStationIds,
  });

  /// Number of stations on the line.
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
