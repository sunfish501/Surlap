// Supabase 프로젝트 URL / publishable(anon) 키.
// 빌드 시 --dart-define 으로 덮어쓸 수 있고, 없으면 아래 기본값을 사용한다.
//
// 여기 들어가는 키는 "publishable(anon)" 키로, 클라이언트에 노출되도록 설계된
// 공개 키다(데이터 보호는 Supabase의 RLS가 담당). service_role 키는 절대 금지.
const supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://dtmwnmeobutohjdpwhka.supabase.co',
);
const supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue:
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR0bXdubWVvYnV0b2hqZHB3aGthIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA0NTI0MDksImV4cCI6MjA5NjAyODQwOX0.zoyB6HUYYV16CRhaGZX7MI8wv42liJtk1uNEp8kUQLQ',
);
