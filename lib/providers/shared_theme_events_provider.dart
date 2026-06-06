import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/storage_keys.dart';
import '../models/event_item.dart';
import '../storage/local_store.dart';

/// 구독 중인 공유 테마에서 받은(읽기 전용) 일정 캐시.
/// 구조: { themeId: { "YYYY-MM-DD": [EventItem...] } }
/// 사용자의 eventsProvider 와 분리 → 구독자가 편집 불가, 본인 클라우드에도 안 섞임.
class SharedThemeEventsNotifier
    extends Notifier<Map<String, Map<String, List<EventItem>>>> {
  @override
  Map<String, Map<String, List<EventItem>>> build() => _load();

  Map<String, Map<String, List<EventItem>>> _load() {
    final raw = LocalStore.instance.getString(StorageKeys.sharedThemeEvents);
    if (raw == null) return {};
    try {
      final outer = jsonDecode(raw) as Map<String, dynamic>;
      return outer.map((themeId, byDate) => MapEntry(
            themeId,
            (byDate as Map<String, dynamic>).map((date, list) => MapEntry(
                  date,
                  (list as List).map((e) => EventItem.fromRaw(e)).toList(),
                )),
          ));
    } catch (_) {
      return {};
    }
  }

  Future<void> _save() async {
    final j = state.map((themeId, byDate) => MapEntry(
          themeId,
          byDate.map(
              (date, list) => MapEntry(date, list.map((e) => e.toJson()).toList())),
        ));
    await LocalStore.instance
        .setString(StorageKeys.sharedThemeEvents, jsonEncode(j));
  }

  /// 한 테마의 일정 전체 교체(Realtime 수신/초기 fetch).
  Future<void> setForTheme(
      String themeId, Map<String, List<EventItem>> events) async {
    state = {...state, themeId: events};
    await _save();
  }

  Future<void> removeTheme(String themeId) async {
    if (!state.containsKey(themeId)) return;
    final next = Map<String, Map<String, List<EventItem>>>.from(state)
      ..remove(themeId);
    state = next;
    await _save();
  }
}

final sharedThemeEventsProvider = NotifierProvider<SharedThemeEventsNotifier,
    Map<String, Map<String, List<EventItem>>>>(SharedThemeEventsNotifier.new);

/// 달력 머지용: 날짜키 → 구독 테마 일정(읽기 전용).
/// 각 EventItem 은 th=themeId 를 그대로 가져 테마 색/필터칩에 얹힌다.
final sharedThemeEventsByDateProvider =
    Provider<Map<String, List<EventItem>>>((ref) {
  final byTheme = ref.watch(sharedThemeEventsProvider);
  final out = <String, List<EventItem>>{};
  for (final entry in byTheme.entries) {
    final themeId = entry.key;
    entry.value.forEach((dateKey, list) {
      // th 를 구독 테마 id로 통일 → 구독자 측 테마 색/필터칩과 정확히 매칭.
      (out[dateKey] ??= []).addAll(list.map((e) => e.copyWith(th: themeId)));
    });
  }
  return out;
});
