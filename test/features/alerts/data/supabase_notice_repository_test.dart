import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/alerts/data/supabase_notice_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeClient extends Fake implements SupabaseClient {
  final _FakeQueryBuilder profilesBuilder;
  final _FakeQueryBuilder userRolesBuilder;

  _FakeClient({required this.profilesBuilder, required this.userRolesBuilder});

  @override
  SupabaseQueryBuilder from(String table) {
    if (table == 'profiles') return profilesBuilder;
    if (table == 'user_roles') return userRolesBuilder;
    throw UnimplementedError('Table $table not supported in test');
  }
}

class _FakeQueryBuilder extends Fake implements SupabaseQueryBuilder {
  final List<Map<String, dynamic>> rows;
  final bool shouldThrow;

  _FakeQueryBuilder({this.rows = const [], this.shouldThrow = false});

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([
    String columns = '*',
  ]) {
    return _FakeFilterBuilder(rows: rows, shouldThrow: shouldThrow);
  }
}

class _FakeFilterBuilder extends Fake
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  final List<Map<String, dynamic>> rows;
  final bool shouldThrow;

  _FakeFilterBuilder({required this.rows, required this.shouldThrow});

  Future<List<Map<String, dynamic>>> get _future => shouldThrow
      ? Future.error(Exception('Query failure'))
      : Future.value(rows);

  @override
  PostgrestTransformBuilder<List<Map<String, dynamic>>> order(
    String column, {
    bool ascending = true,
    bool nullsFirst = false,
    String? referencedTable,
  }) {
    return _FakeTransformBuilder(rows: rows, shouldThrow: shouldThrow);
  }

  @override
  Future<R> then<R>(
    FutureOr<R> Function(List<Map<String, dynamic>> value) onValue, {
    Function? onError,
  }) => _future.then(onValue, onError: onError);

  @override
  Future<List<Map<String, dynamic>>> catchError(
    Function onError, {
    bool Function(Object error)? test,
  }) => _future.catchError(onError, test: test);

  @override
  Future<List<Map<String, dynamic>>> whenComplete(
    FutureOr<void> Function() action,
  ) => _future.whenComplete(action);
}

class _FakeTransformBuilder extends Fake
    implements PostgrestTransformBuilder<List<Map<String, dynamic>>> {
  final List<Map<String, dynamic>> rows;
  final bool shouldThrow;

  _FakeTransformBuilder({required this.rows, required this.shouldThrow});

  Future<List<Map<String, dynamic>>> get _future => shouldThrow
      ? Future.error(Exception('Transform failure'))
      : Future.value(rows);

  @override
  PostgrestTransformBuilder<List<Map<String, dynamic>>> limit(
    int count, {
    String? referencedTable,
  }) {
    return this;
  }

  @override
  Future<R> then<R>(
    FutureOr<R> Function(List<Map<String, dynamic>> value) onValue, {
    Function? onError,
  }) => _future.then(onValue, onError: onError);

  @override
  Future<List<Map<String, dynamic>>> catchError(
    Function onError, {
    bool Function(Object error)? test,
  }) => _future.catchError(onError, test: test);

  @override
  Future<List<Map<String, dynamic>>> whenComplete(
    FutureOr<void> Function() action,
  ) => _future.whenComplete(action);
}

void main() {
  group('SupabaseNoticeRepository.getUsers', () {
    test('successfully returns users paired with their roles', () async {
      final client = _FakeClient(
        profilesBuilder: _FakeQueryBuilder(
          rows: [
            {
              'id': 'u1',
              'full_name': 'Admin User',
              'created_at': '2026-01-01T00:00:00Z',
              'photo_url': 'https://example.com/photo.jpg',
            },
            {
              'id': 'u2',
              'full_name': 'Passenger User',
              'created_at': '2026-01-02T00:00:00Z',
              'photo_url': null,
            },
          ],
        ),
        userRolesBuilder: _FakeQueryBuilder(
          rows: [
            {'user_id': 'u1', 'role': 'admin'},
            {'user_id': 'u2', 'role': 'passenger'},
          ],
        ),
      );

      final repository = SupabaseNoticeRepository(client: client);
      final users = await repository.getUsers();

      expect(users.length, 2);
      expect(users[0].id, 'u1');
      expect(users[0].fullName, 'Admin User');
      expect(users[0].role, 'admin');
      expect(users[0].photoUrl, 'https://example.com/photo.jpg');

      expect(users[1].id, 'u2');
      expect(users[1].fullName, 'Passenger User');
      expect(users[1].role, 'passenger');
      expect(users[1].photoUrl, isNull);
    });

    test(
      'throws NoticeRepositoryException when user_roles query fails',
      () async {
        final client = _FakeClient(
          profilesBuilder: _FakeQueryBuilder(
            rows: [
              {
                'id': 'u1',
                'full_name': 'Admin User',
                'created_at': '2026-01-01T00:00:00Z',
              },
            ],
          ),
          userRolesBuilder: _FakeQueryBuilder(shouldThrow: true),
        );

        final repository = SupabaseNoticeRepository(client: client);

        expect(
          () => repository.getUsers(),
          throwsA(
            isA<NoticeRepositoryException>().having(
              (e) => e.message,
              'message',
              'User overview could not be loaded.',
            ),
          ),
        );
      },
    );

    test(
      'throws NoticeRepositoryException when profiles query fails',
      () async {
        final client = _FakeClient(
          profilesBuilder: _FakeQueryBuilder(shouldThrow: true),
          userRolesBuilder: _FakeQueryBuilder(
            rows: [
              {'user_id': 'u1', 'role': 'admin'},
            ],
          ),
        );

        final repository = SupabaseNoticeRepository(client: client);

        expect(
          () => repository.getUsers(),
          throwsA(
            isA<NoticeRepositoryException>().having(
              (e) => e.message,
              'message',
              'User overview could not be loaded.',
            ),
          ),
        );
      },
    );
  });
}
