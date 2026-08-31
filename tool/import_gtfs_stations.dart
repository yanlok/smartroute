/// One-time import script.
///
/// Reads the data.gov.my Prasarana GTFS static feed
/// (rapid-rail-kl) and emits a generated Dart file
/// `lib/features/tracking/data/datasources/transit_line_static_data.dart`
/// that is committed to git. The app then runs fully offline.
///
/// Run with:
///   dart run tool/import_gtfs_stations.dart
///
/// Source feeds (data.gov.my, public domain):
///   - https://api.data.gov.my/gtfs-static/prasarana?category=rapid-rail-kl
///   - https://api.data.gov.my/gtfs-static/prasarana?category=rapid-bus-kl
///   - https://api.data.gov.my/gtfs-static/prasarana?category=rapid-bus-mrtfeeder
library;

import 'dart:io';

// ─── Inputs (relative to repo root) ────────────────────────────────────────

const String _repoRoot = '.';
const String _gtfsDir = '$_repoRoot/data/gtfs/rapid-rail-kl';
const String _outputPath =
    '$_repoRoot/lib/features/tracking/data/datasources/transit_line_static_data.dart';

/// Date stamped into the generated file header so reviewers know
/// which feed snapshot produced it.
const String _generatedDate = '2026-08-26';

// ─── Mapping tables ────────────────────────────────────────────────────────

/// Maps GTFS `route_id` → our internal [TransitLine.id].
///
/// We currently keep them identical (lowercased) for traceability.
/// Maps the GTFS `route_id` value as it appears in `stops.txt`
/// → our internal [TransitLine.id].
///
/// **Important**: the data.gov.my feed is inconsistent.
/// `routes.txt` uses `KGL` and `PYL` as route_ids, but `stops.txt`
/// labels the MRT Kajang Line stations with `route_id = "MRT"`
/// (same value as the `category` field) and the MRT Putrajaya
/// Line stations with `route_id = "PYL"`. This map normalises
/// both spellings to the canonical `kgl` id.
const Map<String, String> _routeIdAlias = {
  'kj': 'kj',
  'ag': 'ag',
  'ph': 'ph',
  // MRT Kajang Line: stops.txt says "MRT", routes.txt says "KGL".
  'kgl': 'kgl',
  'mrt': 'kgl',
  'pyl': 'pyl',
  'mr': 'mr',
  'brt': 'brt',
  'sa': 'sa',
};

/// Maps our canonical line id → `AppColors` token (per
/// `docs/design.md` §3). This is the single place where raw
/// route colors are converted to design tokens. Do NOT scatter
/// hex strings through widgets.
const Map<String, String> _routeColorToken = {
  'kj': 'kjLine',
  'ag': 'spLine', // Ampang Line shares red palette with Sri Petaling.
  'ph': 'spLine', // Sri Petaling Line (Putra Heights terminus).
  'kgl': 'mkLine', // MRT Kajang Line.
  'pyl': 'mpLine', // MRT Putrajaya Line.
  'mr': 'mlLine', // KL Monorail.
  'brt': 'brLine', // BRT Sunway.
  'sa': 'kjLine', // LRT Shah Alam — design has no dedicated token yet;
                   // falls back to a transit blue palette.
};

/// Maps our canonical line id → our [TransitMode] enum.
const Map<String, String> _routeMode = {
  'kj': 'lrt',
  'ag': 'lrt',
  'ph': 'lrt',
  'sa': 'lrt',
  'kgl': 'mrt',
  'pyl': 'mrt',
  'mr': 'monorail',
  'brt': 'brt',
};

/// Display order for the line picker.
const List<String> _lineOrder = [
  'kj',
  'ag',
  'ph',
  'sa',
  'kgl',
  'pyl',
  'mr',
  'brt',
];

/// User-facing short code shown in the line badge.
/// Falls back to the uppercased route_id if not in this table.
const Map<String, String> _shortName = {
  'kj': 'KJ',
  'ag': 'AG',
  'ph': 'PH',
  'sa': 'SA',
  'kgl': 'MRT-K',
  'pyl': 'MRT-P',
  'mr': 'MR',
  'brt': 'BRT',
};

/// User-facing full name.
const Map<String, String> _longName = {
  'kj': 'Kelana Jaya Line',
  'ag': 'Ampang Line',
  'ph': 'Sri Petaling Line',
  'sa': 'Shah Alam Line',
  'kgl': 'MRT Kajang Line',
  'pyl': 'MRT Putrajaya Line',
  'mr': 'KL Monorail',
  'brt': 'BRT Sunway Line',
};

// ─── CSV parsing ───────────────────────────────────────────────────────────

