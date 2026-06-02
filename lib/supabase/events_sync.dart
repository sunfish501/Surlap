// events.js 대응 — Supabase events 테이블과 동기화.
import '../core/constants/storage_keys.dart';
import '../models/event_item.dart';
import '../storage/local_store.dart';
import 'supabase_client.dart';

class EventsSync {
  static bool _pullAttempted = false;

  /// 현재 계정의 events 전체를 클라우드에서 받아 현재 스코프 로컬 캐시에 교체.
  /// 성공 시 true. 실패 시 로컬을 건드리지 않는다(증발 방지).
  static Future<bool> pullToLocal() async {
    final client = sb;
    if (client == null) return false;
    final user = client.auth.currentUser;
    if (user == null) return false;
    try {
      final res = await client
          .from('events')
          .select('date,title,is_timetable,theme_id,position')
          .eq('user_id', user.id)
          .order('date')
          .order('position');
      final byDate = <String, List<EventItem>>{};
      for (final row in res as List) {
        final r = row as Map<String, dynamic>;
        final date = r['date'] as String;
        (byDate[date] ??= []).add(rowToItem(r));
      }
      await LocalStore.instance
          .setStringQuiet(StorageKeys.events, eventsToJson(byDate));
      _pullAttempted = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  static Map<String, dynamic> itemToRow(String date, EventItem item, int pos, String userId) => {
    'date': date,
    'title': item.t,
    'is_timetable': item.isTimetable,
    'theme_id': item.themeIds.isEmpty ? null : item.themeIds.first,
    'position': pos,
    'user_id': userId,
  };

  static EventItem rowToItem(Map<String, dynamic> row) {
    final isTT = row['is_timetable'] == true;
    final themeId = row['theme_id'] as String?;
    if (isTT || themeId != null) {
      return EventItem(t: row['title'] as String, tt: isTT, th: themeId);
    }
    return EventItem(t: row['title'] as String);
  }

  static Future<Map<String, List<EventItem>>?> pull(
      Map<String, List<EventItem>> local) async {
    final client = sb;
    if (client == null) { return null; }
    final user = client.auth.currentUser;
    if (user == null) { _pullAttempted = true; return null; }

    try {
      final res = await client
          .from('events')
          .select('date,title,is_timetable,theme_id,position')
          .order('date')
          .order('position');

      final byDate = <String, List<EventItem>>{};
      for (final row in res as List) {
        final r = row as Map<String, dynamic>;
        final date = r['date'] as String;
        (byDate[date] ??= []).add(rowToItem(r));
      }

      bool changed = false;
      for (final k in byDate.keys) {
        if ((local[k] ?? []).isEmpty) {
          local[k] = byDate[k]!;
          changed = true;
        }
      }
      _pullAttempted = true;
      return changed ? local : null;
    } catch (_) {
      _pullAttempted = true;
      return null;
    }
  }

  static Future<bool> pushDate(
      String date, List<EventItem> items) async {
    final client = sb;
    if (client == null || !_pullAttempted) { return false; }
    final user = client.auth.currentUser;
    if (user == null) { return false; }

    try {
      await client.from('events').delete()
          .eq('date', date).eq('user_id', user.id);
      if (items.isNotEmpty) {
        final rows = items.asMap().entries
            .map((e) => itemToRow(date, e.value, e.key, user.id))
            .toList();
        await client.from('events').insert(rows);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> pushAll(Map<String, List<EventItem>> events) async {
    if (!_pullAttempted) { return; }
    for (final entry in events.entries) {
      if (entry.key.startsWith('__')) { continue; }
      await pushDate(entry.key, entry.value);
    }
  }

  /// 현재 스코프 로컬 events 를 통째로 클라우드에 push(디바운스 훅에서 호출).
  static Future<void> pushLocal() async {
    final raw = LocalStore.instance.getString(StorageKeys.events);
    await pushAll(raw != null ? eventsFromJson(raw) : {});
  }

  static void forceReady() => _pullAttempted = true;
}
