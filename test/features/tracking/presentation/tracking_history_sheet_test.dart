// TrackingHistorySheet pagination: logs are revealed in pages of 10 as the
// user scrolls toward the bottom.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/tracking/application/tracking_session_controller.dart';
import 'package:smartroute/features/tracking/domain/models/tracking_session.dart';
import 'package:smartroute/features/tracking/domain/repositories/tracking_session_repository.dart';
import 'package:smartroute/features/tracking/presentation/widgets/tracking_history_sheet.dart';

void main() {
  testWidgets('reveals past logs in pages of 10 as the user scrolls', (
    tester,
  ) async {
    final controller = TrackingSessionController(
      repository: _FakeSessionRepository(25),
    );
    await controller.load('user-1');
    expect(controller.pastSessions, hasLength(25));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              height: 400,
              child: TrackingHistorySheet(controller: controller),
            ),
          ),
        ),
      ),
    );

    // First page: the earliest logs are shown, later ones are not loaded.
    expect(find.text('Route 1'), findsOneWidget);
    expect(find.text('Route 11'), findsNothing);
    expect(find.text('Route 21'), findsNothing);

    // Scroll to the bottom of the first page -> the loading-more state
    // appears, then page 2 loads after the loading delay.
    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pump();
    expect(find.text('Loading more…'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.text('Loading more…'), findsNothing);
    expect(find.text('Route 11'), findsOneWidget);
    expect(find.text('Route 21'), findsNothing);

    // Scroll again -> final page loads.
    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.text('Route 21'), findsOneWidget);
    expect(find.text('Loading more…'), findsNothing);

    // One more scroll reveals the very last log.
    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(find.text('Route 25'), findsOneWidget);
  });
}

class _FakeSessionRepository implements TrackingSessionRepository {
  final int count;

  const _FakeSessionRepository(this.count);

  @override
  Future<List<TrackingSession>> getSessionsForUser(String userId) async => [
    for (var index = 0; index < count; index++)
      TrackingSession(
        id: 'session-$index',
        userId: userId,
        routeId: 'rapid-rail-kl:KJ',
        routeName: 'Route ${index + 1}',
        mode: 'lrt',
        originStopId: 'origin-$index',
        originStopName: 'Origin ${index + 1}',
        destinationStopId: 'dest-$index',
        destinationStopName: 'Dest ${index + 1}',
        status: TrackingSessionStatus.completed,
        totalStops: 5,
        startedAt: DateTime(2026, 1, 1).add(Duration(days: index)),
        endedAt: DateTime(2026, 1, 1).add(Duration(days: index, hours: 1)),
        durationMinutes: 30,
      ),
  ];

  @override
  Future<TrackingSession> startSession({
    required String userId,
    required String routeId,
    required String routeName,
    required String mode,
    required String originStopId,
    required String originStopName,
    String? destinationStopId,
    String? destinationStopName,
    required int totalStops,
  }) async => throw UnimplementedError();

  @override
  Future<TrackingSession> updateProgress({
    required String sessionId,
    required String currentStationName,
    required int stopsCompleted,
  }) async => throw UnimplementedError();

  @override
  Future<TrackingSession> completeSession({
    required String sessionId,
    required DateTime endedAt,
    required int durationMinutes,
    String? notes,
    String? destinationStopId,
    String? destinationStopName,
  }) async => throw UnimplementedError();

  @override
  Future<void> cancelSession(String sessionId) async {}

  @override
  Future<void> deleteSession(String sessionId) async {}
}
