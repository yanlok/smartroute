import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/user_management/data/repositories/supabase_profile_repository.dart';
import 'package:smartroute/features/user_management/domain/exceptions/profile_repository_exception.dart';
import 'package:smartroute/features/user_management/domain/models/user_preferences.dart';
import 'package:smartroute/features/user_management/domain/models/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeSupabaseClient extends Fake implements SupabaseClient {
  final FakeSupabaseQueryBuilder profilesQuery;
  final FakeSupabaseQueryBuilder preferencesQuery;

  FakeSupabaseClient({
    required this.profilesQuery,
    required this.preferencesQuery,
  });

  @override
  SupabaseQueryBuilder from(String table) {
    if (table == 'profiles') return profilesQuery;
    if (table == 'user_preferences') return preferencesQuery;
    throw UnimplementedError('Table $table not configured');
  }
}

// ignore: must_be_immutable
class FakeSupabaseQueryBuilder extends Fake implements SupabaseQueryBuilder {
  Map<String, dynamic>? queryResult;
  bool shouldThrow = false;
  Map<String, dynamic>? lastUpdatePayload;

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([
    String columns = '*',
  ]) {
    return FakePostgrestFilterBuilder(
      queryResult: queryResult,
      shouldThrow: shouldThrow,
    );
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> update(
    Map values, {
    String? defaultToNull,
  }) {
    lastUpdatePayload = Map<String, dynamic>.from(values);
    return FakePostgrestFilterBuilder(
      queryResult: queryResult,
      shouldThrow: shouldThrow,
    );
  }
}

class FakePostgrestFilterBuilder extends Fake
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  final Map<String, dynamic>? queryResult;
  final bool shouldThrow;

  FakePostgrestFilterBuilder({this.queryResult, this.shouldThrow = false});

