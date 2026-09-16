import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/contracts/notice_repository.dart';
import '../../../shared/models/notice_models.dart';

class NoticeController extends ChangeNotifier {
  final NoticeRepository _repository;
  List<ServiceNotice> _notices = const [];
  Set<String> _readIds = const {};
  Set<String> _subscribedRouteIds = const {};
  Set<String> _favoriteRouteIds = const {};
  Set<String> _favoriteStationRouteIds = const {};
  List<SourceHealth> _sourceHealth = const [];
  List<AdminUserSummary> _users = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isAdmin = false;
  bool _notificationsEnabled = true;
  String? _userId;
  String? _errorMessage;
  Timer? _activityTimer;

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
      activeNotices.where((notice) => !_readIds.contains(notice.id)).length;

  bool isFavoriteNotice(ServiceNotice notice) =>
      _favoriteRouteIds.contains(notice.routeId);

  List<ServiceNotice> get activeNotices {
    if (!_notificationsEnabled) return const [];
    final now = DateTime.now();
    final notices = _notices.where((notice) => notice.isActiveAt(now)).toList();
    notices.sort((a, b) {
      final favoriteOrder = (isFavoriteNotice(b) ? 1 : 0).compareTo(
        isFavoriteNotice(a) ? 1 : 0,
      );
      return favoriteOrder != 0
          ? favoriteOrder
          : b.startsAt.compareTo(a.startsAt);
    });
    return notices;
  }

  List<ServiceNotice> get relevantNotices => activeNotices
      .where(
        (notice) =>
            _subscribedRouteIds.contains(notice.routeId) ||
            _favoriteRouteIds.contains(notice.routeId),
      )
      .toList();

  List<ServiceNotice> get favoriteStationNotices =>
      activeNoticesForRouteIds(_favoriteStationRouteIds);

  List<ServiceNotice> activeNoticesForRouteIds(Iterable<String> routeIds) {
    final affectedRouteIds = routeIds.toSet();
    final notices = activeNotices
        .where((notice) => affectedRouteIds.contains(notice.routeId))
        .toList();
    notices.sort((a, b) {
      final severityOrder = _severityRank(
        b.severity,
      ).compareTo(_severityRank(a.severity));
      return severityOrder != 0
          ? severityOrder
          : b.updatedAt.compareTo(a.updatedAt);
    });
    return notices;
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
      _scheduleActivityRefresh();
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

  void setFavoriteStationRouteIds(Set<String> routeIds) {
    if (setEquals(_favoriteStationRouteIds, routeIds)) return;
    _favoriteStationRouteIds = Set.unmodifiable(routeIds);
    _scheduleActivityRefresh();
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
    required NoticeCategory category,
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
        category: category,
        severity: severity,
        routeId: routeId,
        startsAt: startsAt,
        endsAt: endsAt,
        status: status,
      );
      _notices = [notice, ..._notices.where((item) => item.id != notice.id)];
      _scheduleActivityRefresh();
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
      _scheduleActivityRefresh();
      return true;
    } catch (_) {
      _errorMessage = 'Service notice could not be archived.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deletePassengerAccount(String userId) async {
    if (!_isAdmin || _isSaving) return false;
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.deletePassengerAccount(userId);
      _users = _users.where((user) => user.id != userId).toList();
      return true;
    } catch (_) {
      _errorMessage =
          'Passenger account could not be deleted. Please try again.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void reset() {
    _activityTimer?.cancel();
    _notices = const [];
    _readIds = const {};
    _subscribedRouteIds = const {};
    _favoriteRouteIds = const {};
    _favoriteStationRouteIds = const {};
    _sourceHealth = const [];
    _users = const [];
    _isAdmin = false;
    _userId = null;
    _errorMessage = null;
    _isLoading = false;
    _isSaving = false;
    notifyListeners();
  }

  int _severityRank(NoticeSeverity severity) => switch (severity) {
    NoticeSeverity.info => 0,
    NoticeSeverity.warning => 1,
    NoticeSeverity.severe => 2,
  };

  void _scheduleActivityRefresh() {
    _activityTimer?.cancel();
    if (_favoriteStationRouteIds.isEmpty) return;
    final now = DateTime.now();
    DateTime? nextChange;
    for (final notice in _notices) {
      if (notice.status != NoticeStatus.published) continue;
      for (final boundary in [notice.startsAt, notice.endsAt]) {
        if (boundary != null &&
            boundary.isAfter(now) &&
            (nextChange == null || boundary.isBefore(nextChange))) {
          nextChange = boundary;
        }
      }
    }
    if (nextChange == null) return;
    _activityTimer = Timer(
      nextChange.difference(now) + const Duration(milliseconds: 10),
      () {
        notifyListeners();
        _scheduleActivityRefresh();
      },
    );
  }

  @override
  void dispose() {
    _activityTimer?.cancel();
    super.dispose();
  }
}
