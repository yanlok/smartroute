import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/core/theme/app_theme.dart';
import 'package:smartroute/features/admin/screens/admin_dashboard_screen.dart';
import 'package:smartroute/features/alerts/application/notice_controller.dart';
import 'package:smartroute/features/transit_network/application/transit_network_controller.dart';
import 'package:smartroute/shared/contracts/notice_repository.dart';
import 'package:smartroute/shared/contracts/transit_network_repository.dart';
import 'package:smartroute/shared/models/notice_models.dart';
import 'package:smartroute/shared/models/transit_models.dart';

class _FakeNoticeRepository implements NoticeRepository {
  final List<ServiceNotice> notices;
  final List<AdminUserSummary> users;
  final List<SourceHealth> sourceHealth;

  _FakeNoticeRepository({
    this.notices = const [],
    this.users = const [],
    this.sourceHealth = const [],
  });

  @override
  Future<void> archiveNotice(String noticeId) async {}

  @override
  Future<List<ServiceNotice>> getNotices() async => notices;

  @override
  Future<Set<String>> getReadNoticeIds(String userId) async => {};

  @override
  Future<List<SourceHealth>> getSourceHealth() async => sourceHealth;

  @override
  Future<Set<String>> getSubscribedRouteIds(String userId) async => {};

  @override
  Future<List<AdminUserSummary>> getUsers() async => users;

