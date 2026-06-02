// 계정 단위 데이터 분리의 단일 진입점.
// auth 상태가 바뀌면: 스코프 전환 → (로그인 시) 클라우드 pull → provider invalidate.
// 데이터 변경 시: 로그인 상태면 디바운스 push.
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/storage_keys.dart';
import '../storage/local_store.dart';
import '../providers/events_provider.dart';
import '../providers/themes_provider.dart';
import '../providers/extras_provider.dart';
import '../providers/filter_provider.dart';
import '../providers/day_widget_provider.dart';
import '../providers/birthdays_provider.dart';
import '../providers/settings_provider.dart';
import 'events_sync.dart';
import 'user_data_sync.dart';

class AccountScope {
  static String? _pulledFor; // 이미 pull 시도한 스코프
  static Timer? _pushTimer;
  static final Set<String> _dirty = {};

  static String scopeFor(User? user) =>
      user != null ? 'user_${user.id}' : 'guest';

  /// 앱 시작 시 1회: 계정 데이터 변경 → 디바운스 push 훅 설치.
  static void installPushHook() {
    LocalStore.instance.onAccountKeyChanged = (key) {
      if (!LocalStore.instance.scope.startsWith('user_')) return; // 로그인 시에만
      _dirty.add(key);
      _pushTimer?.cancel();
      _pushTimer = Timer(const Duration(milliseconds: 700), _flush);
    };
  }

  static Future<void> _flush() async {
    final keys = Set<String>.from(_dirty);
    _dirty.clear();
    for (final k in keys) {
      if (k == StorageKeys.events) {
        await EventsSync.pushLocal();
      } else if (StorageKeys.userDataKeys.contains(k)) {
        await UserDataSync.pushKey(k);
      }
    }
  }

  /// auth 변화 단일 처리: 스코프 전환 → pull → invalidate.
  static Future<void> applyAuth(Ref ref, User? user) async {
    final newScope = scopeFor(user);
    final changed = LocalStore.instance.scope != newScope;
    LocalStore.instance.setScope(newScope);

    var pulled = false;
    if (user != null && _pulledFor != newScope) {
      _pulledFor = newScope;
      EventsSync.forceReady();
      // pull 성공 시에만 로컬 교체(각 sync가 실패 시 로컬 보존).
      final ev = await EventsSync.pullToLocal();
      final ud = await UserDataSync.pullAll();
      pulled = ev || ud;
    }
    if (user == null) _pulledFor = null; // 로그아웃 → 다음 로그인 시 재pull

    if (changed || pulled) _invalidateAll(ref);
  }

  static void _invalidateAll(Ref ref) {
    ref.invalidate(eventsProvider);
    ref.invalidate(themesProvider);
    ref.invalidate(starredProvider);
    ref.invalidate(memosProvider);
    ref.invalidate(circlesProvider);
    ref.invalidate(filterProvider);
    ref.invalidate(dayTemplatesProvider);
    ref.invalidate(widgetValuesProvider);
    ref.invalidate(birthdaysProvider);
    ref.invalidate(settingsProvider); // 모토(계정) 재읽기
  }
}
