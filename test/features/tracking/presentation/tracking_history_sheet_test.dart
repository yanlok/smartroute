// TrackingHistorySheet pagination: history is fetched from the repository in
// server-side pages of 10 and more pages load as the user scrolls to the
// bottom.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/tracking/application/tracking_session_controller.dart';
import 'package:smartroute/features/tracking/domain/models/tracking_session.dart';
import 'package:smartroute/features/tracking/domain/repositories/tracking_session_repository.dart';
import 'package:smartroute/features/tracking/presentation/widgets/tracking_history_sheet.dart';

void main() {
  testWidgets('loads server-side pages of 10 as the user scrolls', (
    tester,
  ) async {
    final repository = _FakeSessionRepository(25);
    final controller = TrackingSessionController(repository: repository);
    await controller.load('user-1');
    expect(controller.pastSessions, hasLength(10));
    expect(controller.hasMoreSessions, isTrue);

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

    // First page: the newest logs are shown, later pages are not loaded yet.
    expect(find.text('Route 1'), findsOneWidget);
    expect(find.text('Route 11'), findsNothing);

    // Scroll to the bottom of the first page -> the loading-more state
    // appears, then page 2 is fetched from the repository.
    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pump();
    expect(find.text('Loading more…'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.text('Loading more…'), findsNothing);
    expect(controller.pastSessions, hasLength(20));
    expect(controller.hasMoreSessions, isTrue);

    // Scroll again -> final page loads and the footer disappears.
    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(controller.pastSessions, hasLength(25));
    expect(controller.hasMoreSessions, isFalse);
    expect(find.text('Loading more…'), findsNothing);

    // The list grew after the final page loaded, so scroll to its new bottom.
    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(find.text('Route 25'), findsOneWidget);

    // The repository only ever served the three pages.
    expect(repository.requestedPages, [
      (limit: 10, offset: 0),
      (limit: 10, offset: 10),
      (limit: 10, offset: 20),
    ]);
  });
}

class _FakeSessionRepository implements TrackingSessionRepository {
  final int count;
  final List<({int limit, int offset})> requestedPages = [];

  _FakeSessionRepository(this.count);

  @override
  Future<List<TrackingSession>> getSessionsForUser(
    String userId, {
    int limit = 10,
    int offset = 0,
  }) async {
    requestedPages.add((limit: limit, offset: offset));
    // Only simulated pagination takes time; the initial load must complete
    // before the first frame, inside fake async time.
    if (offset > 0) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    return [
      for (var index = offset; index < math.min(offset + limit, count); index++)
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
  }

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
