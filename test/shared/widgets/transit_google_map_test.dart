import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  testWidgets('unavailable Android map shows real marker information', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await tester.pumpWidget(
        MaterialApp(
          home: TransitGoogleMap(
            markers: const [
              TransitMapMarker(
                id: 'origin',
                label: 'KLCC Station',
                coordinate: TransitCoordinate(3.1579, 101.7123),
              ),
              TransitMapMarker(
                id: 'destination',
                label: 'Pasar Seni Station',
                coordinate: TransitCoordinate(3.1425, 101.6953),
              ),
            ],
            lines: const [],
            nativeMapAvailability: () async => false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('transit_map_fallback')), findsOneWidget);
      expect(find.text('Map unavailable on this device'), findsOneWidget);
      expect(find.textContaining('KLCC Station'), findsOneWidget);
      expect(find.textContaining('Pasar Seni Station'), findsOneWidget);
      expect(find.byKey(const Key('transit_map_retry')), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