  @override
  Future<bool> isAdmin(String userId) async => true;

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
    required NoticeCategory category,
    required NoticeSeverity severity,
    required String routeId,
    required DateTime startsAt,
    DateTime? endsAt,
    required NoticeStatus status,
  }) async {
    return ServiceNotice(
      id: id ?? 'new-id',
      title: title,
      body: body,
      category: category,
      severity: severity,
      source: NoticeSource.smartRoute,
      routeId: routeId,
      startsAt: startsAt,
      endsAt: endsAt,
      status: status,
      createdBy: userId,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> setSubscription({
    required String userId,
    required String routeId,
    required bool enabled,
  }) async {}
}

class _FakeTransitRepository implements TransitNetworkRepository {
  final TransitNetwork network;

  _FakeTransitRepository(this.network);

  @override
  Future<TransitNetwork> loadNetwork() async => network;
}

TransitNetwork _buildNetwork() => TransitNetwork(
  metadata: TransitMetadata(
    generatedAt: DateTime.now(),
    publisher: 'data.gov.my',
    licence: 'Open',
    routeCount: 2,
    stopCount: 4,
    edgeCount: 2,
    patternCount: 2,
    shapeRouteCount: 2,
    sources: const [],
  ),
  routes: const [
    TransitRoute(
      id: 'r1',
      gtfsId: 'KJ',
      source: 'rapid-rail-kl',
      shortName: 'KJ',
      longName: 'Kelana Jaya Line',
      mode: TransitMode.lrt,
      colorHex: '009FE3',
      operatorName: 'Rapid KL',
      shape: [],
    ),
    TransitRoute(
      id: 'r2',
      gtfsId: 'KG',
      source: 'rapid-rail-kl',
      shortName: 'KG',
      longName: 'Kajang Line',
      mode: TransitMode.mrt,
      colorHex: '008000',
      operatorName: 'Rapid KL',
      shape: [],
    ),
  ],
  stops: const [
    TransitStop(
      id: 's1',
      gtfsId: 'S1',
      source: 'rapid-rail-kl',
      name: 'Stop 1',
      latitude: 3.1,
      longitude: 101.6,
      routeIds: ['r1'],
    ),
    TransitStop(
      id: 's2',
      gtfsId: 'S2',
      source: 'rapid-rail-kl',
      name: 'Stop 2',
      latitude: 3.2,
      longitude: 101.7,
      routeIds: ['r1'],
    ),
    TransitStop(
      id: 's3',
      gtfsId: 'S3',
      source: 'rapid-rail-kl',
      name: 'Stop 3',
      latitude: 3.3,
      longitude: 101.8,
      routeIds: ['r2'],
    ),
    TransitStop(
      id: 's4',
      gtfsId: 'S4',
      source: 'rapid-rail-kl',
      name: 'Stop 4',
      latitude: 3.4,
      longitude: 101.9,
      routeIds: ['r2'],
    ),
  ],
  edges: const [],
  patterns: const [],
);

void main() {
  testWidgets('renders Overview tab and displays correct metrics', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final now = DateTime.now();
    final notices = [
      ServiceNotice(
        id: 'n1',
        title: 'Platform maintenance',
        body: 'Platform 2 under maintenance',
        category: NoticeCategory.maintenance,
        severity: NoticeSeverity.warning,
        source: NoticeSource.smartRoute,
        routeId: 'r1',
        startsAt: now.subtract(const Duration(minutes: 10)),
        endsAt: now.add(const Duration(hours: 2)),
        status: NoticeStatus.published,
        createdBy: 'admin-1',
        updatedAt: now,
      ),
    ];
    final users = <AdminUserSummary>[
      AdminUserSummary(
        id: 'u-1',
        fullName: 'Admin User',
        role: 'admin',
        createdAt: now.subtract(const Duration(days: 10)),
      ),
      AdminUserSummary(
        id: 'u-2',
        fullName: 'Passenger User',
        role: 'passenger',
        createdAt: now.subtract(const Duration(days: 5)),
      ),
    ];

    final noticeRepo = _FakeNoticeRepository(
      notices: notices,
      users: users,
      sourceHealth: [
        SourceHealth(
          id: 'rapid-rail-kl',
          displayName: 'Rapid Rail KL',
          type: 'GTFS Realtime',
          status: 'Operational',
          checkedAt: now,
          dataTimestamp: now,
          recordCount: 10,
          details: 'Healthy sync',
        ),
      ],
    );
    final noticeController = NoticeController(repository: noticeRepo);
    final transitController = TransitNetworkController(
      repository: _FakeTransitRepository(_buildNetwork()),
    );

    await Future.wait([
      noticeController.load(userId: 'admin-1', notificationsEnabled: true),
      transitController.load(),
    ]);

    var signedOut = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AdminDashboardScreen(
          controller: noticeController,
          transitController: transitController,
          onSignOut: () => signedOut = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SmartRoute Admin'), findsOneWidget);
    expect(find.text('Operations & Directory Console'), findsOneWidget);
    expect(find.text('SYSTEM METRICS'), findsOneWidget);

    expect(find.text('2'), findsWidgets);
    expect(find.text('1'), findsWidgets);

    expect(find.text('TOTAL ACCOUNTS'), findsOneWidget);
    expect(find.text('ACTIVE NOTICES'), findsOneWidget);
    expect(find.text('PASSENGERS'), findsOneWidget);
    expect(find.text('ADMINISTRATORS'), findsOneWidget);
    expect(find.text('NETWORK ROUTES'), findsOneWidget);
    expect(find.text('NETWORK STOPS'), findsOneWidget);

    final signOutButton = find.byTooltip('Sign Out');
    expect(signOutButton, findsOneWidget);
    await tester.tap(signOutButton);
    await tester.pumpAndSettle();

    expect(
      find.text('Are you sure you want to sign out of the Admin console?'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Sign Out'));
    await tester.pumpAndSettle();

    expect(signedOut, isTrue);
  });

  testWidgets('renders Users tab with search and role filtering', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final now = DateTime.now();
    final users = <AdminUserSummary>[
      AdminUserSummary(
        id: 'u-1',
        fullName: 'Alice Admin',
        role: 'admin',
        createdAt: now.subtract(const Duration(days: 20)),
      ),
      AdminUserSummary(
        id: 'u-2',
        fullName: 'Bob Passenger',
        role: 'passenger',
        createdAt: now.subtract(const Duration(days: 10)),
      ),
    ];

    final noticeRepo = _FakeNoticeRepository(users: users);
    final noticeController = NoticeController(repository: noticeRepo);
    final transitController = TransitNetworkController(
      repository: _FakeTransitRepository(_buildNetwork()),
    );

    await Future.wait([
      noticeController.load(userId: 'admin-1', notificationsEnabled: true),
      transitController.load(),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AdminDashboardScreen(
          controller: noticeController,
          transitController: transitController,
          onSignOut: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Users'));
    await tester.pumpAndSettle();

    expect(find.text('Alice Admin'), findsOneWidget);
    expect(find.text('Bob Passenger'), findsOneWidget);

    await tester.tap(find.text('Admins (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Alice Admin'), findsOneWidget);
    expect(find.text('Bob Passenger'), findsNothing);

    await tester.tap(find.text('All (2)'));
    await tester.pumpAndSettle();

    final searchField = find.widgetWithText(
      TextField,
      'Search by name or ID...',
    );
    await tester.enterText(searchField, 'bob');
    await tester.pumpAndSettle();

    expect(find.text('Alice Admin'), findsNothing);
    expect(find.text('Bob Passenger'), findsOneWidget);

    await tester.tap(find.text('Bob Passenger'));
    await tester.pumpAndSettle();

    expect(find.text('Account Details'), findsOneWidget);
    expect(find.text('u-2'), findsOneWidget);
  });
}
