import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/core/theme/app_colors.dart';
import 'package:smartroute/features/tracking/domain/models/live_vehicle.dart';
import 'package:smartroute/features/tracking/domain/models/tracking_station.dart';
import 'package:smartroute/features/tracking/domain/models/transit_direction.dart';
import 'package:smartroute/features/tracking/presentation/widgets/live_map_painter.dart';

void main() {
  group('LiveMapPainter', () {
    testWidgets('paints without throwing for a small station list', (
      tester,
    ) async {
      const stations = <TrackingStation>[
        TrackingStation(id: 'kj1', name: 'A', lineId: 'kj', sequence: 0),
        TrackingStation(id: 'kj2', name: 'B', lineId: 'kj', sequence: 1),
        TrackingStation(id: 'kj3', name: 'C', lineId: 'kj', sequence: 2),
      ];
      final vehicle = LiveVehicle(
        vehicleId: 'KJ-1',
        lineId: 'kj',
        direction: TransitDirection.forward,
        positionFraction: 0.5,
        etaMinutes: 9,
        lastUpdated: DateTime.utc(2026, 1, 1),
        isLive: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 196,
              child: CustomPaint(
                painter: LiveMapPainter(
                  stations: stations,
                  vehicle: vehicle,
                  pulseValue: 0.5,
                  lineColor: AppColors.kjLine,
                ),
                size: const Size(390, 196),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('paints without throwing for an empty station list', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 100,
              child: CustomPaint(
                painter: LiveMapPainter(
                  stations: const <TrackingStation>[],
                  vehicle: null,
                  pulseValue: 0.0,
                  lineColor: AppColors.kjLine,
                ),
                size: const Size(200, 100),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
