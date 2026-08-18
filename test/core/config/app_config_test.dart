import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test(
      'valid explicit configuration reports configured and validates successfully',
      () {
        const config = AppConfig(
          supabaseUrl: 'https://example.supabase.co',
          supabasePublishableKey: 'sb-publishable-key-12345',
        );

        expect(config.isSupabaseConfigured, isTrue);
        expect(config.supabaseUrl, 'https://example.supabase.co');
        expect(config.supabasePublishableKey, 'sb-publishable-key-12345');
        expect(() => config.validateSupabase(), returnsNormally);
      },
    );

    test('missing URL throws StateError mentioning SUPABASE_URL', () {
      const config = AppConfig(
        supabaseUrl: '',
        supabasePublishableKey: 'sb-publishable-key-12345',
      );

      expect(config.isSupabaseConfigured, isFalse);
      expect(
        () => config.validateSupabase(),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('SUPABASE_URL'),
          ),
        ),
      );
    });

    test(
      'missing publishable key throws StateError mentioning SUPABASE_PUBLISHABLE_KEY',
      () {
        const config = AppConfig(
          supabaseUrl: 'https://example.supabase.co',
          supabasePublishableKey: '',
        );

        expect(config.isSupabaseConfigured, isFalse);
        expect(
          () => config.validateSupabase(),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('SUPABASE_PUBLISHABLE_KEY'),
            ),
          ),
        );
      },
    );

    test('both missing throw StateError mentioning both variables', () {
      const config = AppConfig(supabaseUrl: '', supabasePublishableKey: '');

      expect(config.isSupabaseConfigured, isFalse);
      expect(
        () => config.validateSupabase(),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('SUPABASE_URL'),
              contains('SUPABASE_PUBLISHABLE_KEY'),
            ),
          ),
        ),
      );
    });

    test(
      'validation exception does not leak actual key values in error message',
      () {
        const sensitiveKey = 'secret-or-anon-key-xyz-987';
        const config = AppConfig(
          supabaseUrl: '',
          supabasePublishableKey: sensitiveKey,
        );

        try {
          config.validateSupabase();
          fail('Should have thrown StateError');
        } on StateError catch (e) {
          expect(e.message.contains(sensitiveKey), isFalse);
        }
      },
    );
  });
}
