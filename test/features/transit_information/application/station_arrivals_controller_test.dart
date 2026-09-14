import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/transit_information/application/station_arrivals_controller.dart';
import 'package:smartroute/shared/models/transit_models.dart';

void main() {
  group('station-centric scheduled arrivals', () {
    test('combines, sorts, and deduplicates every line serving a station', () {
      final now = DateTime(2026, 9, 14, 8, 7);
      final network = _network([
        _pattern(
          id: 'line-a',
          routeId: 'line-a',
          tripId: 'a-trip',
          startSeconds: _secondsAt(8),
          endSeconds: _secondsAt(8, 30),
          headwaySeconds: 10 * 60,
        ),
        _pattern(
          id: 'line-a-duplicate',
          routeId: 'line-a',
          tripId: 'a-trip-copy',
          startSeconds: _secondsAt(8),
          endSeconds: _secondsAt(8, 30),
          headwaySeconds: 10 * 60,
        ),
        _pattern(
          id: 'line-b',
          routeId: 'line-b',
          tripId: 'b-trip',
          startSeconds: _secondsAt(8, 5),
          endSeconds: _secondsAt(8, 35),
          headwaySeconds: 10 * 60,
        ),
      ]);

      final arrivals = network.upcomingArrivalsForStop(
        _stationId,
        now: now,
        limit: 5,
      );

      expect(arrivals.map((arrival) => arrival.scheduledArrival), [
        DateTime(2026, 9, 14, 8, 10),
        DateTime(2026, 9, 14, 8, 15),
        DateTime(2026, 9, 14, 8, 20),
        DateTime(2026, 9, 14, 8, 25),
        DateTime(2026, 9, 14, 8, 30),
      ]);
      expect(arrivals.map((arrival) => arrival.routeId), [
        'line-a',
        'line-b',
        'line-a',
        'line-b',
        'line-a',
      ]);
      expect(arrivals.map((arrival) => arrival.dedupeKey).toSet().length, 5);
    });

    test('does not create tomorrow arrivals after service has ended today', () {
      final network = _network([
        _pattern(
          id: 'au3',
          routeId: 'line-a',
          tripId: 'au3-trip',
          startSeconds: _secondsAt(5, 30),
          endSeconds: _secondsAt(6),
          headwaySeconds: 30 * 60,
        ),
      ]);

      final arrivals = network.upcomingArrivalsForStop(
        _stationId,
        now: DateTime(2026, 9, 14, 8, 33),
      );

      expect(arrivals, isEmpty);
    });

    test('keeps only future arrivals when the controller refreshes', () async {
      var now = DateTime(2026, 9, 14, 8, 7);
      final controller = StationArrivalsController(
        network: _network([
          _pattern(
            id: 'line-a',
            routeId: 'line-a',
            tripId: 'a-trip',
            startSeconds: _secondsAt(8),
            endSeconds: _secondsAt(8, 30),
            headwaySeconds: 10 * 60,
          ),
        ]),
        stationId: _stationId,
        clock: () => now,
        refreshInterval: const Duration(days: 1),
      );
      addTearDown(controller.dispose);

      await controller.start();
      expect(
        controller.arrivals.first.scheduledArrival,
        DateTime(2026, 9, 14, 8, 10),
      );

      now = DateTime(2026, 9, 14, 8, 21);
      await controller.refresh();

      expect(controller.arrivals.map((arrival) => arrival.scheduledArrival), [
        DateTime(2026, 9, 14, 8, 30),
      ]);
      expect(controller.errorMessage, isNull);
    });

    test('includes an unfinished overnight service from the previous day', () {
      final network = _network([
        _pattern(
          id: 'overnight',
          routeId: 'line-a',
          tripId: 'overnight-trip',
          startSeconds: _secondsAt(23, 30),
          endSeconds: _secondsAt(6),
          headwaySeconds: 30 * 60,
        ),
      ]);

      final arrivals = network.upcomingArrivalsForStop(
        _stationId,
        now: DateTime(2026, 9, 14, 1),
      );

      expect(arrivals.first.scheduledArrival, DateTime(2026, 9, 14, 1, 30));
      expect(
        arrivals.first.scheduledArrival.isAfter(DateTime(2026, 9, 14, 1)),
        isTrue,
      );
    });
  });
}

const _stationId = 'station-1';

int _secondsAt(int hour, [int minute = 0]) =>
    hour * Duration.secondsPerHour + minute * Duration.secondsPerMinute;

TransitPattern _pattern({
  required String id,
  required String routeId,
  required String tripId,
  required int startSeconds,
  required int endSeconds,
  required int headwaySeconds,
}) => TransitPattern(
  id: id,
  routeId: routeId,
  gtfsTripId: tripId,
  direction: 0,
  headsign: 'Central',
  stopIds: const [_stationId],
  offsetMinutes: const [0],
  startSeconds: startSeconds,
  endSeconds: endSeconds,
  headwaySeconds: headwaySeconds,
);

TransitNetwork _network(List<TransitPattern> patterns) => TransitNetwork(
  metadata: TransitMetadata(
    generatedAt: DateTime(2026, 9, 14),
    publisher: 'test',
    licence: 'test',
    routeCount: 2,
    stopCount: 1,
    edgeCount: 0,
    patternCount: patterns.length,
    shapeRouteCount: 0,
    sources: const [],
  ),
  routes: const [
    TransitRoute(
      id: 'line-a',
      gtfsId: 'A',
      source: 'test',
      shortName: 'A',
      longName: 'Line A',
      mode: TransitMode.bus,
      colorHex: '0066CC',
      operatorName: 'Test',
      shape: [],
    ),
    TransitRoute(
      id: 'line-b',
      gtfsId: 'B',
      source: 'test',
      shortName: 'B',
      longName: 'Line B',
      mode: TransitMode.bus,
      colorHex: '00AA55',
      operatorName: 'Test',
      shape: [],
    ),
  ],
  stops: const [
    TransitStop(
      id: _stationId,
      gtfsId: 'station-1',
      source: 'test',
      name: 'Station One',
      latitude: 3,
      longitude: 101,
      routeIds: ['line-a', 'line-b'],
    ),
  ],
  edges: const [],
  patterns: patterns,
);
