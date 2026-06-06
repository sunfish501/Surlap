import '../models/calendar_theme.dart';
import '../models/event_item.dart';

/// theme_shares.payload 파싱 결과.
/// v2: { theme, events: { "YYYY-MM-DD": [item...] }, v:2 }
/// v1: { theme, v:1 }  (events 없음 — 폴백)
class SharedThemePayload {
  final CalendarTheme theme;
  final Map<String, List<EventItem>> events;
  const SharedThemePayload({required this.theme, required this.events});

  factory SharedThemePayload.fromPayload(dynamic payload) {
    // payload 자체가 테마(아주 옛 형식)일 수도 있어 폴백 처리.
    final map = payload is Map
        ? Map<String, dynamic>.from(payload)
        : <String, dynamic>{};
    final themeJson = (map['theme'] is Map)
        ? Map<String, dynamic>.from(map['theme'] as Map)
        : map;
    final theme = CalendarTheme.fromJson(themeJson);

    final events = <String, List<EventItem>>{};
    final rawEvents = map['events'];
    if (rawEvents is Map) {
      rawEvents.forEach((k, v) {
        if (v is List) {
          events['$k'] = v.map((e) => EventItem.fromRaw(e)).toList();
        }
      });
    }
    return SharedThemePayload(theme: theme, events: events);
  }

  /// 전체 이벤트 개수(알림 문구·변경 비교용).
  int get eventCount =>
      events.values.fold(0, (sum, list) => sum + list.length);
}

/// 특정 테마 id 에 속한 이벤트만 추린 날짜별 맵(공유 payload용).
Map<String, List<EventItem>> eventsForTheme(
    Map<String, List<EventItem>> all, String themeId) {
  final out = <String, List<EventItem>>{};
  all.forEach((dateKey, list) {
    final filtered = list
        .where((e) => !e.isTimetable && e.themeIds.contains(themeId))
        .toList();
    if (filtered.isNotEmpty) out[dateKey] = filtered;
  });
  return out;
}

/// 이벤트 맵 → payload jsonb 직렬화.
Map<String, dynamic> eventsToPayloadJson(Map<String, List<EventItem>> events) =>
    {for (final e in events.entries) e.key: e.value.map((i) => i.toJson()).toList()};
