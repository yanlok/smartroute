import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/alerts/application/arrival_reminder_controller.dart';
import 'package:smartroute/features/alerts/application/notice_controller.dart';
import 'package:smartroute/features/alerts/data/in_memory_arrival_reminder_repository.dart';
import 'package:smartroute/features/alerts/screens/alerts_screen.dart';
import 'package:smartroute/features/transit_network/application/transit_network_controller.dart';
import 'package:smartroute/shared/contracts/notice_repository.dart';
import 'package:smartroute/shared/contracts/transit_network_repository.dart';
import 'package:smartroute/shared/models/notice_models.dart';
import 'package:smartroute/shared/models/transit_models.dart';

void main() {
  testWidgets('shows notice details and manages local arrival reminders', (
    tester,
  ) async {
    final network = _network();
    final noticeController = NoticeController(
      repository: _NoticeRepo(
        notices: [_notice()],
        subscriptions: {'rapid-rail-kl:KJ'},
      ),
    );
    final reminderController = ArrivalReminderController(
      repository: InMemoryArrivalReminderRepository(),
    );
    final transitController = TransitNetworkController(
      repository: _TransitRepo(network),
    );
    await Future.wait([
      noticeController.load(userId: 'user-a', notificationsEnabled: true),
      transitController.load(),
    ]);
    await reminderController.load('user-a');
    expect(
      await reminderController.create(
        stationId: 'rapid-rail-kl:S1',
        routeId: 'rapid-rail-kl:KJ',
        expectedArrival: DateTime.now().add(const Duration(minutes: 20)),
        leadTimeMinutes: 5,
      ),
      isTrue,
    );
    String? openedRouteId;
    String? openedStationId;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AlertsScreen(
            controller: noticeController,
            reminders: reminderController,
            transitController: transitController,
            notificationsEnabled: true,
            onOpenRoute: (routeId) => openedRouteId = routeId,
            onOpenStation: (stationId) => openedStationId = stationId,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Service Notices'), findsOneWidget);
    await tester.tap(find.text('Signal maintenance'));
    await tester.pumpAndSettle();

    expect(find.text('Affected route'), findsOneWidget);
    expect(find.text('Active period'), findsOneWidget);
    expect(find.text('Delays possible'), findsOneWidget);
    await tester.ensureVisible(find.text('View Route'));
    await tester.tap(find.text('View Route'));
    await tester.pumpAndSettle();
    expect(openedRouteId, 'rapid-rail-kl:KJ');

    await tester.tap(find.text('Arrival Reminders'));
    await tester.pumpAndSettle();

    expect(find.text('Origin Station'), findsOneWidget);
    expect(find.text('ACTIVE'), findsOneWidget);
    await tester.tap(find.text('View Station Details'));
    expect(openedStationId, 'rapid-rail-kl:S1');

    await tester.tap(find.text('Disable'));
    await tester.pumpAndSettle();
    expect(find.text('DISABLED'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('No arrival reminders yet'), findsOneWidget);

    noticeController.dispose();
    reminderController.dispose();
    transitController.dispose();
  });
}

class _TransitRepo implements TransitNetworkRepository {
  final TransitNetwork network;

  _TransitRepo(this.network);

  @override
  Future<TransitNetwork> loadNetwork() async => network;
}

class _NoticeRepo implements NoticeRepository {
  final List<ServiceNotice> notices;
  final Set<String> subscriptions;

  _NoticeRepo({required this.notices, required this.subscriptions});

  @override
  Future<void> archiveNotice(String noticeId) async {}

  @override
  Future<List<ServiceNotice>> getNotices() async => notices;

  @override
  Future<Set<String>> getReadNoticeIds(String userId) async => {};

  @override
  Future<List<SourceHealth>> getSourceHealth() async => [];

  @override
  Future<Set<String>> getSubscribedRouteIds(String userId) async =>
      subscriptions;

  @override
  Future<List<AdminUserSummary>> getUsers() async => [];

  @override
  Future<bool> isAdmin(String userId) async => false;

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

ServiceNotice _notice() => ServiceNotice(
  id: 'notice-1',
  title: 'Signal maintenance',
  body: 'Trains may use a different platform this evening.',
  severity: NoticeSeverity.warning,
  source: NoticeSource.smartRoute,
  routeId: 'rapid-rail-kl:KJ',
  startsAt: DateTime.now().subtract(const Duration(minutes: 5)),
  endsAt: DateTime.now().add(const Duration(hours: 1)),
  status: NoticeStatus.published,
  createdBy: 'admin-a',
  updatedAt: DateTime.now(),
);

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
