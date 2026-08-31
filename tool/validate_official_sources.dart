import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:smartroute/features/tracking/data/datasources/official_gtfs_realtime_data_source.dart';

const _categories = <String>[
  'rapid-rail-kl',
  'rapid-bus-kl',
  'rapid-bus-mrtfeeder',
];

Future<void> main() async {
  final networkFile = File('assets/data/transit_network.json');
  if (!networkFile.existsSync()) {
    stderr.writeln('Bundled transit network is missing.');
    exitCode = 1;
    return;
  }
  final network = jsonDecode(await networkFile.readAsString()) as Map;
  final metadata = network['metadata'] as Map;
  stdout.writeln(
    'Bundled network: ${metadata['routeCount']} routes, '
    '${metadata['stopCount']} stops, ${metadata['patternCount']} patterns, '
    '${metadata['shapeRouteCount']} route shapes; '
    'generated ${metadata['generatedAt']}.',
  );

  final parser = OfficialGtfsRealtimeDataSource();
  var failed = false;
  for (final category in _categories) {
    final staticUri = Uri.https('api.data.gov.my', '/gtfs-static/prasarana', {
      'category': category,
    });
    final staticResponse = await http
        .get(staticUri)
        .timeout(const Duration(seconds: 30));
    stdout.writeln(
      '$category static: HTTP ${staticResponse.statusCode}, '
      '${staticResponse.bodyBytes.length} bytes.',
    );
    failed |=
        staticResponse.statusCode != 200 || staticResponse.bodyBytes.isEmpty;

    final realtimeUri = Uri.https(
      'api.data.gov.my',
      '/gtfs-realtime/vehicle-position/prasarana',
      {'category': category},
    );
    final realtimeResponse = await http
        .get(realtimeUri)
        .timeout(const Duration(seconds: 30));
    if (category == 'rapid-rail-kl') {
      stdout.writeln(
        '$category realtime: HTTP ${realtimeResponse.statusCode}; '
        'scheduled journey progress is used.',
      );
      continue;
    }
    if (realtimeResponse.statusCode != 200 ||
        realtimeResponse.bodyBytes.isEmpty) {
      stdout.writeln(
        '$category realtime: HTTP ${realtimeResponse.statusCode}, no payload.',
      );
      failed = true;
      continue;
    }
    final vehicles = parser.parse(realtimeResponse.bodyBytes);
    final latest = vehicles.isEmpty
        ? null
        : vehicles
              .map((vehicle) => vehicle.timestamp)
              .reduce((left, right) => left.isAfter(right) ? left : right);
    final fresh =
        latest != null &&
        DateTime.now().toUtc().difference(latest).abs() <=
            const Duration(minutes: 2);
    stdout.writeln(
      '$category realtime: ${vehicles.length} vehicle positions, '
      'latest ${latest?.toIso8601String() ?? 'none'}, fresh=$fresh.',
    );
  }
  if (failed) exitCode = 1;
}
