import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/contracts/notice_repository.dart';
import '../../../shared/models/notice_models.dart';

class SupabaseNoticeRepository implements NoticeRepository {
  final SupabaseClient _client;

  const SupabaseNoticeRepository({required SupabaseClient client})
    : _client = client;

  @override
  Future<bool> isAdmin(String userId) async {
    try {
      final row = await _client
          .from('user_roles')
          .select('role')
          .eq('user_id', userId)
          .maybeSingle();
      return row?['role'] == 'admin';
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<ServiceNotice>> getNotices() async {
    try {
      final rows = await _loadNoticeRows();
      return [for (final row in rows) _notice(row)];
    } catch (_) {
      throw const NoticeRepositoryException(
        'Service notices could not be loaded.',
      );
    }
  }

  @override
  Future<Set<String>> getReadNoticeIds(String userId) async {
    try {
      final rows = await _client
          .from('notification_read_state')
          .select('notice_id')
          .eq('user_id', userId);
      return {for (final row in rows) row['notice_id']! as String};
    } catch (_) {
      throw const NoticeRepositoryException(
        'Notification state could not be loaded.',
      );
    }
  }

  @override
  Future<Set<String>> getSubscribedRouteIds(String userId) async {
    try {
      final rows = await _client
          .from('notification_subscriptions')
          .select('route_id')
          .eq('user_id', userId);
      return {for (final row in rows) row['route_id']! as String};
    } catch (_) {
      throw const NoticeRepositoryException(
        'Route subscriptions could not be loaded.',
      );
    }
  }

  @override
  Future<void> markRead({
    required String userId,
    required String noticeId,
  }) async {
    try {
      await _client.from('notification_read_state').upsert({
        'user_id': userId,
        'notice_id': noticeId,
        'read_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id,notice_id');
    } catch (_) {
      throw const NoticeRepositoryException(
        'Notification could not be marked read.',
      );
    }
  }

  @override
  Future<void> setSubscription({
    required String userId,
    required String routeId,
    required bool enabled,
  }) async {
    try {
      if (enabled) {
        await _client.from('notification_subscriptions').upsert({
          'user_id': userId,
          'route_id': routeId,
        }, onConflict: 'user_id,route_id');
      } else {
        await _client
            .from('notification_subscriptions')
            .delete()
            .eq('user_id', userId)
            .eq('route_id', routeId);
      }
    } catch (_) {
      throw const NoticeRepositoryException(
        'Route subscription could not be updated.',
      );
    }
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
  }) async {
    final values = <String, Object?>{
      'title': title.trim(),
      'body': body.trim(),
      'category': category.name,
      'severity': severity.name,
      'source': 'smartroute',
      'route_id': routeId,
      'starts_at': startsAt.toUtc().toIso8601String(),
      'ends_at': endsAt?.toUtc().toIso8601String(),
      'status': status.name,
      'created_by': userId,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (id != null) {
      values['id'] = id;
    }
    try {
      final row = await _saveNoticeRow(values);
      return _notice(row);
    } catch (_) {
      throw const NoticeRepositoryException(
        'Service notice could not be saved.',
      );
    }
  }

  Future<List<Map<String, dynamic>>> _loadNoticeRows() async {
    try {
      return await _client
          .from('service_notices')
          .select(
            'id, title, body, category, severity, source, route_id, starts_at, ends_at, status, created_by, updated_at',
          )
          .order('starts_at', ascending: false);
    } catch (_) {
      return await _client
          .from('service_notices')
          .select(
            'id, title, body, severity, source, route_id, starts_at, ends_at, status, created_by, updated_at',
          )
          .order('starts_at', ascending: false);
    }
  }

  Future<Map<String, dynamic>> _saveNoticeRow(
    Map<String, Object?> values,
  ) async {
    try {
      return await _client
          .from('service_notices')
          .upsert(values)
          .select(
            'id, title, body, category, severity, source, route_id, starts_at, ends_at, status, created_by, updated_at',
          )
          .single();
    } catch (_) {
      final compatibleValues = {...values}..remove('category');
      return await _client
          .from('service_notices')
          .upsert(compatibleValues)
          .select(
            'id, title, body, severity, source, route_id, starts_at, ends_at, status, created_by, updated_at',
          )
          .single();
    }
  }

  @override
  Future<void> archiveNotice(String noticeId) async {
    try {
      await _client
          .from('service_notices')
          .update({'status': 'archived'})
          .eq('id', noticeId);
    } catch (_) {
      throw const NoticeRepositoryException(
        'Service notice could not be archived.',
      );
    }
  }

  @override
  Future<List<SourceHealth>> getSourceHealth() async {
    try {
      final rows = await _client
          .from('source_metadata')
          .select(
            'source_id, display_name, source_type, status, checked_at, data_timestamp, record_count, details',
          )
          .order('display_name');
      return [for (final row in rows) _health(row)];
    } catch (_) {
      throw const NoticeRepositoryException(
        'Data-source health could not be loaded.',
      );
    }
  }

  @override
  Future<List<AdminUserSummary>> getUsers() async {
    try {
      final profileRows = await _client
          .from('profiles')
          .select('id, full_name, created_at, photo_url')
          .order('created_at', ascending: false)
          .limit(100);

      final roleMap = <String, String>{};
      try {
        final roleRows = await _client
            .from('user_roles')
            .select('user_id, role');
        for (final r in roleRows) {
          final uid = r['user_id']?.toString();
          final role = r['role']?.toString();
          if (uid != null && role != null) {
            roleMap[uid] = role;
          }
        }
      } catch (_) {}

      return [
        for (final row in profileRows)
          AdminUserSummary(
            id: row['id']?.toString() ?? '',
            fullName: (row['full_name'] as String?)?.trim().isNotEmpty == true
                ? (row['full_name'] as String).trim()
                : 'User',
            createdAt: row['created_at'] != null
                ? DateTime.tryParse(row['created_at'].toString()) ??
                      DateTime.now()
                : DateTime.now(),
            role: roleMap[row['id']?.toString()] ?? 'passenger',
            photoUrl: row['photo_url'] as String?,
          ),
      ];
    } catch (_) {
      throw const NoticeRepositoryException(
        'User overview could not be loaded.',
      );
    }
  }

  ServiceNotice _notice(Map<String, dynamic> row) => ServiceNotice(
    id: row['id']! as String,
    title: row['title']! as String,
    body: row['body']! as String,
    category: _noticeCategory(row),
    severity: NoticeSeverity.values.byName(row['severity']! as String),
    source: row['source'] == 'official'
        ? NoticeSource.official
        : NoticeSource.smartRoute,
    routeId: row['route_id']! as String,
    startsAt: DateTime.parse(row['starts_at']! as String),
    endsAt: row['ends_at'] == null
        ? null
        : DateTime.parse(row['ends_at']! as String),
    status: NoticeStatus.values.byName(row['status']! as String),
    createdBy: row['created_by']! as String,
    updatedAt: DateTime.parse(row['updated_at']! as String),
  );

  NoticeCategory _noticeCategory(Map<String, dynamic> row) {
    final stored = row['category'];
    if (stored is String) {
      for (final category in NoticeCategory.values) {
        if (category.name == stored) return category;
      }
    }
    final content = '${row['title'] ?? ''} ${row['body'] ?? ''}'.toLowerCase();
    if (content.contains('maintenance')) return NoticeCategory.maintenance;
    if (content.contains('delay') || content.contains('disruption')) {
      return NoticeCategory.delay;
    }
    return NoticeCategory.service;
  }

  SourceHealth _health(Map<String, dynamic> row) => SourceHealth(
    id: row['source_id']! as String,
    displayName: row['display_name']! as String,
    type: row['source_type']! as String,
    status: row['status']! as String,
    checkedAt: DateTime.parse(row['checked_at']! as String),
    dataTimestamp: row['data_timestamp'] == null
        ? null
        : DateTime.parse(row['data_timestamp']! as String),
    recordCount: row['record_count'] as int?,
    details: row['details']! as String,
  );
}

class NoticeRepositoryException implements Exception {
  final String message;

  const NoticeRepositoryException(this.message);
}
