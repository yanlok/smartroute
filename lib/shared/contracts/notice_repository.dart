import '../models/notice_models.dart';

abstract class NoticeRepository {
  Future<bool> isAdmin(String userId);

  Future<List<ServiceNotice>> getNotices();

  Future<Set<String>> getReadNoticeIds(String userId);

  Future<Set<String>> getSubscribedRouteIds(String userId);

  Future<void> markRead({required String userId, required String noticeId});

  Future<void> setSubscription({
    required String userId,
    required String routeId,
    required bool enabled,
  });

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
  });

  Future<void> archiveNotice(String noticeId);

  Future<List<SourceHealth>> getSourceHealth();

  Future<List<AdminUserSummary>> getUsers();
}
