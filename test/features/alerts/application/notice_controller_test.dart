import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/alerts/application/notice_controller.dart';
import 'package:smartroute/shared/contracts/notice_repository.dart';
import 'package:smartroute/shared/models/notice_models.dart';

void main() {
  late _MemoryNoticeRepository repository;
  late NoticeController controller;

  setUp(() {
    repository = _MemoryNoticeRepository();
    controller = NoticeController(repository: repository);
  });

  tearDown(() => controller.dispose());

  test('only subscribed active notices are relevant and unread', () async {
    repository.notices.addAll([
      _notice(id: 'active', routeId: 'route-a'),
      _notice(id: 'unrelated', routeId: 'route-b'),
      _notice(
        id: 'expired',
        routeId: 'route-a',
        endsAt: DateTime.now().subtract(const Duration(minutes: 1)),
      ),
    ]);
    repository.subscriptions.add('route-a');

    await controller.load(userId: 'user-a', notificationsEnabled: true);

    expect(controller.relevantNotices.map((item) => item.id), ['active']);
    expect(controller.unreadCount, 1);
  });

  test('favourite journey route makes a notice relevant', () async {
    repository.notices.add(_notice(id: 'favorite', routeId: 'route-c'));
    await controller.load(userId: 'user-a', notificationsEnabled: true);

    controller.setFavoriteRouteIds({'route-c'});

    expect(controller.relevantNotices.single.id, 'favorite');
  });

  test('mark read persists and updates unread state', () async {
    final notice = _notice(id: 'notice', routeId: 'route-a');
    repository.notices.add(notice);
    repository.subscriptions.add('route-a');
    await controller.load(userId: 'user-a', notificationsEnabled: true);

    await controller.markRead(notice);

    expect(repository.readIds, contains('notice'));
    expect(controller.unreadCount, 0);
  });

  test('notifications preference suppresses in-app relevance', () async {
    repository.notices.add(_notice(id: 'notice', routeId: 'route-a'));
    repository.subscriptions.add('route-a');

    await controller.load(userId: 'user-a', notificationsEnabled: false);

    expect(controller.relevantNotices, isEmpty);
  });

  test('admin can publish and archive a SmartRoute notice', () async {
    repository.admin = true;
    await controller.load(userId: 'admin-a', notificationsEnabled: true);

    expect(
      await controller.saveNotice(
        title: 'Line maintenance',
        body: 'Use the alternate platform.',
        severity: NoticeSeverity.warning,
        routeId: 'route-a',
        startsAt: DateTime.now().subtract(const Duration(minutes: 1)),
        status: NoticeStatus.published,
      ),
      isTrue,
    );
    final notice = controller.notices.single;
    expect(notice.source, NoticeSource.smartRoute);
    expect(notice.status, NoticeStatus.published);

    expect(await controller.archive(notice), isTrue);
    expect(controller.notices, isEmpty);
    expect(repository.archived, contains(notice.id));
  });

  test('passenger cannot invoke admin notice mutation', () async {
    await controller.load(userId: 'user-a', notificationsEnabled: true);

    final result = await controller.saveNotice(
      title: 'Unauthorized',
      body: 'Should not save',
      severity: NoticeSeverity.info,
      routeId: 'route-a',
      startsAt: DateTime.now(),
      status: NoticeStatus.published,
    );

    expect(result, isFalse);
    expect(repository.notices, isEmpty);
  });
}

class _MemoryNoticeRepository implements NoticeRepository {
  bool admin = false;
  final List<ServiceNotice> notices = [];
  final Set<String> readIds = {};
  final Set<String> subscriptions = {};
  final Set<String> archived = {};

  @override
  Future<void> archiveNotice(String noticeId) async {
    archived.add(noticeId);
  }

  @override
  Future<List<ServiceNotice>> getNotices() async => List.unmodifiable(notices);

  @override
  Future<Set<String>> getReadNoticeIds(String userId) async => {...readIds};

  @override
  Future<List<SourceHealth>> getSourceHealth() async => const [];

  @override
  Future<Set<String>> getSubscribedRouteIds(String userId) async => {
    ...subscriptions,
  };

  @override
  Future<List<AdminUserSummary>> getUsers() async => const [];

  @override
  Future<bool> isAdmin(String userId) async => admin;

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
    required NoticeSeverity severity,
    required String routeId,
    required DateTime startsAt,
    DateTime? endsAt,
    required NoticeStatus status,
  }) async {
    final result = ServiceNotice(
      id: id ?? 'notice-${notices.length}',
      title: title,
      body: body,
      severity: severity,
      source: NoticeSource.smartRoute,
      routeId: routeId,
      startsAt: startsAt,
      endsAt: endsAt,
      status: status,
      createdBy: userId,
      updatedAt: DateTime.now(),
    );
    notices.removeWhere((item) => item.id == result.id);
    notices.add(result);
    return result;
  }

  @override
  Future<void> setSubscription({
    required String userId,
    required String routeId,
    required bool enabled,
  }) async {
    enabled ? subscriptions.add(routeId) : subscriptions.remove(routeId);
  }
}

ServiceNotice _notice({
  required String id,
  required String routeId,
  DateTime? endsAt,
}) => ServiceNotice(
  id: id,
  title: 'Notice $id',
  body: 'Affected service information',
  severity: NoticeSeverity.warning,
  source: NoticeSource.smartRoute,
  routeId: routeId,
  startsAt: DateTime.now().subtract(const Duration(minutes: 5)),
  endsAt: endsAt,
  status: NoticeStatus.published,
  createdBy: 'admin-a',
  updatedAt: DateTime.now(),
);
