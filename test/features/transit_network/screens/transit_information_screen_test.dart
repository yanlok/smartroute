import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/alerts/application/notice_controller.dart';
import 'package:smartroute/features/transit_information/screens/transit_information_screen.dart';
import 'package:smartroute/features/transit_network/application/transit_network_controller.dart';
import 'package:smartroute/shared/contracts/notice_repository.dart';
import 'package:smartroute/shared/contracts/transit_network_repository.dart';
import 'package:smartroute/shared/models/notice_models.dart';
import 'package:smartroute/shared/models/transit_models.dart';

void main() {
  testWidgets(
    'TransitInformationScreen renders network exploration map, mode rail, and route cards',
    (tester) async {
      final network = _network();
      final transitController = TransitNetworkController(
        repository: _FakeTransitRepo(network),
      );
      final noticeController = NoticeController(repository: _FakeNoticeRepo());

      var progressRouteId = '';

      await tester.pumpWidget(
        MaterialApp(
          home: TransitInformationScreen(
            controller: transitController,
            notices: noticeController,
            onOpenProgress: (routeId) {
              progressRouteId = routeId;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Explore Network'), findsOneWidget);
      expect(find.text('Search line, station or route'), findsOneWidget);

      expect(find.text('All'), findsOneWidget);
      expect(find.text('LRT'), findsOneWidget);
      expect(find.text('MRT'), findsOneWidget);
      expect(find.text('Bus'), findsOneWidget);

      expect(find.text('Kelana Jaya Line'), findsOneWidget);
      expect(find.text('2 stations'), findsOneWidget);

      await tester.tap(find.text('Kelana Jaya Line'));
      await tester.pumpAndSettle();

      expect(find.text('View scheduled journey progress'), findsOneWidget);
      expect(find.text('Origin Station'), findsOneWidget);
      expect(find.text('Destination Station'), findsOneWidget);

      await tester.tap(find.text('View scheduled journey progress'));
      await tester.pump();

      expect(progressRouteId, 'rapid-rail-kl:KJ');

      transitController.dispose();
      noticeController.dispose();
    },
  );
}

class _FakeTransitRepo implements TransitNetworkRepository {
  final TransitNetwork network;
  _FakeTransitRepo(this.network);

  @override
  Future<TransitNetwork> loadNetwork() async => network;
}

class _FakeNoticeRepo implements NoticeRepository {
  @override
  Future<bool> isAdmin(String userId) async => false;

  @override
  Future<List<ServiceNotice>> getNotices() async => [];

  @override
  Future<Set<String>> getReadNoticeIds(String userId) async => {};

  @override
  Future<Set<String>> getSubscribedRouteIds(String userId) async => {};

  @override
  Future<void> archiveNotice(String noticeId) async {}

  @override
  Future<List<SourceHealth>> getSourceHealth() async => [];

  @override
  Future<List<AdminUserSummary>> getUsers() async => [];

  @override
  Future<void> markRead({
    required String userId,
    required String noticeId,
  }) async {}

  @override
  Future<ServiceNotice> saveNotice({
    String? id,
    required String userId,
    required String title,
    required String body,
    required NoticeSeverity severity,
    required String routeId,
    required DateTime startsAt,
    DateTime? endsAt,
    required NoticeStatus status,
  }) => throw UnimplementedError();

  @override
  Future<void> setSubscription({
    required String userId,
    required String routeId,
    required bool enabled,
  }) async {}
}

TransitNetwork _network() => TransitNetwork(
  metadata: TransitMetadata(
    generatedAt: DateTime.now(),
    publisher: 'data.gov.my',
    licence: 'Open',
    routeCount: 1,
    stopCount: 2,
    edgeCount: 1,
    patternCount: 1,
    shapeRouteCount: 1,
    sources: const [],
  ),
  routes: const [
    TransitRoute(
      id: 'rapid-rail-kl:KJ',
      gtfsId: 'KJ',
      source: 'rapid-rail-kl',
      shortName: 'KJ',
      longName: 'Kelana Jaya Line',
      mode: TransitMode.lrt,
      colorHex: '009FE3',
      operatorName: 'Rapid KL',
      shape: [TransitCoordinate(3, 101), TransitCoordinate(3.1, 101.1)],
    ),
  ],
  stops: const [
    TransitStop(
      id: 'rapid-rail-kl:S1',
      gtfsId: 'S1',
      source: 'rapid-rail-kl',
      name: 'Origin Station',
      latitude: 3,
      longitude: 101,
      routeIds: ['rapid-rail-kl:KJ'],
    ),
    TransitStop(
      id: 'rapid-rail-kl:S2',
      gtfsId: 'S2',
      source: 'rapid-rail-kl',
      name: 'Destination Station',
      latitude: 3.1,
      longitude: 101.1,
      routeIds: ['rapid-rail-kl:KJ'],
    ),
  ],
  edges: const [],
  patterns: const [
    TransitPattern(
      id: 'rapid-rail-kl:KJ:p1',
      routeId: 'rapid-rail-kl:KJ',
      gtfsTripId: 'trip-1',
      direction: 0,
      headsign: 'Destination Station',
      stopIds: ['rapid-rail-kl:S1', 'rapid-rail-kl:S2'],
      offsetMinutes: [0, 10],
      startSeconds: 0,
      endSeconds: 86400,
      headwaySeconds: 300,
    ),
  ],
);
