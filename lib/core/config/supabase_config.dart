/// Supabase project configuration.
/// Override via --dart-define: SUPABASE_URL=... SUPABASE_ANON_KEY=...
/// Defaults point to the LinkStage Supabase project (LINKSTAGE).
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://rfpltplxqwwobcgjscbd.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
