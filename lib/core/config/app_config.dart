class AppConfig {
  final String supabaseUrl;
  final String supabasePublishableKey;

  const AppConfig({
    required this.supabaseUrl,
    required this.supabasePublishableKey,
  });

  const AppConfig.fromEnvironment()
    : supabaseUrl = const String.fromEnvironment('SUPABASE_URL'),
      supabasePublishableKey = const String.fromEnvironment(
        'SUPABASE_PUBLISHABLE_KEY',
      );

  bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

  void validateSupabase() {
    if (supabaseUrl.isEmpty && supabasePublishableKey.isEmpty) {
      throw StateError(
        'Missing required Supabase environment variables: SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY',
      );
    }
    if (supabaseUrl.isEmpty) {
      throw StateError(
        'Missing required Supabase environment variable: SUPABASE_URL',
      );
    }
    if (supabasePublishableKey.isEmpty) {
      throw StateError(
        'Missing required Supabase environment variable: SUPABASE_PUBLISHABLE_KEY',
      );
    }
  }
}
