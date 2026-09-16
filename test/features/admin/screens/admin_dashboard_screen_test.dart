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
  List<ServiceNotice> notices;
  List<AdminUserSummary> users;
  List<SourceHealth> sourceHealth;

  _FakeNoticeRepository({
    this.notices = const [],
    this.users = const [],
    this.sourceHealth = const [],
  });

  @override
  Future<void> archiveNotice(String noticeId) async {
    notices = notices.map((n) {
      if (n.id == noticeId) {
        return ServiceNotice(
          id: n.id,
          title: n.title,
          body: n.body,
          category: n.category,
          severity: n.severity,
          source: n.source,
          routeId: n.routeId,
          startsAt: n.startsAt,
          endsAt: n.endsAt,
          status: NoticeStatus.archived,
          createdBy: n.createdBy,
          updatedAt: DateTime.now(),
        );
      }
      return n;
    }).toList();
  }

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
    final notice = ServiceNotice(
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
    if (id != null) {
      notices = notices.map((n) => n.id == id ? notice : n).toList();
    } else {
      notices = [...notices, notice];
    }
    return notice;
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
  testWidgets(
    'renders Overview tab and displays correct metrics and Recent Activity',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 3200);
      tester.view.devicePixelRatio = 1.0;
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

      expect(find.text('RECENT ACTIVITY'), findsOneWidget);
      expect(find.text('Published notice'), findsOneWidget);
      expect(find.text('Platform maintenance'), findsOneWidget);
      expect(find.text('Passenger User joined SmartRoute'), findsOneWidget);
      expect(find.text('Admin User joined SmartRoute'), findsOneWidget);

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
    },
  );

  testWidgets(
    'Recent Activity combines users and notices, limits to 5, sorts newest first, and handles empty state',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final emptyRepo = _FakeNoticeRepository();
      final emptyController = NoticeController(repository: emptyRepo);
      final transitController = TransitNetworkController(
        repository: _FakeTransitRepository(_buildNetwork()),
      );

      await Future.wait([
        emptyController.load(userId: 'admin-1', notificationsEnabled: true),
        transitController.load(),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminDashboardScreen(
            controller: emptyController,
            transitController: transitController,
            onSignOut: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No recent activity'), findsOneWidget);
      expect(
        find.text(
          'Recent account registrations and notice updates will appear here.',
        ),
        findsOneWidget,
      );

      final now = DateTime.now();
      final notices = [
        ServiceNotice(
          id: 'n1',
          title: 'KJ Delay',
          body: 'Signal problem',
          category: NoticeCategory.delay,
          severity: NoticeSeverity.warning,
          source: NoticeSource.smartRoute,
          routeId: 'r1',
          startsAt: now.subtract(const Duration(minutes: 30)),
          endsAt: now.add(const Duration(hours: 1)),
          status: NoticeStatus.published,
          createdBy: 'admin-1',
          updatedAt: now.subtract(const Duration(minutes: 1)),
        ),
        ServiceNotice(
          id: 'n2',
          title: 'Track Inspection Draft',
          body: 'Scheduled inspection',
          category: NoticeCategory.maintenance,
          severity: NoticeSeverity.info,
          source: NoticeSource.smartRoute,
          routeId: 'r1',
          startsAt: now.add(const Duration(days: 1)),
          endsAt: null,
          status: NoticeStatus.draft,
          createdBy: 'admin-1',
          updatedAt: now.subtract(const Duration(minutes: 4)),
        ),
        ServiceNotice(
          id: 'n3',
          title: 'Old Flood Warning',
          body: 'Archived flood issue',
          category: NoticeCategory.service,
          severity: NoticeSeverity.severe,
          source: NoticeSource.smartRoute,
          routeId: 'r1',
          startsAt: now.subtract(const Duration(days: 2)),
          endsAt: null,
          status: NoticeStatus.archived,
          createdBy: 'admin-1',
          updatedAt: now.subtract(const Duration(minutes: 6)),
        ),
      ];

      final users = [
        AdminUserSummary(
          id: 'u1',
          fullName: 'Charlie User',
          role: 'passenger',
          createdAt: now.subtract(const Duration(minutes: 2)),
        ),
        AdminUserSummary(
          id: 'u2',
          fullName: 'Dave User',
          role: 'passenger',
          createdAt: now.subtract(const Duration(minutes: 3)),
        ),
        AdminUserSummary(
          id: 'u3',
          fullName: 'Eve User',
          role: 'admin',
          createdAt: now.subtract(const Duration(minutes: 5)),
        ),
        AdminUserSummary(
          id: 'u4',
          fullName: 'Frank User',
          role: 'passenger',
          createdAt: now.subtract(const Duration(minutes: 10)),
        ),
      ];

      final populatedRepo = _FakeNoticeRepository(
        notices: notices,
        users: users,
      );
      final populatedController = NoticeController(repository: populatedRepo);

      await populatedController.load(
        userId: 'admin-1',
        notificationsEnabled: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminDashboardScreen(
            controller: populatedController,
            transitController: transitController,
            onSignOut: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('KJ Delay'), findsOneWidget);
      expect(find.text('Charlie User joined SmartRoute'), findsOneWidget);
      expect(find.text('Dave User joined SmartRoute'), findsOneWidget);
      expect(find.text('Track Inspection Draft'), findsOneWidget);
      expect(find.text('Eve User joined SmartRoute'), findsOneWidget);

      expect(find.text('Old Flood Warning'), findsNothing);
      expect(find.text('Frank User joined SmartRoute'), findsNothing);

      final pos1 = tester.getTopLeft(find.text('KJ Delay')).dy;
      final pos2 = tester
          .getTopLeft(find.text('Charlie User joined SmartRoute'))
          .dy;
      final pos3 = tester
          .getTopLeft(find.text('Dave User joined SmartRoute'))
          .dy;
      final pos4 = tester.getTopLeft(find.text('Track Inspection Draft')).dy;
      final pos5 = tester
          .getTopLeft(find.text('Eve User joined SmartRoute'))
          .dy;

      expect(pos1 < pos2, isTrue);
      expect(pos2 < pos3, isTrue);
      expect(pos3 < pos4, isTrue);
      expect(pos4 < pos5, isTrue);

      expect(find.text('Published notice'), findsOneWidget);
      expect(find.text('Draft notice updated'), findsOneWidget);
      expect(find.text('New account'), findsNWidgets(3));
    },
  );

  testWidgets(
    'renders Users tab with summary chips, role filtering, search, and sorting',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final now = DateTime.now();
      final users = <AdminUserSummary>[
        AdminUserSummary(
          id: 'u-3',
          fullName: 'Charlie Passenger',
          role: 'passenger',
          createdAt: now.subtract(const Duration(days: 30)),
        ),
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

      expect(find.text('All 3'), findsOneWidget);
      expect(find.text('Passengers 2'), findsOneWidget);
      expect(find.text('Admins 1'), findsOneWidget);

      expect(find.text('Alice Admin'), findsOneWidget);
      expect(find.text('Bob Passenger'), findsOneWidget);
      expect(find.text('Charlie Passenger'), findsOneWidget);

      await tester.tap(find.text('Admins 1'));
      await tester.pumpAndSettle();

      expect(find.text('Alice Admin'), findsOneWidget);
      expect(find.text('Bob Passenger'), findsNothing);
      expect(find.text('Charlie Passenger'), findsNothing);

      await tester.tap(find.text('Passengers 2'));
      await tester.pumpAndSettle();

      expect(find.text('Alice Admin'), findsNothing);
      expect(find.text('Bob Passenger'), findsOneWidget);
      expect(find.text('Charlie Passenger'), findsOneWidget);

      await tester.tap(find.text('All 3'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Admins 1'));
      await tester.pumpAndSettle();

      final searchField = find.widgetWithText(
        TextField,
        'Search by name or ID...',
      );
      await tester.enterText(searchField, 'bob');
      await tester.pumpAndSettle();

      expect(find.text('Alice Admin'), findsNothing);
      expect(find.text('Bob Passenger'), findsNothing);
      expect(find.text('No accounts matching "bob"'), findsOneWidget);

      await tester.enterText(searchField, 'alice');
      await tester.pumpAndSettle();

      expect(find.text('Alice Admin'), findsOneWidget);
      expect(find.text('Bob Passenger'), findsNothing);

      await tester.enterText(searchField, '');
      await tester.tap(find.text('All 3'));
      await tester.pumpAndSettle();

      var posBob = tester.getTopLeft(find.text('Bob Passenger')).dy;
      var posAlice = tester.getTopLeft(find.text('Alice Admin')).dy;
      var posCharlie = tester.getTopLeft(find.text('Charlie Passenger')).dy;
      expect(posBob < posAlice, isTrue);
      expect(posAlice < posCharlie, isTrue);

      await tester.tap(find.text('Newest first'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Oldest first').last);
      await tester.pumpAndSettle();

      posBob = tester.getTopLeft(find.text('Bob Passenger')).dy;
      posAlice = tester.getTopLeft(find.text('Alice Admin')).dy;
      posCharlie = tester.getTopLeft(find.text('Charlie Passenger')).dy;
      expect(posCharlie < posAlice, isTrue);
      expect(posAlice < posBob, isTrue);

      await tester.tap(find.text('Oldest first'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Name A–Z').last);
      await tester.pumpAndSettle();

      posBob = tester.getTopLeft(find.text('Bob Passenger')).dy;
      posAlice = tester.getTopLeft(find.text('Alice Admin')).dy;
      posCharlie = tester.getTopLeft(find.text('Charlie Passenger')).dy;
      expect(posAlice < posBob, isTrue);
      expect(posBob < posCharlie, isTrue);

      await tester.tap(find.text('Alice Admin'));
      await tester.pumpAndSettle();

      expect(find.text('Account Details'), findsOneWidget);
      expect(find.text('u-1'), findsOneWidget);
      expect(find.text('Administrator (public.user_roles)'), findsOneWidget);
    },
  );

  testWidgets('renders Notices tab with status filtering and live counts', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final now = DateTime.now();
    final notices = [
      ServiceNotice(
        id: 'n1',
        title: 'Kelana Jaya Track Delay',
        body: 'Delays of 15 minutes due to signal issue',
        category: NoticeCategory.delay,
        severity: NoticeSeverity.warning,
        source: NoticeSource.smartRoute,
        routeId: 'r1',
        startsAt: now.subtract(const Duration(minutes: 10)),
        endsAt: now.add(const Duration(hours: 2)),
        status: NoticeStatus.published,
        createdBy: 'admin-1',
        updatedAt: now,
      ),
      ServiceNotice(
        id: 'n2',
        title: 'Upcoming Inspection Draft',
        body: 'Scheduled inspection work',
        category: NoticeCategory.maintenance,
        severity: NoticeSeverity.info,
        source: NoticeSource.smartRoute,
        routeId: 'r1',
        startsAt: now.add(const Duration(days: 1)),
        endsAt: null,
        status: NoticeStatus.draft,
        createdBy: 'admin-1',
        updatedAt: now.subtract(const Duration(hours: 1)),
      ),
      ServiceNotice(
        id: 'n3',
        title: 'Yesterday Incident Archived',
        body: 'Resolved issue from yesterday',
        category: NoticeCategory.service,
        severity: NoticeSeverity.severe,
        source: NoticeSource.smartRoute,
        routeId: 'r2',
        startsAt: now.subtract(const Duration(days: 1)),
        endsAt: null,
        status: NoticeStatus.archived,
        createdBy: 'admin-1',
        updatedAt: now.subtract(const Duration(hours: 5)),
      ),
    ];

    final noticeRepo = _FakeNoticeRepository(notices: notices);
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

    await tester.tap(find.text('Notices'));
    await tester.pumpAndSettle();

    expect(find.text('All 3'), findsOneWidget);
    expect(find.text('Published 1'), findsOneWidget);
    expect(find.text('Draft 1'), findsOneWidget);
    expect(find.text('Archived 1'), findsOneWidget);
    expect(find.text('SERVICE NOTICES (3)'), findsOneWidget);

    expect(find.text('Kelana Jaya Track Delay'), findsOneWidget);
    expect(find.text('Upcoming Inspection Draft'), findsOneWidget);
    expect(find.text('Yesterday Incident Archived'), findsOneWidget);

    await tester.tap(find.text('Published 1'));
    await tester.pumpAndSettle();

    expect(find.text('SERVICE NOTICES (1)'), findsOneWidget);
    expect(find.text('Kelana Jaya Track Delay'), findsOneWidget);
    expect(find.text('Upcoming Inspection Draft'), findsNothing);
    expect(find.text('Yesterday Incident Archived'), findsNothing);

    await tester.tap(find.text('Draft 1'));
    await tester.pumpAndSettle();

    expect(find.text('SERVICE NOTICES (1)'), findsOneWidget);
    expect(find.text('Kelana Jaya Track Delay'), findsNothing);
    expect(find.text('Upcoming Inspection Draft'), findsOneWidget);
    expect(find.text('Yesterday Incident Archived'), findsNothing);

    await tester.tap(find.text('Archived 1'));
    await tester.pumpAndSettle();

    expect(find.text('SERVICE NOTICES (1)'), findsOneWidget);
    expect(find.text('Kelana Jaya Track Delay'), findsNothing);
    expect(find.text('Upcoming Inspection Draft'), findsNothing);
    expect(find.text('Yesterday Incident Archived'), findsOneWidget);

    await tester.tap(find.text('All 3'));
    await tester.pumpAndSettle();

    expect(find.text('SERVICE NOTICES (3)'), findsOneWidget);
    expect(find.text('Kelana Jaya Track Delay'), findsOneWidget);
    expect(find.text('Upcoming Inspection Draft'), findsOneWidget);
    expect(find.text('Yesterday Incident Archived'), findsOneWidget);

    final archiveButton = find.byTooltip('Archive notice').first;
    await tester.tap(archiveButton);
    await tester.pumpAndSettle();

    expect(find.text('All 2'), findsOneWidget);
    expect(find.text('Published 0'), findsOneWidget);
    expect(find.text('Draft 1'), findsOneWidget);
    expect(find.text('Archived 1'), findsOneWidget);
    expect(find.text('SERVICE NOTICES (2)'), findsOneWidget);
  });
}
