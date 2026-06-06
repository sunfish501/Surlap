import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/calendar_theme.dart';
import '../models/shared_theme_payload.dart';
import '../supabase/supabase_client.dart';
import '../supabase/theme_share_service.dart';
import '../utils/theme_share_notifications.dart';
import 'events_provider.dart';
import 'themes_provider.dart';
import 'shared_theme_events_provider.dart';

/// 공유 테마 실시간 동기화 오케스트레이터.
///  - owner: 일정/테마 변경 시 updateShare 자동 호출(디바운스).
///  - subscriber: theme_shares 를 code 로 Realtime 구독 → 일정 머지 + 알림.
/// 앱 시작 시 MainShell 에서 watch 해 살아있게 유지한다.
class ThemeSharing {
  final Ref ref;
  ThemeSharing(this.ref);

  static const _debounce = Duration(seconds: 3);
  final Map<String, Timer> _ownerTimers = {}; // shareCode -> debounce
  final Map<String, RealtimeChannel> _channels = {}; // shareCode -> channel
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;
    // owner: 이벤트 변경 → 소유 공유테마 갱신 예약.
    ref.listen(eventsProvider, (_, _) => _scheduleOwnerUploads());
    // 테마 변경(메타 수정/구독·해제) → owner 갱신 + 구독 채널 동기화.
    ref.listen(themesProvider, (_, _) {
      _scheduleOwnerUploads();
      _syncSubscriberChannels();
    });
    Future.microtask(_syncSubscriberChannels);
  }

  void dispose() {
    for (final t in _ownerTimers.values) {
      t.cancel();
    }
    final client = sb;
    for (final c in _channels.values) {
      client?.removeChannel(c);
    }
    _ownerTimers.clear();
    _channels.clear();
  }

  // ── owner 자동 업로드(디바운스) ──────────────────────────────────────
  void _scheduleOwnerUploads() {
    final owned = ref
        .read(themesProvider)
        .where((t) => t.shareRole == 'owner' && t.shareCode != null);
    for (final t in owned) {
      final code = t.shareCode!;
      _ownerTimers[code]?.cancel();
      _ownerTimers[code] = Timer(_debounce, () => _uploadOwned(t.id, code));
    }
  }

  Future<void> _uploadOwned(String themeId, String code) async {
    final theme = ref.read(themesProvider.notifier).byId(themeId);
    if (theme == null) return;
    final events = eventsForTheme(ref.read(eventsProvider), themeId);
    try {
      await ThemeShareService.updateShare(code, theme, events);
      debugPrint('[ThemeSharing] owner 업로드: $code (${events.length}일)');
    } catch (e) {
      debugPrint('[ThemeSharing] owner 업로드 실패($code): $e');
    }
  }

  // ── subscriber Realtime ──────────────────────────────────────────────
  void _syncSubscriberChannels() {
    final client = sb;
    if (client == null) return;
    final subs = ref
        .read(themesProvider)
        .where((t) => t.shareRole == 'subscriber' && t.shareCode != null)
        .toList();
    final wanted = {for (final t in subs) t.shareCode!};

    // 해제된 구독 → 채널 닫기.
    for (final code in _channels.keys.toList()) {
      if (!wanted.contains(code)) {
        client.removeChannel(_channels.remove(code)!);
      }
    }
    // 새 구독 → 초기 fetch + 채널 연결.
    for (final t in subs) {
      final code = t.shareCode!;
      if (_channels.containsKey(code)) continue;
      _initialFetch(t.id, code);
      _subscribe(t.id, code);
    }
    // 더 이상 구독 안 하는 테마의 캐시 제거.
    final subThemeIds = {for (final t in subs) t.id};
    for (final themeId in ref.read(sharedThemeEventsProvider).keys.toList()) {
      if (!subThemeIds.contains(themeId)) {
        ref.read(sharedThemeEventsProvider.notifier).removeTheme(themeId);
      }
    }
  }

  Future<void> _initialFetch(String themeId, String code) async {
    try {
      final payload = await ThemeShareService.fetchPayloadByCode(code);
      if (payload == null) return;
      await ref
          .read(sharedThemeEventsProvider.notifier)
          .setForTheme(themeId, payload.events);
    } catch (e) {
      debugPrint('[ThemeSharing] 초기 fetch 실패($code): $e');
    }
  }

  void _subscribe(String themeId, String code) {
    final client = sb;
    if (client == null) return;
    final channel = client.channel('theme_shares:$code');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'theme_shares',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'code',
        value: code,
      ),
      callback: (payload) => _onRemoteChange(themeId, payload.newRecord),
    ).subscribe();
    _channels[code] = channel;
  }

  Future<void> _onRemoteChange(
      String themeId, Map<String, dynamic> newRecord) async {
    try {
      final parsed = SharedThemePayload.fromPayload(newRecord['payload']);
      final prev = ref
              .read(sharedThemeEventsProvider)[themeId]
              ?.values
              .fold<int>(0, (s, l) => s + l.length) ??
          0;
      final next = parsed.eventCount;
      // 깜빡임 없이 갱신(provider 상태만 교체 → 관련 뷰만 리빌드).
      await ref
          .read(sharedThemeEventsProvider.notifier)
          .setForTheme(themeId, parsed.events);
      final kind = next > prev
          ? ShareChangeKind.added
          : next < prev
              ? ShareChangeKind.removed
              : ShareChangeKind.updated;
      await ThemeShareNotifications.notify(parsed.theme.name, kind);
    } catch (e) {
      debugPrint('[ThemeSharing] 원격 변경 처리 실패: $e');
    }
  }

  /// 외부에서 즉시 업로드(첫 공유 직후 등).
  Future<void> uploadNow(CalendarTheme theme) async {
    if (theme.shareCode == null) return;
    await _uploadOwned(theme.id, theme.shareCode!);
  }
}

final themeSharingProvider = Provider<ThemeSharing>((ref) {
  final s = ThemeSharing(ref);
  s.start();
  ref.onDispose(s.dispose);
  return s;
});
