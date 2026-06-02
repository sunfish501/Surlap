import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/supabase_config.dart';

Future<void> initSupabase() async {
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    debugPrint('[Supabase] URL/anon 키가 비어 있어 초기화를 건너뜁니다 '
        '(로그인·클라우드 동기화 비활성).');
    return;
  }
  try {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    debugPrint('[Supabase] 초기화 완료 → $supabaseUrl');
  } catch (e) {
    debugPrint('[Supabase] 초기화 실패 (키/네트워크 확인): $e');
  }
}

SupabaseClient? get sb {
  if (supabaseUrl.isEmpty) { return null; }
  try {
    return Supabase.instance.client;
  } catch (e) {
    debugPrint('[Supabase] client 접근 실패 — 아직 초기화되지 않음: $e');
    return null;
  }
}