/// Splits a single GTFS CSV line into fields. GTFS fields are
/// comma-separated; we do not need to handle quoted commas because
/// the only field that contains commas (`geometry` in `stops.txt`)
/// is JSON-shaped and we skip it.
List<String> _splitCsv(String line) {
  // GTFS feeds on Windows sometimes have CRLF; trim trailing CR.
  if (line.endsWith('\r')) {
    line = line.substring(0, line.length - 1);
  }
  return line.split(',');
}

/// Reads a GTFS file as `List<List<String>>` of fields, with the
/// first row treated as the header.
List<List<String>> _readCsv(String path) {
  final raw = File(path).readAsLinesSync();
  return raw.map(_splitCsv).toList(growable: false);
}

// ─── Domain loaders ────────────────────────────────────────────────────────

class _RawStop {
  _RawStop({
    required this.routeId,
    required this.stopId,
    required this.name,
    required this.lat,
    required this.lon,
  });
  final String routeId;
  final String stopId;
  final String name;
  final double lat;
  final double lon;
}

/// Parses `stops.txt` and groups stations by GTFS `route_id`.
/// Stops are returned in the order they appear in the file, which
/// matches the CSV row order (not the canonical line sequence — see
/// [_loadStationSequence] for that).
Map<String, List<_RawStop>> _loadStopsByRoute() {
  final rows = _readCsv('$_gtfsDir/stops.txt');
  final header = rows.first;
  final stopIdIdx = header.indexOf('stop_id');
  final nameIdx = header.indexOf('stop_name');
  final latIdx = header.indexOf('stop_lat');
  final lonIdx = header.indexOf('stop_lon');
  final routeIdIdx = header.indexOf('route_id');

  if ([stopIdIdx, nameIdx, latIdx, lonIdx, routeIdIdx].contains(-1)) {
    throw StateError('stops.txt is missing one of the required columns');
  }

  final out = <String, List<_RawStop>>{};
  for (final row in rows.skip(1)) {
    if (row.length <= routeIdIdx) continue;
    final rawRouteId = row[routeIdIdx].toLowerCase();
    final canonicalId = _routeIdAlias[rawRouteId];
    if (canonicalId == null) continue;
    out.putIfAbsent(canonicalId, () => <_RawStop>[]);
    out[canonicalId]!.add(
      _RawStop(
        routeId: canonicalId,
        stopId: row[stopIdIdx].toLowerCase(),
        name: _titleCase(row[nameIdx]),
        lat: double.tryParse(row[latIdx]) ?? 0.0,
        lon: double.tryParse(row[lonIdx]) ?? 0.0,
      ),
    );
  }
  return out;
}

/// Reads the `trips.txt` to extract a single representative
/// `shape_id` per route. We pick the first trip for direction 0
/// (forward) so the line shape runs origin → terminal.
Map<String, String> _loadForwardShapeIds() {
  final rows = _readCsv('$_gtfsDir/trips.txt');
  final header = rows.first;
  final routeIdIdx = header.indexOf('route_id');
  final dirIdx = header.indexOf('direction_id');
  final shapeIdx = header.indexOf('shape_id');

  final out = <String, String>{};
  for (final row in rows.skip(1)) {
    if (row.length <= shapeIdx) continue;
    final rawRouteId = row[routeIdIdx].toLowerCase();
    final canonicalId = _routeIdAlias[rawRouteId];
    if (canonicalId == null) continue;
    if (out.containsKey(canonicalId)) continue;
    if (row[dirIdx] == '0') {
      out[canonicalId] = row[shapeIdx];
    }
  }
  return out;
}

/// Reads `shapes.txt` and groups (lat, lon) points by `shape_id`,
/// preserving `shape_pt_sequence` order.
Map<String, List<List<double>>> _loadShapePoints() {
  final rows = _readCsv('$_gtfsDir/shapes.txt');
  final header = rows.first;
  final shapeIdIdx = header.indexOf('shape_id');
  final latIdx = header.indexOf('shape_pt_lat');
  final lonIdx = header.indexOf('shape_pt_lon');
  final seqIdx = header.indexOf('shape_pt_sequence');

  final grouped = <String, List<List<double>>>{};
  for (final row in rows.skip(1)) {
    if (row.length <= seqIdx) continue;
    final shapeId = row[shapeIdIdx];
    final lat = double.tryParse(row[latIdx]);
    final lon = double.tryParse(row[lonIdx]);
    if (lat == null || lon == null) continue;
    grouped.putIfAbsent(shapeId, () => <List<double>>[]);
    grouped[shapeId]!.add([lat, lon]);
  }
  return grouped;
}

