import 'package:flutter/foundation.dart';

import '../../../shared/contracts/notice_repository.dart';
import '../../../shared/models/notice_models.dart';

class NoticeController extends ChangeNotifier {
  final NoticeRepository _repository;
  List<ServiceNotice> _notices = const [];
  Set<String> _readIds = const {};
  Set<String> _subscribedRouteIds = const {};
  Set<String> _favoriteRouteIds = const {};
  List<SourceHealth> _sourceHealth = const [];
  List<AdminUserSummary> _users = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isAdmin = false;
  bool _notificationsEnabled = true;
  String? _userId;
  String? _errorMessage;

  NoticeController({required NoticeRepository repository})
    : _repository = repository;

  List<ServiceNotice> get notices => _notices;
  Set<String> get subscribedRouteIds => _subscribedRouteIds;
  List<SourceHealth> get sourceHealth => _sourceHealth;
  List<AdminUserSummary> get users => _users;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isAdmin => _isAdmin;
  String? get errorMessage => _errorMessage;
  int get unreadCount =>
      relevantNotices.where((notice) => !_readIds.contains(notice.id)).length;

  List<ServiceNotice> get relevantNotices {
    if (!_notificationsEnabled) return const [];
    final now = DateTime.now();
    return _notices
        .where(
          (notice) =>
              notice.isActiveAt(now) &&
              (_subscribedRouteIds.contains(notice.routeId) ||
                  _favoriteRouteIds.contains(notice.routeId)),
        )
        .toList();
  }

  Future<void> load({
    required String userId,
    required bool notificationsEnabled,
  }) async {
    if (_isLoading) return;
    _isLoading = true;
    _userId = userId;
    _notificationsEnabled = notificationsEnabled;
    _errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repository.isAdmin(userId),
        _repository.getNotices(),
        _repository.getReadNoticeIds(userId),
        _repository.getSubscribedRouteIds(userId),
      ]);
      _isAdmin = results[0] as bool;
      _notices = results[1] as List<ServiceNotice>;
      _readIds = results[2] as Set<String>;
      _subscribedRouteIds = results[3] as Set<String>;
      if (_isAdmin) {
        final adminResults = await Future.wait([
          _repository.getSourceHealth(),
          _repository.getUsers(),
        ]);
        _sourceHealth = adminResults[0] as List<SourceHealth>;
        _users = adminResults[1] as List<AdminUserSummary>;
      }
    } catch (_) {
      _errorMessage = 'Service notices could not be loaded. Try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reload() async {
    final userId = _userId;
    if (userId == null) return;
    await load(userId: userId, notificationsEnabled: _notificationsEnabled);
  }

  bool isRead(ServiceNotice notice) => _readIds.contains(notice.id);

  void setFavoriteRouteIds(Set<String> routeIds) {
    if (setEquals(_favoriteRouteIds, routeIds)) return;
    _favoriteRouteIds = Set.unmodifiable(routeIds);
    notifyListeners();
  }

  Future<void> markRead(ServiceNotice notice) async {
    final userId = _userId;
    if (userId == null || _readIds.contains(notice.id)) return;
    try {
      await _repository.markRead(userId: userId, noticeId: notice.id);
      _readIds = {..._readIds, notice.id};
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Notification state could not be updated.';
      notifyListeners();
    }
  }

  Future<bool> setSubscribed(String routeId, bool enabled) async {
    final userId = _userId;
    if (userId == null) return false;
    try {
      await _repository.setSubscription(
        userId: userId,
        routeId: routeId,
        enabled: enabled,
      );
      _subscribedRouteIds = {..._subscribedRouteIds};
      enabled
          ? _subscribedRouteIds.add(routeId)
          : _subscribedRouteIds.remove(routeId);
      notifyListeners();
      return true;
    } catch (_) {
      _errorMessage = 'Route subscription could not be updated.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveNotice({
    String? id,
    required String title,
    required String body,
    required NoticeSeverity severity,
    required String routeId,
    required DateTime startsAt,
    DateTime? endsAt,
    required NoticeStatus status,
  }) async {
    final userId = _userId;
    if (!_isAdmin || userId == null || _isSaving) return false;
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final notice = await _repository.saveNotice(
        id: id,
        userId: userId,
        title: title,
        body: body,
        severity: severity,
        routeId: routeId,
        startsAt: startsAt,
        endsAt: endsAt,
        status: status,
      );
      _notices = [notice, ..._notices.where((item) => item.id != notice.id)];
      return true;
    } catch (_) {
      _errorMessage = 'Service notice could not be saved.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> archive(ServiceNotice notice) async {
    if (!_isAdmin || _isSaving) return false;
    _isSaving = true;
    notifyListeners();
    try {
      await _repository.archiveNotice(notice.id);
      _notices = _notices.where((item) => item.id != notice.id).toList();
      return true;
    } catch (_) {
      _errorMessage = 'Service notice could not be archived.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void reset() {
    _notices = const [];
    _readIds = const {};
    _subscribedRouteIds = const {};
    _favoriteRouteIds = const {};
    _sourceHealth = const [];
    _users = const [];
    _isAdmin = false;
    _userId = null;
    _errorMessage = null;
    _isLoading = false;
    _isSaving = false;
    notifyListeners();
  }
}
