import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/storage_keys.dart';
import '../core/utils/date_utils.dart' as du;
import '../models/event_item.dart';
import '../models/sports.dart';
import '../sports/sports_adapter.dart';
import '../storage/local_store.dart';
import '../utils/sports_notifications.dart';

// ─── 구독 목록 ──────────────────────────────────────────────────────────
class SportsSubscriptionsNotifier extends Notifier<List<SportSubscription>> {
  @override
  List<SportSubscription> build() {
    final raw = LocalStore.instance.getString(StorageKeys.sportsSubscriptions);
    return raw != null ? SportSubscription.listFromJson(raw) : [];
  }

  bool isSubscribed(String id) => state.any((s) => s.id == id);

  Future<void> subscribe(SportSubscription sub) async {
    if (isSubscribed(sub.id)) return;
    state = [...state, sub];
    await _save();
    await ref.read(sportsEventsProvider.notifier).refreshOne(sub);
  }

  Future<void> unsubscribe(String id) async {
    state = state.where((s) => s.id != id).toList();
    await _save();
    await ref.read(sportsEventsProvider.notifier).dropSubscription(id);
  }

  Future<void> toggleEnabled(String id) async {
    state = [
      for (final s in state) s.id == id ? s.copyWith(enabled: !s.enabled) : s
    ];
    await _save();
    await ref.read(sportsEventsProvider.notifier).reschedule();
  }

  Future<void> setReminder(String id, int minutes) async {
    state = [
      for (final s in state)
        s.id == id ? s.copyWith(reminderMinutes: minutes) : s
    ];
    await _save();
    await ref.read(sportsEventsProvider.notifier).reschedule();
  }

  /// 구독 표시 색 변경 — 저장만 하면 sportsEventsByDateProvider가 다시 계산돼
  /// 달력에 즉시 반영(경기 재요청 불필요).
  Future<void> setColor(String id, int color) async {
    state = [
      for (final s in state) s.id == id ? s.copyWith(color: color) : s
    ];
    await _save();
  }

  Future<void> _save() async {
    await LocalStore.instance.setString(
        StorageKeys.sportsSubscriptions, SportSubscription.listToJson(state));
  }
}

final sportsSubscriptionsProvider =
    NotifierProvider<SportsSubscriptionsNotifier, List<SportSubscription>>(
        SportsSubscriptionsNotifier.new);

// ─── 경기 일정 캐시(구독별) ─────────────────────────────────────────────
class SportsEventsNotifier extends Notifier<Map<String, List<SportsEvent>>> {
  bool _refreshing = false;

  @override
  Map<String, List<SportsEvent>> build() {
    final loaded = _load();
    // 앱 진입 시 백그라운드로 한 번 갱신.
    Future.microtask(refreshAll);
    return loaded;
  }

  Map<String, List<SportsEvent>> _load() {
    final raw = LocalStore.instance.getString(StorageKeys.sportsEventsCache);
    if (raw == null) return {};
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return j.map((subId, list) => MapEntry(
            subId,
            (list as List)
                .whereType<Map<String, dynamic>>()
                .map(SportsEvent.fromJson)
                .toList(),
          ));
    } catch (_) {
      return {};
    }
  }

  Future<void> _save() async {
    final j = state.map((k, v) => MapEntry(k, v.map((e) => e.toJson()).toList()));
    await LocalStore.instance
        .setString(StorageKeys.sportsEventsCache, jsonEncode(j));
  }

  DateTime get _from => DateTime.now().subtract(const Duration(days: 3));
  DateTime get _to => DateTime.now().add(const Duration(days: 60));

  /// 전체 구독 일정 갱신(앱 진입/수동).
  Future<void> refreshAll() async {
    if (_refreshing) return;
    final subs =
        ref.read(sportsSubscriptionsProvider).where((s) => s.enabled).toList();
    if (subs.isEmpty) return;
    _refreshing = true;
    final next = Map<String, List<SportsEvent>>.from(state);
    for (final sub in subs) {
      try {
        final games = await adapterForSport(sub.kind)
            .fetchGames(sub: sub, from: _from, to: _to);
        if (games.isNotEmpty) next[sub.id] = games;
      } catch (e) {
        debugPrint('[Sports] refresh ${sub.id} 실패: $e');
      }
    }
    state = next;
    await _save();
    _refreshing = false;
    await reschedule();
  }

  Future<void> refreshOne(SportSubscription sub) async {
    try {
      final games = await adapterForSport(sub.kind)
          .fetchGames(sub: sub, from: _from, to: _to);
      state = {...state, sub.id: games};
      await _save();
      await reschedule();
    } catch (e) {
      debugPrint('[Sports] refreshOne ${sub.id} 실패: $e');
    }
  }

  Future<void> dropSubscription(String id) async {
    final next = Map<String, List<SportsEvent>>.from(state)..remove(id);
    state = next;
    await _save();
    await reschedule();
  }

  /// 알림 재스케줄(구독·일정 변동 시).
  Future<void> reschedule() async {
    await SportsNotifications.scheduleAll(
        ref.read(sportsSubscriptionsProvider), state);
  }
}

final sportsEventsProvider =
    NotifierProvider<SportsEventsNotifier, Map<String, List<SportsEvent>>>(
        SportsEventsNotifier.new);

// ─── 달력 머지용: 날짜키 → 스포츠 EventItem ────────────────────────────
// 각 항목은 th=구독id, sport=true, 구독 색/이모지를 들고 있어
// 기존 필터(filterProvider)와 색/칩 로직에 그대로 얹힌다.
final sportsEventsByDateProvider = Provider<Map<String, List<EventItem>>>((ref) {
  final subs = ref.watch(sportsSubscriptionsProvider);
  final byId = ref.watch(sportsEventsProvider);
  final out = <String, List<EventItem>>{};
  for (final sub in subs) {
    if (!sub.enabled) continue;
    for (final ev in byId[sub.id] ?? const <SportsEvent>[]) {
      final local = ev.startAt.toLocal();
      final key = du.toDateKey(local);
      out.putIfAbsent(key, () => []).add(EventItem(
            t: ev.title,
            tm: '${du.pad(local.hour)}:${du.pad(local.minute)}',
            th: sub.id,
            sport: true,
            sportColor: sub.color,
            sportEmoji: sub.emoji,
          ));
    }
  }
  return out;
});
