import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/date_utils.dart' as du;
import '../core/utils/recurrence.dart';
import '../models/event_item.dart';
import 'events_provider.dart';

/// 일반 일정 중 `rr`(반복 규칙)이 설정된 앵커들을 ±1년 윈도우 안에서 펼쳐서
/// 날짜별 가상 occurrence 맵으로 반환한다. 앵커 본인은 포함하지 않음 — 앵커는
/// 이미 `eventsProvider[anchorDate]`에 존재하기 때문.
///
/// 사용:
///   final extra = ref.watch(recurringEventsByDateProvider)[dateKey] ?? const [];
///   final all = [...(events[dateKey] ?? []), ...extra];
final recurringEventsByDateProvider =
    Provider<Map<String, List<EventItem>>>((ref) {
  final events = ref.watch(eventsProvider);
  final today = DateTime.now();
  final winStart = DateTime(today.year - 1, today.month, today.day);
  final winEnd = DateTime(today.year + 1, today.month, today.day);

  final out = <String, List<EventItem>>{};
  events.forEach((anchorKey, list) {
    DateTime anchor;
    try {
      anchor = du.fromDateKey(anchorKey);
    } catch (_) {
      return;
    }
    for (final e in list) {
      final rr = Recurrence.fromJson(e.rr);
      if (rr == null || e.isTimetable) continue;
      // 윈도우의 each day 검사 — 단순 그러나 충분히 빠름(<=730일).
      var cursor = winStart;
      while (!cursor.isAfter(winEnd)) {
        if (!cursor.isAtSameMomentAs(anchor) && occursOn(rr, anchor, cursor)) {
          final k = du.toDateKey(cursor);
          (out[k] ??= <EventItem>[]).add(e);
        }
        cursor = cursor.add(const Duration(days: 1));
      }
    }
  });
  return out;
});
