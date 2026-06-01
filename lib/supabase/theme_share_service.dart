import 'dart:convert';
import 'dart:math';
import '../models/calendar_theme.dart';
import 'supabase_client.dart';

class ThemeShareService {
  // 8자리 대문자+숫자 공유 코드 생성
  static String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(8, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  // 테마를 Supabase shared_themes 테이블에 업로드 → 공유 코드 반환
  static Future<String> shareTheme(CalendarTheme theme) async {
    final client = sb;
    if (client == null) throw Exception('Supabase에 연결되지 않았습니다');
    final uid = client.auth.currentUser?.id;
    if (uid == null) throw Exception('로그인이 필요합니다');

    final code = _generateCode();
    await client.from('shared_themes').upsert({
      'share_code': code,
      'theme_json': jsonEncode(theme.copyWith(shareCode: code, shareRole: 'owner').toJson()),
      'owner_id': uid,
    });
    return code;
  }

  // 공유 코드로 테마 가져오기
  static Future<CalendarTheme?> fetchByCode(String code) async {
    final client = sb;
    if (client == null) throw Exception('Supabase에 연결되지 않았습니다');

    final result = await client
        .from('shared_themes')
        .select('theme_json')
        .eq('share_code', code.toUpperCase().trim())
        .maybeSingle();

    if (result == null) return null;
    final json = jsonDecode(result['theme_json'] as String) as Map<String, dynamic>;
    return CalendarTheme.fromJson(json);
  }
}
