import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/tracking/domain/models/tracking_station.dart';
import 'package:smartroute/features/tracking/presentation/widgets/upcoming_stops_list.dart';

void main() {
  group('UpcomingStopsList', () {
    const stops = <TrackingStation>[
      TrackingStation(id: 'kj1', name: 'Gombak', lineId: 'kj', sequence: 0),
      TrackingStation(
        id: 'kj2',
        name: 'Taman Melati',
        lineId: 'kj',
        sequence: 1,
      ),
      TrackingStation(
        id: 'kj3',
        name: 'Wangsa Maju',
        lineId: 'kj',
        sequence: 2,
      ),
    ];

    testWidgets('marks the first stop as Current', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: UpcomingStopsList(stops: stops)),
        ),
      );
      expect(find.text('Current'), findsOneWidget);
      expect(find.text('Gombak'), findsOneWidget);
    });

    testWidgets('invokes onStationTap when a row is tapped', (tester) async {
      TrackingStation? tapped;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UpcomingStopsList(
              stops: stops,
              onStationTap: (s) => tapped = s,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Taman Melati'));
      await tester.pump();
      expect(tapped?.id, 'kj2');
    });

    testWidgets('renders nothing when stops is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: UpcomingStopsList(stops: <TrackingStation>[])),
        ),
      );
      expect(find.byType(Text), findsNothing);
    });
  });
}
