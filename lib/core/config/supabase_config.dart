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
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJmcGx0cGx4cXd3b2JjZ2pzY2JkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMzMjIwODUsImV4cCI6MjA4ODg5ODA4NX0.7QZsowpCOtUoXWdeWppzl142vZC_NLdl506_KXeXBQM',
  );

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
