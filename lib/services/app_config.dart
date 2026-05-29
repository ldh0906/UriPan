const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
);

bool get hasSupabaseConfig =>
    supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