  Future<List<Map<String, dynamic>>> get _future => shouldThrow
      ? Future.error(Exception('Postgrest query error'))
      : Future.value(<Map<String, dynamic>>[]);

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> eq(
    String column,
    Object value,
  ) {
    return this;
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([
    String columns = '*',
  ]) {
    return this;
  }

  @override
  PostgrestTransformBuilder<Map<String, dynamic>?> maybeSingle() {
    return FakePostgrestTransformBuilder(
      result: queryResult,
      shouldThrow: shouldThrow,
    );
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

class FakePostgrestTransformBuilder extends Fake
    implements PostgrestTransformBuilder<Map<String, dynamic>?> {
  final Map<String, dynamic>? result;
  final bool shouldThrow;

  FakePostgrestTransformBuilder({this.result, this.shouldThrow = false});

  Future<Map<String, dynamic>?> get _future => shouldThrow
      ? Future.error(Exception('Postgrest transform error'))
      : Future.value(result);

  @override
  Future<R> then<R>(
    FutureOr<R> Function(Map<String, dynamic>? value) onValue, {
    Function? onError,
  }) => _future.then(onValue, onError: onError);

  @override
  Future<Map<String, dynamic>?> catchError(
    Function onError, {
    bool Function(Object error)? test,
  }) => _future.catchError(onError, test: test);

  @override
  Future<Map<String, dynamic>?> whenComplete(
    FutureOr<void> Function() action,
  ) => _future.whenComplete(action);
}

void main() {
  late FakeSupabaseClient fakeClient;
  late FakeSupabaseQueryBuilder fakeProfilesQuery;
  late FakeSupabaseQueryBuilder fakePreferencesQuery;
  late SupabaseProfileRepository repository;

  setUp(() {
    fakeProfilesQuery = FakeSupabaseQueryBuilder();
    fakePreferencesQuery = FakeSupabaseQueryBuilder();
    fakeClient = FakeSupabaseClient(
      profilesQuery: fakeProfilesQuery,
      preferencesQuery: fakePreferencesQuery,
    );

    repository = SupabaseProfileRepository(client: fakeClient);
  });

  group('SupabaseProfileRepository - getProfile', () {
    test('throws exception when userId is empty', () async {
      await expectLater(
        repository.getProfile(userId: '   '),
        throwsA(
          isA<ProfileRepositoryException>().having(
            (e) => e.message,
            'message',
            'User ID is required.',
          ),
        ),
      );
    });

    test(
      'returns mapped UserProfile with trimmed name and normalized photoUrl',
      () async {
        fakeProfilesQuery.queryResult = {
          'id': 'u-123',
          'full_name': '  Jane Doe  ',
          'photo_url': '  https://example.com/photo.jpg  ',
        };

        final profile = await repository.getProfile(userId: 'u-123');

        expect(
          profile,
          const UserProfile(
            id: 'u-123',
            fullName: 'Jane Doe',
            photoUrl: 'https://example.com/photo.jpg',
          ),
        );
      },
    );

    test('normalizes empty photoUrl to null', () async {
      fakeProfilesQuery.queryResult = {
        'id': 'u-123',
        'full_name': 'Jane Doe',
        'photo_url': '   ',
      };

      final profile = await repository.getProfile(userId: 'u-123');

      expect(profile.photoUrl, isNull);
    });

    test('throws safe exception when row is not found', () async {
      fakeProfilesQuery.queryResult = null;

      await expectLater(
        repository.getProfile(userId: 'u-missing'),
        throwsA(
          isA<ProfileRepositoryException>().having(
            (e) => e.message,
            'message',
            'Unable to load your profile. Please try again.',
          ),
        ),
      );
    });

    test(
      'throws safe exception when returned id does not match requested userId',
      () async {
        fakeProfilesQuery.queryResult = {
          'id': 'u-different',
          'full_name': 'Jane Doe',
        };

        await expectLater(
          repository.getProfile(userId: 'u-123'),
          throwsA(
            isA<ProfileRepositoryException>().having(
              (e) => e.message,
              'message',
              'Unable to load your profile. Please try again.',
            ),
          ),
        );
      },
    );

    test('throws safe exception on database query error', () async {
      fakeProfilesQuery.shouldThrow = true;

      await expectLater(
        repository.getProfile(userId: 'u-err'),
        throwsA(
          isA<ProfileRepositoryException>().having(
            (e) => e.message,
            'message',
            'Unable to load your profile. Please try again.',
          ),
        ),
      );
    });
  });

  group('SupabaseProfileRepository - getPreferences', () {
    test('returns mapped UserPreferences for valid row', () async {
      fakePreferencesQuery.queryResult = {
        'user_id': 'u-123',
        'notifications_enabled': false,
        'location_enabled': true,
        'language': 'ms',
      };

      final prefs = await repository.getPreferences(userId: 'u-123');

      expect(
        prefs,
        const UserPreferences(
          notificationsEnabled: false,
          locationEnabled: true,
          language: 'ms',
        ),
      );
    });

    test(
      'throws safe exception when notifications_enabled is missing or null',
      () async {
        fakePreferencesQuery.queryResult = {
          'user_id': 'u-123',
          'location_enabled': true,
          'language': 'en',
        };

        await expectLater(
          repository.getPreferences(userId: 'u-123'),
          throwsA(
            isA<ProfileRepositoryException>().having(
              (e) => e.message,
              'message',
              'Unable to load your preferences. Please try again.',
            ),
          ),
        );
      },
    );

    test('throws safe exception when location_enabled is wrong type', () async {
      fakePreferencesQuery.queryResult = {
        'user_id': 'u-123',
        'notifications_enabled': true,
        'location_enabled': 'not_a_bool',
        'language': 'en',
      };

      await expectLater(
        repository.getPreferences(userId: 'u-123'),
        throwsA(
          isA<ProfileRepositoryException>().having(
            (e) => e.message,
            'message',
            'Unable to load your preferences. Please try again.',
          ),
        ),
      );
    });

    test('throws safe exception when language is not en or ms', () async {
      fakePreferencesQuery.queryResult = {
        'user_id': 'u-123',
        'notifications_enabled': true,
        'location_enabled': true,
        'language': 'invalid_lang',
      };

      await expectLater(
        repository.getPreferences(userId: 'u-123'),
        throwsA(
          isA<ProfileRepositoryException>().having(
            (e) => e.message,
            'message',
            'Unable to load your preferences. Please try again.',
          ),
        ),
      );
    });

    test(
      'throws safe exception when preferences row is missing user_id',
      () async {
        fakePreferencesQuery.queryResult = {
          'notifications_enabled': true,
          'location_enabled': true,
          'language': 'en',
        };

        await expectLater(
          repository.getPreferences(userId: 'u-123'),
          throwsA(
            isA<ProfileRepositoryException>().having(
              (e) => e.message,
              'message',
              'Unable to load your preferences. Please try again.',
            ),
          ),
        );
      },
    );

    test(
      'throws safe exception when preferences returned user_id mismatches',
      () async {
        fakePreferencesQuery.queryResult = {
          'user_id': 'u-mismatch',
          'notifications_enabled': true,
          'location_enabled': true,
          'language': 'en',
        };

        await expectLater(
          repository.getPreferences(userId: 'u-123'),
          throwsA(
            isA<ProfileRepositoryException>().having(
              (e) => e.message,
              'message',
              'Unable to load your preferences. Please try again.',
            ),
          ),
        );
      },
    );

    test('throws safe exception when preferences row is missing', () async {
      fakePreferencesQuery.queryResult = null;

      await expectLater(
        repository.getPreferences(userId: 'u-missing'),
        throwsA(
          isA<ProfileRepositoryException>().having(
            (e) => e.message,
            'message',
            'Unable to load your preferences. Please try again.',
          ),
        ),
      );
    });
  });

  group('SupabaseProfileRepository - updateProfile', () {
    test('throws validation exception when fullName is empty', () async {
      await expectLater(
        repository.updateProfile(userId: 'u-123', fullName: '   '),
        throwsA(
          isA<ProfileRepositoryException>().having(
            (e) => e.message,
            'message',
            'Full name is required.',
          ),
        ),
      );
    });

    test('updates profile and returns mapped server row result', () async {
      fakeProfilesQuery.queryResult = {
        'id': 'u-123',
        'full_name': 'Jane Server Confirmed',
        'photo_url': 'https://example.com/server.png',
      };

      final result = await repository.updateProfile(
        userId: 'u-123',
        fullName: '  Jane Client Input  ',
        photoUrl: '  https://example.com/client.png  ',
      );

      expect(
        result,
        const UserProfile(
          id: 'u-123',
          fullName: 'Jane Server Confirmed',
          photoUrl: 'https://example.com/server.png',
        ),
      );
      expect(
        fakeProfilesQuery.lastUpdatePayload?['full_name'],
        'Jane Client Input',
      );
      expect(
        fakeProfilesQuery.lastUpdatePayload?['photo_url'],
        'https://example.com/client.png',
      );
    });

    test(
      'throws safe exception when update returns zero rows (null)',
      () async {
        fakeProfilesQuery.queryResult = null;

        await expectLater(
          repository.updateProfile(userId: 'u-123', fullName: 'Jane Doe'),
          throwsA(
            isA<ProfileRepositoryException>().having(
              (e) => e.message,
              'message',
              'Unable to update your profile. Please try again.',
            ),
          ),
        );
      },
    );

    test('throws safe exception on database update failure', () async {
      fakeProfilesQuery.shouldThrow = true;

      await expectLater(
        repository.updateProfile(userId: 'u-123', fullName: 'Jane Error'),
        throwsA(
          isA<ProfileRepositoryException>().having(
            (e) => e.message,
            'message',
            'Unable to update your profile. Please try again.',
          ),
        ),
      );
    });
  });

  group('SupabaseProfileRepository - updatePreferences', () {
    test('throws validation exception on invalid language', () async {
      await expectLater(
        repository.updatePreferences(
          userId: 'u-123',
          preferences: const UserPreferences(language: 'fr'),
        ),
        throwsA(
          isA<ProfileRepositoryException>().having(
            (e) => e.message,
            'message',
            'Language must be English (en) or Bahasa Melayu (ms).',
          ),
        ),
      );
    });

    test('updates preferences and returns mapped server row result', () async {
      fakePreferencesQuery.queryResult = {
        'user_id': 'u-123',
        'notifications_enabled': false,
        'location_enabled': false,
        'language': 'ms',
      };

      const prefs = UserPreferences(
        notificationsEnabled: false,
        locationEnabled: false,
        language: 'ms',
      );

      final result = await repository.updatePreferences(
        userId: 'u-123',
        preferences: prefs,
      );

      expect(result, prefs);
      expect(
        fakePreferencesQuery.lastUpdatePayload?['notifications_enabled'],
        false,
      );
      expect(
        fakePreferencesQuery.lastUpdatePayload?['location_enabled'],
        false,
      );
      expect(fakePreferencesQuery.lastUpdatePayload?['language'], 'ms');
    });

    test(
      'throws safe exception when update preferences returns zero rows (null)',
      () async {
        fakePreferencesQuery.queryResult = null;

        await expectLater(
          repository.updatePreferences(
            userId: 'u-123',
            preferences: const UserPreferences(language: 'en'),
          ),
          throwsA(
            isA<ProfileRepositoryException>().having(
              (e) => e.message,
              'message',
              'Unable to update your preferences. Please try again.',
            ),
          ),
        );
      },
    );

    test(
      'throws safe exception on database update preferences failure',
      () async {
        fakePreferencesQuery.shouldThrow = true;

        await expectLater(
          repository.updatePreferences(
            userId: 'u-123',
            preferences: const UserPreferences(language: 'en'),
          ),
          throwsA(
            isA<ProfileRepositoryException>().having(
              (e) => e.message,
              'message',
              'Unable to update your preferences. Please try again.',
            ),
          ),
        );
      },
    );
  });
}
