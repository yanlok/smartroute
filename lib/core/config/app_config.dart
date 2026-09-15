class AppConfig {
  final String supabaseUrl;
  final String supabasePublishableKey;
  final String googleWebClientId;

  const AppConfig({
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    this.googleWebClientId = '',
  });

  const AppConfig.fromEnvironment()
    : supabaseUrl = const String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: 'https://lomjlfmikzzdmctyngjv.supabase.co',
      ),
      supabasePublishableKey = const String.fromEnvironment(
        'SUPABASE_PUBLISHABLE_KEY',
        defaultValue: 'sb_publishable_dO97tA7VfN9G6NPPhmtA8w_VhJa7JkQ',
      ),
      googleWebClientId = const String.fromEnvironment(
        'GOOGLE_WEB_CLIENT_ID',
        defaultValue: '',
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
