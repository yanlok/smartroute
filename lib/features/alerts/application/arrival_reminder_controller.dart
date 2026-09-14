import 'package:flutter/foundation.dart';

import '../../../shared/contracts/arrival_reminder_repository.dart';
import '../../../shared/models/arrival_reminder.dart';

class ArrivalReminderController extends ChangeNotifier {
  final ArrivalReminderRepository _repository;
  final DateTime Function() _clock;

  List<ArrivalReminder> _reminders = const [];
  String? _userId;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  ArrivalReminderController({
    required ArrivalReminderRepository repository,
    DateTime Function()? clock,
  }) : _repository = repository,
       _clock = clock ?? DateTime.now;

  List<ArrivalReminder> get reminders => List.unmodifiable(_reminders);
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  Future<void> load(String userId) async {
    if (_isLoading) return;
    _isLoading = true;
    _userId = userId;
    _errorMessage = null;
    notifyListeners();
    try {
      final savedReminders = await _repository.getReminders(userId);
      final demoReminders = _reminders.where((item) => item.isDemo).toList();
      _reminders = _sort([...savedReminders, ...demoReminders]);
      await _refreshStatuses();
    } catch (_) {
      _errorMessage = 'Arrival reminders could not be loaded. Try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reload() async {
    final userId = _userId;
    if (userId != null) await load(userId);
  }

  Future<bool> create({
    required String stationId,
    required String routeId,
    required DateTime expectedArrival,
    required int leadTimeMinutes,
  }) async {
    final userId = _userId;
    if (userId == null || _isSaving || leadTimeMinutes <= 0) return false;
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final reminder = await _repository.createReminder(
        userId: userId,
        stationId: stationId,
        routeId: routeId,
        expectedArrival: expectedArrival,
        leadTimeMinutes: leadTimeMinutes,
      );
      _reminders = _sort([reminder, ..._reminders]);
      return true;
    } catch (_) {
      _errorMessage = 'Arrival reminder could not be saved.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> disable(ArrivalReminder reminder) =>
      _setStatus(reminder, ArrivalReminderStatus.disabled);

  Future<bool> delete(ArrivalReminder reminder) async {
    if (reminder.isDemo) {
      _reminders = _reminders.where((item) => item.id != reminder.id).toList();
      notifyListeners();
      return true;
    }
    if (_isSaving) return false;
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.deleteReminder(reminder.id);
      _reminders = _reminders.where((item) => item.id != reminder.id).toList();
      return true;
    } catch (_) {
      _errorMessage = 'Arrival reminder could not be deleted.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> _setStatus(
    ArrivalReminder reminder,
    ArrivalReminderStatus status,
  ) async {
    if (reminder.isDemo) {
      _replace(reminder.copyWith(status: status, updatedAt: _clock()));
      notifyListeners();
      return true;
    }
    if (_isSaving || reminder.status == status) return true;
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.updateStatus(reminderId: reminder.id, status: status);
      _replace(reminder.copyWith(status: status, updatedAt: _clock()));
      return true;
    } catch (_) {
      _errorMessage = 'Arrival reminder status could not be updated.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> _refreshStatuses() async {
    final now = _clock();
    final updates = <ArrivalReminder>[];
    for (final reminder in _reminders) {
      final nextStatus = reminder.statusAt(now);
      if (nextStatus == reminder.status) continue;
      if (reminder.isDemo) {
        updates.add(reminder.copyWith(status: nextStatus, updatedAt: now));
        continue;
      }
      await _repository.updateStatus(
        reminderId: reminder.id,
        status: nextStatus,
      );
      updates.add(reminder.copyWith(status: nextStatus, updatedAt: now));
    }
    for (final reminder in updates) {
      _replace(reminder);
    }
  }

  void _replace(ArrivalReminder reminder) {
    _reminders = _sort([
      for (final item in _reminders)
        if (item.id == reminder.id) reminder else item,
    ]);
  }

  List<ArrivalReminder> _sort(List<ArrivalReminder> reminders) {
    reminders.sort((a, b) => a.expectedArrival.compareTo(b.expectedArrival));
    return reminders;
  }

  ArrivalReminder showDemoArrivalNotification({
    required String stationId,
    required String routeId,
    required DateTime expectedArrival,
  }) {
    final now = _clock();
    final reminder = ArrivalReminder(
      id: 'demo:arrival:$routeId:$stationId',
      userId: _userId ?? 'demo-passenger',
      stationId: stationId,
      routeId: routeId,
      expectedArrival: expectedArrival,
      leadTimeMinutes: 5,
      status: ArrivalReminderStatus.triggered,
      createdAt: now,
      updatedAt: now,
    );
    _reminders = _sort([
      reminder,
      for (final item in _reminders)
        if (item.id != reminder.id) item,
    ]);
    notifyListeners();
    return reminder;
  }

  void reset() {
    _reminders = const [];
    _userId = null;
    _isLoading = false;
    _isSaving = false;
    _errorMessage = null;
    notifyListeners();
  }
}
