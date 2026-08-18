import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/user_management/domain/models/app_user.dart';
import 'package:smartroute/features/user_management/domain/models/user_preferences.dart';

void main() {
  group('AppUser model', () {
    test('instantiates with required and optional fields', () {
      const user = AppUser(
        id: '1',
        fullName: 'Alex Lee',
        email: 'alex@example.com',
        photoUrl: 'https://example.com/avatar.png',
      );

      expect(user.id, '1');
      expect(user.fullName, 'Alex Lee');
      expect(user.email, 'alex@example.com');
      expect(user.photoUrl, 'https://example.com/avatar.png');
    });

    test('copyWith creates modified clone', () {
      const user = AppUser(
        id: '1',
        fullName: 'Alex Lee',
        email: 'alex@example.com',
      );

      final updated = user.copyWith(
        fullName: 'Alexander Lee',
        photoUrl: 'https://example.com/new.png',
      );

      expect(updated.id, '1');
      expect(updated.fullName, 'Alexander Lee');
      expect(updated.email, 'alex@example.com');
      expect(updated.photoUrl, 'https://example.com/new.png');
    });

    test('equality and hashCode support value comparison', () {
      const user1 = AppUser(
        id: '1',
        fullName: 'Alex Lee',
        email: 'alex@example.com',
      );
      const user2 = AppUser(
        id: '1',
        fullName: 'Alex Lee',
        email: 'alex@example.com',
      );
      const user3 = AppUser(
        id: '2',
        fullName: 'Alex Lee',
        email: 'alex@example.com',
      );

      expect(user1, equals(user2));
      expect(user1.hashCode, equals(user2.hashCode));
      expect(user1, isNot(equals(user3)));
    });
  });

  group('UserPreferences model', () {
    test(
      'has expected default values including machine-readable language en',
      () {
        const prefs = UserPreferences();

        expect(prefs.notificationsEnabled, isTrue);
        expect(prefs.locationEnabled, isTrue);
        expect(prefs.language, 'en');
      },
    );

    test('copyWith creates modified clone', () {
      const prefs = UserPreferences();
      final updated = prefs.copyWith(
        notificationsEnabled: false,
        language: 'ms',
      );

      expect(updated.notificationsEnabled, isFalse);
      expect(updated.locationEnabled, isTrue);
      expect(updated.language, 'ms');
    });

    test('equality and hashCode support value comparison', () {
      const prefs1 = UserPreferences();
      const prefs2 = UserPreferences();
      const prefs3 = UserPreferences(language: 'ms');

      expect(prefs1, equals(prefs2));
      expect(prefs1.hashCode, equals(prefs2.hashCode));
      expect(prefs1, isNot(equals(prefs3)));
    });
  });
}
