import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/tracking/domain/models/arrival_estimate.dart';
import 'package:smartroute/features/tracking/presentation/widgets/countdown_tile.dart';

void main() {
  group('CountdownTile', () {
    ArrivalEstimate makeArrival({int eta = 4}) {
      return ArrivalEstimate(
        stationId: 'kj10',
        platformCode: 'Platform 1',
        lineId: 'kj',
        vehicleId: 'KJ-1001',
        etaMinutes: eta,
        isLive: false,
      );
    }

    testWidgets('renders platform, vehicle id, and ETA', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CountdownTile(arrival: makeArrival(eta: 7), lineCode: 'KJ'),
          ),
        ),
      );
      expect(find.text('Platform 1'), findsOneWidget);
      expect(find.text('KJ-1001'), findsOneWidget);
      expect(find.text('7 min'), findsOneWidget);
    });

    testWidgets('exposes a Simulated semantics label', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CountdownTile(arrival: makeArrival(), lineCode: 'KJ'),
          ),
        ),
      );
      // Verify the Semantics node is present with the right
      // properties on the widget tree (independent of merge
      // behaviour in the semantics tree).
      final semantics = tester.widgetList<Semantics>(find.byType(Semantics));
      final hasLabel = semantics.any(
        (s) => s.properties.label == 'Simulated arrival — not real-time data.',
      );
      expect(
        hasLabel,
        isTrue,
        reason: 'Expected a Semantics node with the simulated label.',
      );
      handle.dispose();
    });
  });
}
