import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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

  testWidgets(
    'uses an interactive transit diagram when Play services are unavailable',
    (tester) async {
      const channel = MethodChannel('com.smartroute.app/maps');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            expect(call.method, 'isGooglePlayServicesAvailable');
            return false;
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TransitGoogleMap(markers: [], lines: []),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Transit network'), findsOneWidget);
      expect(find.byType(GoogleMap), findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets('opens a station from the device-safe transit diagram', (
    tester,
  ) async {
    const channel = MethodChannel('com.smartroute.app/maps');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => false);
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });
    var selected = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TransitGoogleMap(
            markers: [
              TransitMapMarker(
                id: 'station',
                label: 'Demo station',
                coordinate: const TransitCoordinate(3.13, 101.69),
                onTap: () => selected = true,
              ),
            ],
            lines: const [],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Station marker: Demo station'));

    expect(selected, isTrue);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
