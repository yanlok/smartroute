import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/alerts/application/notice_controller.dart';
import 'package:smartroute/features/alerts/screens/alerts_screen.dart';
import 'package:smartroute/features/transit_network/application/transit_network_controller.dart';
import 'package:smartroute/shared/contracts/notice_repository.dart';
import 'package:smartroute/shared/contracts/transit_network_repository.dart';
import 'package:smartroute/shared/models/notice_models.dart';
import 'package:smartroute/shared/models/transit_models.dart';

void main() {
  testWidgets('shows all active notices and opens persistent read details', (
    tester,
  ) async {
    final network = _network();
    final noticeController = NoticeController(
      repository: _NoticeRepo(
        notices: [
          _notice(),
          _notice(
            id: 'notice-2',
            title: 'Traffic delay',
            body: 'Heavy traffic is causing a ten-minute delay.',
            category: NoticeCategory.delay,
          ),
          _notice(
            id: 'notice-3',
            title: 'Boarding point change',
            body: 'Use the temporary boarding point at the station entrance.',
            category: NoticeCategory.service,
          ),
          _notice(
            id: 'notice-4',
            title: 'Route 250 service update',
            body: 'Temporary boarding point change at Hab Bas AU3.',
            category: NoticeCategory.service,
            routeId: 'rapid-bus-kl:U2500',
          ),
        ],
        subscriptions: {'rapid-rail-kl:KJ'},
      ),
    );
    final transitController = TransitNetworkController(
      repository: _TransitRepo(network),
    );
    await Future.wait([
      noticeController.load(userId: 'user-a', notificationsEnabled: true),
      transitController.load(),
    ]);
    String? openedRouteId;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AlertsScreen(
            controller: noticeController,
            transitController: transitController,
            notificationsEnabled: true,
            onOpenRoute: (routeId) => openedRouteId = routeId,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('All'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Delay'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Maintenance'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Service'), findsOneWidget);
    expect(find.text('Arrival Reminders'), findsNothing);
    expect(find.text('4 new'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Delay'));
    await tester.pumpAndSettle();
    expect(
      find.text('Heavy traffic is causing a ten-minute delay.'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'Service'));
    await tester.pumpAndSettle();
    expect(find.text('Service Announcement'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('rapid-bus-kl:U2500'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('rapid-bus-kl:U2500'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Maintenance'));
    await tester.pumpAndSettle();
    expect(find.text('Delay'), findsOneWidget);
    expect(find.text('Service Announcement'), findsNothing);

    await tester.tap(find.text('Kelana Jaya Line'));
    await tester.pumpAndSettle();

    expect(find.text('SERVICE NOTICE'), findsOneWidget);
    expect(find.text('Signal maintenance'), findsOneWidget);
    expect(find.text('Affected Route'), findsOneWidget);
    expect(find.text('Severity'), findsOneWidget);
    expect(find.text('Medium'), findsOneWidget);
    expect(find.text('Active Period'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('ACTIVE'), findsOneWidget);
    expect(noticeController.unreadCount, 3);
    expect(noticeController.isRead(noticeController.notices.first), isTrue);
    await tester.ensureVisible(find.text('View Route'));
    await tester.tap(find.text('View Route'));
    await tester.pumpAndSettle();
    expect(openedRouteId, 'rapid-rail-kl:KJ');

    noticeController.dispose();
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
  final Set<String> readIds = {};

  _NoticeRepo({required this.notices, required this.subscriptions});

  @override
  Future<void> archiveNotice(String noticeId) async {}

  @override
  Future<List<ServiceNotice>> getNotices() async => notices;

  @override
  Future<Set<String>> getReadNoticeIds(String userId) async => {...readIds};

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
  }) async {
    readIds.add(noticeId);
  }

  @override
  Future<ServiceNotice> saveNotice({
    String? id,
    required String userId,
    required String title,
    required String body,
    required NoticeCategory category,
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

ServiceNotice _notice({
  String id = 'notice-1',
  String title = 'Signal maintenance',
  String body = 'Trains may use a different platform this evening.',
  NoticeCategory category = NoticeCategory.maintenance,
  String routeId = 'rapid-rail-kl:KJ',
}) => ServiceNotice(
  id: id,
  title: title,
  body: body,
  category: category,
  severity: NoticeSeverity.warning,
  source: NoticeSource.smartRoute,
  routeId: routeId,
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
