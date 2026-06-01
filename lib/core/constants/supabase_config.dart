// dart-define으로 주입. 빌드 시 --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
// 값이 없으면 빈 문자열 → 앱 시작 시 assert로 잡힘.
const supabaseUrl     = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
