import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as flutter_map;
import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/shared/models/transit_models.dart';
import 'package:smartroute/shared/widgets/transit_google_map.dart';

void main() {
  const viewport = TransitMapViewport();

  test('camera centers the complete route extent', () {
    final camera = viewport.resolve(
      markers: const [
        TransitMapMarker(
          id: 'origin',
          label: 'Origin',
          coordinate: TransitCoordinate(3.00, 101.50),
        ),
        TransitMapMarker(
          id: 'destination',
          label: 'Destination',
          coordinate: TransitCoordinate(3.20, 101.80),
        ),
      ],
      lines: const [],
    );

    expect(camera.center.latitude, closeTo(3.10, 0.0001));
    expect(camera.center.longitude, closeTo(101.65, 0.0001));
    expect(camera.zoom, 9.0);
  });

  test('camera keeps a close zoom for one station', () {
    final camera = viewport.resolve(
      markers: const [
        TransitMapMarker(
          id: 'station',
          label: 'Station',
          coordinate: TransitCoordinate(3.13, 101.69),
        ),
      ],
      lines: const [],
    );

    expect(camera.center.latitude, 3.13);
    expect(camera.center.longitude, 101.69);
    expect(camera.zoom, 14.0);
  });

  testWidgets('uses an interactive OpenStreetMap when Google Maps is unavailable', (
    tester,
  ) async {
    var markerTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TransitGoogleMap(
            markers: [
              TransitMapMarker(
                id: 'station',
                label: 'Example station',
                coordinate: const TransitCoordinate(3.139, 101.6869),
                onTap: () => markerTapped = true,
              ),
            ],
            lines: const [],
            googleMapsAvailable: () async => false,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(flutter_map.FlutterMap), findsOneWidget);
    expect(find.text('© OpenStreetMap contributors'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('station')));
    expect(markerTapped, isTrue);
  });
}
