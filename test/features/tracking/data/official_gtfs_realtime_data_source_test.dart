import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gtfs_realtime_bindings/gtfs_realtime_bindings.dart';
import 'package:smartroute/features/tracking/data/datasources/official_gtfs_realtime_data_source.dart';

void main() {
  test('parses official GTFS-Realtime vehicle identity and coordinates', () {
    final message = FeedMessage(
      header: FeedHeader(gtfsRealtimeVersion: '2.0'),
      entity: [
        FeedEntity(
          id: 'entity-1',
          vehicle: VehiclePosition(
            trip: TripDescriptor(
              tripId: 'trip-55',
              routeId: 'route-10',
              directionId: 1,
            ),
            position: Position(
              latitude: 3.139,
              longitude: 101.6869,
              bearing: 90,
              speed: 8,
            ),
            vehicle: VehicleDescriptor(id: 'bus-22', label: 'WVC 22'),
          ),
        ),
      ],
    );
    final source = OfficialGtfsRealtimeDataSource(
      fetchBytes: (_) async => Uint8List(0),
    );

    final vehicles = source.parse(Uint8List.fromList(message.writeToBuffer()));

    expect(vehicles, hasLength(1));
    expect(vehicles.single.routeId, 'route-10');
    expect(vehicles.single.tripId, 'trip-55');
    expect(vehicles.single.vehicleId, 'bus-22');
    expect(vehicles.single.label, 'WVC 22');
    expect(vehicles.single.directionId, 1);
    expect(vehicles.single.latitude, closeTo(3.139, 0.00001));
    expect(vehicles.single.longitude, closeTo(101.6869, 0.00001));
  });

  test('ignores non-vehicle and incomplete entities', () {
    final message = FeedMessage(
      header: FeedHeader(gtfsRealtimeVersion: '2.0'),
      entity: [
        FeedEntity(id: 'empty'),
        FeedEntity(
          id: 'no-position',
          vehicle: VehiclePosition(trip: TripDescriptor(routeId: 'route-10')),
        ),
      ],
    );
    final source = OfficialGtfsRealtimeDataSource(
      fetchBytes: (_) async => Uint8List(0),
    );

    expect(source.parse(Uint8List.fromList(message.writeToBuffer())), isEmpty);
  });
}
