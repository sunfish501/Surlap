import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/calendar_theme.dart';
import '../models/event_item.dart';
import '../models/shared_theme_payload.dart';
import 'supabase_client.dart';

/// 테마 공유 — Supabase `theme_shares` 테이블 사용.
/// 스키마(웹 앱과 동일): code(text, 공유코드), payload(jsonb), created_by(uuid).
class ThemeShareService {
  // 딥링크 — https 앱링크(주) + 커스텀 스킴(보조)
  // GitHub Pages 레포 이름이 서브패스로 들어감(`/Surlap/`).
  static const scheme = 'surlap';
  static const httpsDomain = 'kev208dev.github.io';
  static const httpsBasePath = '/Surlap';
  static String linkForCode(String code) => '$scheme://theme/$code';
  static String httpsLinkForCode(String code) =>
      'https://$httpsDomain$httpsBasePath/theme/$code';

  // 8자리 대문자+숫자 공유 코드 생성
  static String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(8, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  // payload v2: 테마 메타 + 그 테마 소속 일정 동봉.
  static Map<String, dynamic> _payloadV2(
          String code,
          CalendarTheme theme,
          Map<String, List<EventItem>> events) =>
      {
        'theme': theme.copyWith(shareCode: code, shareRole: 'owner').toJson(),
        'events': eventsToPayloadJson(events),
        'v': 2,
      };

  // 테마 + 일정을 theme_shares 에 업로드 → 공유 코드 반환
  static Future<String> shareTheme(
      CalendarTheme theme, Map<String, List<EventItem>> events) async {
    final client = sb;
    if (client == null) throw Exception('Supabase에 연결되지 않았습니다');
    final uid = client.auth.currentUser?.id;
    if (uid == null) throw Exception('로그인이 필요합니다');

    final code = _generateCode();
    try {
      await client.from('theme_shares').insert({
        'code': code,
        'payload': _payloadV2(code, theme, events),
        'created_by': uid,
      });
    } catch (e, st) {
      debugPrint('[ThemeShare] shareTheme 실패: ${e.runtimeType} → $e');
      debugPrint('$st');
      rethrow;
    }
    return code;
  }

  // owner가 테마/일정을 수정하면 theme_shares.payload 갱신.
  // RLS상 created_by == auth.uid() 인 행만 update 가능(=owner만).
  static Future<void> updateShare(String code, CalendarTheme theme,
      Map<String, List<EventItem>> events) async {
    final client = sb;
    if (client == null) throw Exception('Supabase에 연결되지 않았습니다');
    final uid = client.auth.currentUser?.id;
    if (uid == null) throw Exception('로그인이 필요합니다');
    try {
      await client.from('theme_shares').update({
        'payload': _payloadV2(code, theme, events),
      }).eq('code', code).eq('created_by', uid);
    } catch (e, st) {
      debugPrint('[ThemeShare] updateShare 실패: ${e.runtimeType} → $e');
      debugPrint('$st');
      rethrow;
    }
  }

  // 공유 코드로 payload(테마 + 일정) 가져오기. v1(테마만)도 폴백 파싱.
  static Future<SharedThemePayload?> fetchPayloadByCode(String code) async {
    final client = sb;
    if (client == null) throw Exception('Supabase에 연결되지 않았습니다');
    try {
      final result = await client
          .from('theme_shares')
          .select('payload')
          .eq('code', code.toUpperCase().trim())
          .maybeSingle();
      if (result == null) return null;
      return SharedThemePayload.fromPayload(result['payload']);
    } catch (e, st) {
      debugPrint('[ThemeShare] fetchPayloadByCode 실패: ${e.runtimeType} → $e');
      debugPrint('$st');
      rethrow;
    }
  }

  // 공유 코드로 테마만 가져오기(기존 호출 호환).
  static Future<CalendarTheme?> fetchByCode(String code) async =>
      (await fetchPayloadByCode(code))?.theme;
}
