import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/tracking/domain/services/vehicle_position_simulator.dart';
import 'package:smartroute/shared/models/transit_models.dart';

void main() {
  group('VehiclePositionSimulator', () {
    test('interpolatePolyline returns start coordinate for fraction <= 0', () {
      const shape = [
        TransitCoordinate(3.0, 101.0),
        TransitCoordinate(3.1, 101.1),
      ];
      final pos = VehiclePositionSimulator.interpolatePolyline(shape, 0.0);
      expect(pos.latitude, closeTo(3.0, 1e-5));
      expect(pos.longitude, closeTo(101.0, 1e-5));
    });

    test('interpolatePolyline returns end coordinate for fraction >= 1', () {
      const shape = [
        TransitCoordinate(3.0, 101.0),
        TransitCoordinate(3.1, 101.1),
      ];
      final pos = VehiclePositionSimulator.interpolatePolyline(shape, 1.0);
      expect(pos.latitude, closeTo(3.1, 1e-5));
      expect(pos.longitude, closeTo(101.1, 1e-5));
    });

    test(
      'interpolatePolyline interpolates midpoint correctly across segments',
      () {
        const shape = [
          TransitCoordinate(0.0, 0.0),
          TransitCoordinate(0.0, 10.0),
        ];
        final pos = VehiclePositionSimulator.interpolatePolyline(shape, 0.5);
        expect(pos.latitude, closeTo(0.0, 1e-5));
        expect(pos.longitude, closeTo(5.0, 1e-5));
      },
    );

    test('simulatedPositions returns empty when shape is empty', () {
      const route = TransitRoute(
        id: 'r1',
        gtfsId: 'R1',
        source: 's',
        shortName: 'R1',
        longName: 'Route 1',
        mode: TransitMode.lrt,
        colorHex: 'FF0000',
        operatorName: 'Op',
        shape: [],
      );
      const pattern = TransitPattern(
        id: 'p1',
        routeId: 'r1',
        gtfsTripId: 't1',
        direction: 0,
        headsign: 'Dest',
        stopIds: ['s1', 's2'],
        offsetMinutes: [0, 10],
        startSeconds: 0,
        endSeconds: 86400,
        headwaySeconds: 300,
      );
      final positions = VehiclePositionSimulator.simulatedPositions(
        pattern: pattern,
        route: route,
        now: DateTime(2026, 9, 11, 12, 0),
      );
      expect(positions, isEmpty);
    });

    test(
      'simulatedPositions produces active vehicles during service hours',
      () {
        const route = TransitRoute(
          id: 'r1',
          gtfsId: 'R1',
          source: 's',
          shortName: 'R1',
          longName: 'Route 1',
          mode: TransitMode.lrt,
          colorHex: 'FF0000',
          operatorName: 'Op',
          shape: [TransitCoordinate(3.0, 101.0), TransitCoordinate(3.1, 101.1)],
        );
        const pattern = TransitPattern(
          id: 'p1',
          routeId: 'r1',
          gtfsTripId: 't1',
          direction: 0,
          headsign: 'Dest',
          stopIds: ['s1', 's2'],
          offsetMinutes: [0, 30], // 30 min duration
          startSeconds: 6 * 3600, // 06:00
          endSeconds: 23 * 3600, // 23:00
          headwaySeconds: 600, // 10 min headway
        );

        // 12:05 PM = 12 * 3600 + 5 * 60 = 43500 s
        final now = DateTime(2026, 9, 11, 12, 5);
        final positions = VehiclePositionSimulator.simulatedPositions(
          pattern: pattern,
          route: route,
          now: now,
        );

        expect(positions, isNotEmpty);
        for (final v in positions) {
          expect(v.positionFraction, greaterThanOrEqualTo(0.0));
          expect(v.positionFraction, lessThanOrEqualTo(1.0));
        }
      },
    );

    test('calculateBearing returns 0 for due north and 90 for due east', () {
      const p1 = TransitCoordinate(0.0, 0.0);
      const pNorth = TransitCoordinate(1.0, 0.0);
      const pEast = TransitCoordinate(0.0, 1.0);

      expect(
        VehiclePositionSimulator.calculateBearing(p1, pNorth),
        closeTo(0.0, 1.0),
      );
      expect(
        VehiclePositionSimulator.calculateBearing(p1, pEast),
        closeTo(90.0, 1.0),
      );
    });

    test(
      'interpolatePolylineWithBearing returns position and segment bearing',
      () {
        const shape = [
          TransitCoordinate(0.0, 0.0),
          TransitCoordinate(1.0, 0.0), // heading north = 0 deg
          TransitCoordinate(1.0, 1.0), // heading east = 90 deg
        ];

        final firstSeg =
            VehiclePositionSimulator.interpolatePolylineWithBearing(
              shape,
              0.25,
            );
        expect(firstSeg.position.latitude, closeTo(0.5, 0.01));
        expect(firstSeg.bearing, closeTo(0.0, 1.0));

        final secondSeg =
            VehiclePositionSimulator.interpolatePolylineWithBearing(
              shape,
              0.75,
            );
        expect(secondSeg.position.longitude, closeTo(0.5, 0.01));
        expect(secondSeg.bearing, closeTo(90.0, 1.0));
      },
    );

    test(
      'simulatedVehiclesForProgress distributes moving vehicles evenly along route',
      () {
        const route = TransitRoute(
          id: 'r1',
          gtfsId: 'R1',
          source: 's',
          shortName: 'R1',
          longName: 'Route 1',
          mode: TransitMode.lrt,
          colorHex: 'FF0000',
          operatorName: 'Op',
          shape: [
            TransitCoordinate(3.0, 101.0),
            TransitCoordinate(3.1, 101.1),
            TransitCoordinate(3.2, 101.2),
          ],
        );

        final vehicles = VehiclePositionSimulator.simulatedVehiclesForProgress(
          route: route,
          globalProgress: 0.1,
          count: 2,
        );

        expect(vehicles.length, 2);
        // Vehicle 0 is on Outbound leg (0.1 * 2.0 = 0.2)
        expect(vehicles[0].positionFraction, closeTo(0.2, 1e-4));
        expect(vehicles[0].isReturnTrip, isFalse);
        // Vehicle 1 is on Return leg (1.0 - (0.6 - 0.5) * 2 = 0.8)
        expect(vehicles[1].positionFraction, closeTo(0.8, 1e-4));
        expect(vehicles[1].isReturnTrip, isTrue);
        expect(vehicles[0].bearing, greaterThan(0.0));
      },
    );

    test(
      'computeStationStatus returns At station when vehicle is close to stop',
      () {
        const pattern = TransitPattern(
          id: 'p1',
          routeId: 'r1',
          gtfsTripId: 't1',
          direction: 0,
          headsign: 'Dest',
          stopIds: ['s1', 's2', 's3'],
          offsetMinutes: [0, 10, 20],
          startSeconds: 0,
          endSeconds: 86400,
          headwaySeconds: 300,
        );
        final stopsById = {
          's1': const TransitStop(
            id: 's1',
            gtfsId: 's1',
            source: 'src',
            name: 'Station One',
            latitude: 3.0,
            longitude: 101.0,
            routeIds: ['r1'],
          ),
          's2': const TransitStop(
            id: 's2',
            gtfsId: 's2',
            source: 'src',
            name: 'Station Two',
            latitude: 3.1,
            longitude: 101.1,
            routeIds: ['r1'],
          ),
          's3': const TransitStop(
            id: 's3',
            gtfsId: 's3',
            source: 'src',
            name: 'Station Three',
            latitude: 3.2,
            longitude: 101.2,
            routeIds: ['r1'],
          ),
        };

        const vehicleAtOrigin = SimulatedVehicle(
          vehicleId: 'sim-1',
          position: TransitCoordinate(3.0, 101.0),
          positionFraction: 0.0,
          isReturnTrip: false,
          isAtStation: true,
          currentStopIndex: 0,
        );

        final status1 = VehiclePositionSimulator.computeStationStatus(
          vehicle: vehicleAtOrigin,
          pattern: pattern,
          stopsById: stopsById,
          vehicleIndex: 0,
        );

        expect(status1.isAtStation, isTrue);
        expect(status1.statusText, 'Now at Station One');
        expect(status1.towardsTerminus, 'Towards Station Three');

        // Moving vehicle close to station must remain Approaching until actually stopped
        const vehicleDeparting = SimulatedVehicle(
          vehicleId: 'sim-1',
          position: TransitCoordinate(3.01, 101.01),
          positionFraction: 0.02,
          isReturnTrip: false,
          isAtStation: false,
          nextStopIndex: 1,
        );

        final statusDeparting = VehiclePositionSimulator.computeStationStatus(
          vehicle: vehicleDeparting,
          pattern: pattern,
          stopsById: stopsById,
          vehicleIndex: 0,
        );

        expect(statusDeparting.isAtStation, isFalse);
        expect(statusDeparting.statusText, 'Approaching Station Two');

        const vehicleApproachingMid = SimulatedVehicle(
          vehicleId: 'sim-2',
          position: TransitCoordinate(3.05, 101.05),
          positionFraction: 0.25,
          isReturnTrip: false,
        );

        final status2 = VehiclePositionSimulator.computeStationStatus(
          vehicle: vehicleApproachingMid,
          pattern: pattern,
          stopsById: stopsById,
          vehicleIndex: 0,
        );

        expect(status2.isAtStation, isFalse);
        expect(status2.statusText, 'Approaching Station Two');

        const vehicleReturn = SimulatedVehicle(
          vehicleId: 'sim-3',
          position: TransitCoordinate(3.15, 101.15),
          positionFraction: 0.75,
          isReturnTrip: true,
        );

        final status3 = VehiclePositionSimulator.computeStationStatus(
          vehicle: vehicleReturn,
          pattern: pattern,
          stopsById: stopsById,
          vehicleIndex: 1,
        );

        expect(status3.isAtStation, isFalse);
        expect(status3.statusText, 'Approaching Station Two');
        expect(status3.towardsTerminus, 'Towards Station One');
      },
    );

    test(
      'remainingMinutesToTarget calculates remaining minutes accurately',
      () {
        const vehicle = SimulatedVehicle(
          vehicleId: 'sim-1',
          position: TransitCoordinate(3.0, 101.0),
          positionFraction: 0.5,
          isReturnTrip: false,
        );

        final remaining = VehiclePositionSimulator.remainingMinutesToTarget(
          vehicle: vehicle,
          targetFraction: 1.0,
          tripDurationMinutes: 30,
        );

        // (1.0 - 0.5) * 30 = 15 mins
        expect(remaining, 15);
      },
    );

    test(
      'buildSimulationTimeline creates alternating dwell and travel steps',
      () {
        const pattern = TransitPattern(
          id: 'p1',
          routeId: 'r1',
          gtfsTripId: 't1',
          direction: 0,
          headsign: 'Dest',
          stopIds: ['s1', 's2', 's3'],
          offsetMinutes: [0, 5, 10],
          startSeconds: 0,
          endSeconds: 86400,
          headwaySeconds: 300,
        );

        final steps = VehiclePositionSimulator.buildSimulationTimeline(
          pattern: pattern,
          dwellSeconds: 2.0,
          terminusDwellSeconds: 3.0,
          defaultTravelSeconds: 4.0,
        );

        expect(steps, isNotEmpty);
        expect(steps.first.isDwell, isTrue);
        expect(steps.first.stopIndex, 0);
        expect(steps.first.duration, 3.0); // terminus dwell

        final travelSteps = steps.where((s) => !s.isDwell);
        expect(travelSteps, isNotEmpty);

        final dwellSteps = steps.where((s) => s.isDwell);
        expect(dwellSteps, isNotEmpty);
      },
    );

    test(
      'simulatedVehiclesForProgress with pattern pauses at stations and continues',
      () {
        const route = TransitRoute(
          id: 'r1',
          gtfsId: 'R1',
          source: 's',
          shortName: 'R1',
          longName: 'Route 1',
          mode: TransitMode.lrt,
          colorHex: 'FF0000',
          operatorName: 'Op',
          shape: [
            TransitCoordinate(3.0, 101.0),
            TransitCoordinate(3.1, 101.1),
            TransitCoordinate(3.2, 101.2),
          ],
        );
        const pattern = TransitPattern(
          id: 'p1',
          routeId: 'r1',
          gtfsTripId: 't1',
          direction: 0,
          headsign: 'Dest',
          stopIds: ['s1', 's2', 's3'],
          offsetMinutes: [0, 5, 10],
          startSeconds: 0,
          endSeconds: 86400,
          headwaySeconds: 300,
        );

        // At progress 0.0, vehicle 0 should be dwelling at origin (Stop 0)
        final atStart = VehiclePositionSimulator.simulatedVehiclesForProgress(
          route: route,
          globalProgress: 0.0,
          count: 2,
          pattern: pattern,
        );

        expect(atStart, hasLength(2));
        expect(atStart[0].isAtStation, isTrue);
        expect(atStart[0].currentStopIndex, 0);
        expect(atStart[0].positionFraction, 0.0);
      },
    );

    test(
      'projectCoordinateToShapeFraction maps coordinates onto polyline fraction',
      () {
        const shape = [
          TransitCoordinate(3.0, 100.0),
          TransitCoordinate(3.0, 101.0),
          TransitCoordinate(3.0, 102.0),
        ];

        final fracMid =
            VehiclePositionSimulator.projectCoordinateToShapeFraction(
              shape,
              const TransitCoordinate(3.0, 101.0),
            );
        expect(fracMid, closeTo(0.5, 0.001));

        final fracStart =
            VehiclePositionSimulator.projectCoordinateToShapeFraction(
              shape,
              const TransitCoordinate(3.01, 100.0),
            );
        expect(fracStart, closeTo(0.0, 0.01));
      },
    );

    test(
      'simulatedVehiclesForProgress snaps position to exact stop coordinate during dwell',
      () {
        const route = TransitRoute(
          id: 'r1',
          gtfsId: 'R1',
          source: 's',
          shortName: 'R1',
          longName: 'Route 1',
          mode: TransitMode.lrt,
          colorHex: 'FF0000',
          operatorName: 'Op',
          shape: [
            TransitCoordinate(3.0, 101.0),
            TransitCoordinate(3.1, 101.1),
            TransitCoordinate(3.2, 101.2),
          ],
        );
        const pattern = TransitPattern(
          id: 'p1',
          routeId: 'r1',
          gtfsTripId: 't1',
          direction: 0,
          headsign: 'Dest',
          stopIds: ['s1', 's2', 's3'],
          offsetMinutes: [0, 5, 10],
          startSeconds: 0,
          endSeconds: 86400,
          headwaySeconds: 300,
        );
        final stopsById = {
          's1': const TransitStop(
            id: 's1',
            gtfsId: 's1',
            source: 'src',
            name: 'Station 1',
            latitude: 3.001,
            longitude: 101.002,
            routeIds: ['r1'],
          ),
          's2': const TransitStop(
            id: 's2',
            gtfsId: 's2',
            source: 'src',
            name: 'Station 2',
            latitude: 3.105,
            longitude: 101.105,
            routeIds: ['r1'],
          ),
          's3': const TransitStop(
            id: 's3',
            gtfsId: 's3',
            source: 'src',
            name: 'Station 3',
            latitude: 3.201,
            longitude: 101.202,
            routeIds: ['r1'],
          ),
        };

        final vehicles = VehiclePositionSimulator.simulatedVehiclesForProgress(
          route: route,
          globalProgress: 0.0,
          count: 2,
          pattern: pattern,
          stopsById: stopsById,
        );

        expect(vehicles, hasLength(2));
        expect(vehicles[0].isAtStation, isTrue);
        expect(vehicles[0].currentStopIndex, 0);
        expect(vehicles[0].position.latitude, equals(3.001));
        expect(vehicles[0].position.longitude, equals(101.002));
      },
    );
  });
}