/// Cross-references `stops.txt` (which gives us lat/lon per stop)
/// with the ordered `shape_id` points to produce a canonical
/// station sequence per route. We use a nearest-point-on-shape
/// heuristic: for each stop, find the shape point closest to its
/// lat/lon and record the order in which those shape points appear.
Map<String, List<String>> _loadStationSequence(
  Map<String, List<_RawStop>> stopsByRoute,
  Map<String, String> forwardShapeIdByRoute,
  Map<String, List<List<double>>> shapePointsByShapeId,
) {
  final out = <String, List<String>>{};
  for (final entry in stopsByRoute.entries) {
    final routeId = entry.key;
    final stops = entry.value;
    final shapeId = forwardShapeIdByRoute[routeId];
    if (shapeId == null) {
      out[routeId] = stops.map((s) => s.stopId).toList();
      continue;
    }
    final shapePts = shapePointsByShapeId[shapeId];
    if (shapePts == null || shapePts.isEmpty) {
      out[routeId] = stops.map((s) => s.stopId).toList();
      continue;
    }
    // For each stop, find the index on the shape whose point is
    // closest. That index gives the canonical sequence.
    final indexedStops = <_IndexedStop>[];
    for (final stop in stops) {
      var bestIdx = 0;
      var bestDist = double.infinity;
      for (var i = 0; i < shapePts.length; i++) {
        final d = _haversine(
          stop.lat,
          stop.lon,
          shapePts[i][0],
          shapePts[i][1],
        );
        if (d < bestDist) {
          bestDist = d;
          bestIdx = i;
        }
      }
      indexedStops.add(_IndexedStop(stop.stopId, bestIdx));
    }
    indexedStops.sort((a, b) => a.shapeIndex.compareTo(b.shapeIndex));
    out[routeId] = indexedStops.map((s) => s.stopId).toList();
  }
  return out;
}

class _IndexedStop {
  _IndexedStop(this.stopId, this.shapeIndex);
  final String stopId;
  final int shapeIndex;
}

/// Very rough haversine in degrees (small distance). Good enough
/// for ordering nearby shape points; we are not measuring routes.
double _haversine(double lat1, double lon1, double lat2, double lon2) {
  final dLat = lat2 - lat1;
  final dLon = lon2 - lon1;
  return dLat * dLat + dLon * dLon;
}

