import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/calendar_theme.dart';
import 'supabase_client.dart';

/// 테마 공유 — Supabase `theme_shares` 테이블 사용.
/// 스키마(웹 앱과 동일): code(text, 공유코드), payload(jsonb), created_by(uuid).
class ThemeShareService {
  // 8자리 대문자+숫자 공유 코드 생성
  static String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(8, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  // 테마를 theme_shares 에 업로드 → 공유 코드 반환
  static Future<String> shareTheme(CalendarTheme theme) async {
    final client = sb;
    if (client == null) throw Exception('Supabase에 연결되지 않았습니다');
    final uid = client.auth.currentUser?.id;
    if (uid == null) throw Exception('로그인이 필요합니다');

    final code = _generateCode();
    try {
      await client.from('theme_shares').insert({
        'code': code,
        'payload': {
          'theme':
              theme.copyWith(shareCode: code, shareRole: 'owner').toJson(),
          'v': 1,
        },
        'created_by': uid,
      });
    } catch (e, st) {
      debugPrint('[ThemeShare] shareTheme 실패: ${e.runtimeType} → $e');
      debugPrint('$st');
      rethrow;
    }
    return code;
  }

  // owner가 테마를 수정하면 theme_shares.payload 갱신.
  // RLS상 created_by == auth.uid() 인 행만 update 가능(=owner만).
  static Future<void> updateShare(String code, CalendarTheme theme) async {
    final client = sb;
    if (client == null) throw Exception('Supabase에 연결되지 않았습니다');
    final uid = client.auth.currentUser?.id;
    if (uid == null) throw Exception('로그인이 필요합니다');
    try {
      await client.from('theme_shares').update({
        'payload': {
          'theme':
              theme.copyWith(shareCode: code, shareRole: 'owner').toJson(),
          'v': 1,
        },
      }).eq('code', code).eq('created_by', uid);
    } catch (e, st) {
      debugPrint('[ThemeShare] updateShare 실패: ${e.runtimeType} → $e');
      debugPrint('$st');
      rethrow;
    }
  }

  // 공유 코드로 테마 가져오기
  static Future<CalendarTheme?> fetchByCode(String code) async {
    final client = sb;
    if (client == null) throw Exception('Supabase에 연결되지 않았습니다');

    try {
      final result = await client
          .from('theme_shares')
          .select('payload')
          .eq('code', code.toUpperCase().trim())
          .maybeSingle();

      if (result == null) return null;
      final payload = result['payload'];
      // payload = { theme: {...}, v: 1 } (웹 호환). 혹시 payload 자체가 테마면 폴백.
      final themeJson = (payload is Map && payload['theme'] is Map)
          ? Map<String, dynamic>.from(payload['theme'] as Map)
          : Map<String, dynamic>.from(payload as Map);
      return CalendarTheme.fromJson(themeJson);
    } catch (e, st) {
      debugPrint('[ThemeShare] fetchByCode 실패: ${e.runtimeType} → $e');
      debugPrint('$st');
      rethrow;
    }
  }
}