String _titleCase(String s) {
  if (s.isEmpty) return s;
  return s
      .toLowerCase()
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

// ─── Output rendering ──────────────────────────────────────────────────────

void _writeOutput(
  Map<String, List<_RawStop>> stopsByRoute,
  Map<String, List<String>> sequenceByRoute,
  Map<String, List<List<double>>> shapePointsByShapeId,
  Map<String, String> forwardShapeIdByRoute,
) {
  final buf = StringBuffer();

  buf.writeln('// GENERATED FILE — DO NOT EDIT BY HAND.');
  buf.writeln('//');
  buf.writeln('// Generated by: tool/import_gtfs_stations.dart');
  buf.writeln(
    '// Source feed:  https://api.data.gov.my/gtfs-static/prasarana?category=rapid-rail-kl',
  );
  buf.writeln('// Generated on: $_generatedDate');
  buf.writeln('//');
  buf.writeln('// This file is the static, in-app source of truth for the');
  buf.writeln('// Klang Valley transit network used by the Real-Time Transit');
  buf.writeln('// Tracking module. It is regenerated only when the upstream');
  buf.writeln('// GTFS feed is refreshed; the app itself runs fully offline.');
  buf.writeln('//');
  buf.writeln('// data.gov.my feeds are public domain (no licence required).');
  buf.writeln('');
  buf.writeln("import '../../domain/models/transit_line.dart';");
  buf.writeln("import '../../domain/models/transit_mode.dart';");
  buf.writeln("import '../../domain/models/tracking_station.dart';");
  buf.writeln('');

  // ── TransitLine list ──
  buf.writeln('/// The list of transit lines supported by the app, in display');
  buf.writeln('/// order. Each line uses the short GTFS `route_id` as its id.');
  buf.writeln('const List<TransitLine> kTransitLines = <TransitLine>[');
  for (final routeId in _lineOrder) {
    if (!sequenceByRoute.containsKey(routeId)) continue;
    final orderedIds = sequenceByRoute[routeId]!;
    final mode = _routeMode[routeId] ?? 'lrt';
    final color = _routeColorToken[routeId] ?? 'kjLine';
    final short = _shortName[routeId] ?? routeId.toUpperCase();
    final long = _longName[routeId] ?? routeId;
    buf.writeln('  TransitLine(');
    buf.writeln("    id: '$routeId',");
    buf.writeln("    code: '$short',");
    buf.writeln("    name: '$long',");
    buf.writeln('    mode: TransitMode.$mode,');
    buf.writeln("    colorToken: '$color',");
    buf.writeln('    orderedStationIds: <String>[');
    for (final sid in orderedIds) {
      buf.writeln("      '$sid',");
    }
    buf.writeln('    ],');
    buf.writeln('  ),');
  }
  buf.writeln('];');
  buf.writeln('');

  // ── All stations (deduplicated by stop_id) ──
  buf.writeln('/// The complete list of stations across all lines.');
  buf.writeln(
    '/// Stations that belong to multiple lines appear once per line.',
  );
  buf.writeln('const List<TrackingStation> kAllStations = <TrackingStation>[');
  for (final routeId in _lineOrder) {
    final stops = stopsByRoute[routeId];
    if (stops == null) continue;
    final seqMap = <String, int>{};
    final ordered = sequenceByRoute[routeId] ?? const <String>[];
    for (var i = 0; i < ordered.length; i++) {
      seqMap[ordered[i]] = i;
    }
    for (final stop in stops) {
      final seq = seqMap[stop.stopId] ?? 0;
      buf.writeln('  TrackingStation(');
      buf.writeln("    id: '${stop.stopId}',");
      buf.writeln("    name: '${_escape(stop.name)}',");
      buf.writeln("    lineId: '$routeId',");
      buf.writeln('    sequence: $seq,');
      buf.writeln('    latitude: ${stop.lat},');
      buf.writeln('    longitude: ${stop.lon},');
      buf.writeln('  ),');
    }
  }
  buf.writeln('];');
  buf.writeln('');

  // ── Line shapes (lat/lon sequences) ──
  buf.writeln('/// Map of line id → ordered list of [lat, lon] points that');
  buf.writeln('/// trace the line on a map. Sourced from GTFS `shapes.txt`.');
  buf.writeln(
    'const Map<String, List<List<double>>> kLineShapes = <String, List<List<double>>>{',
  );
  for (final routeId in _lineOrder) {
    final shapeId = forwardShapeIdByRoute[routeId];
    if (shapeId == null) continue;
    final pts = shapePointsByShapeId[shapeId];
    if (pts == null || pts.isEmpty) continue;
    buf.writeln("  '$routeId': <List<double>>[");
    for (final p in pts) {
      buf.writeln('    [${p[0]}, ${p[1]}],');
    }
    buf.writeln('  ],');
  }
  buf.writeln('};');
  buf.writeln('');

  // ── Id alias map (for cross-module bridging to YL's DB) ──
  buf.writeln('/// Cross-module id alias map. GTFS `route_id` → YL DB');
  buf.writeln('/// `transit_lines.id`. Use this if a future shared');
  buf.writeln('/// contract requires interop with the Planner module.');
  buf.writeln('const Map<String, String> kLineIdAlias = <String, String>{');
  buf.writeln("  'kj': 'kelana-jaya',");
  buf.writeln("  'ag': 'ampang',");
  buf.writeln("  'ph': 'sri-petaling',");
  buf.writeln("  'sa': 'shah-alam',");
  buf.writeln("  'kgl': 'kajang',");
  buf.writeln("  'pyl': 'putrajaya',");
  buf.writeln("  'mr': 'monorail',");
  buf.writeln("  'brt': 'brt-sunway',");
  buf.writeln('};');

  File(_outputPath).writeAsStringSync(buf.toString());
  stdout.writeln('Wrote: $_outputPath');
  stdout.writeln('Lines: ${sequenceByRoute.length}');
  stdout.writeln(
    'Stations (incl. duplicates across lines): '
    '${stopsByRoute.values.fold<int>(0, (a, b) => a + b.length)}',
  );
}

String _escape(String s) => s.replaceAll(r"\'", r"\'").replaceAll(r"'", r"\'");

// ─── main ──────────────────────────────────────────────────────────────────

void main() {
  if (!Directory(_gtfsDir).existsSync()) {
    stderr.writeln('Missing input directory: $_gtfsDir');
    stderr.writeln('Download the GTFS feed and unzip it first.');
    exit(1);
  }

  final stopsByRoute = _loadStopsByRoute();
  final forwardShapeIds = _loadForwardShapeIds();
  final shapePoints = _loadShapePoints();
  final sequences = _loadStationSequence(
    stopsByRoute,
    forwardShapeIds,
    shapePoints,
  );

  _writeOutput(stopsByRoute, sequences, shapePoints, forwardShapeIds);
}
