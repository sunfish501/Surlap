import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/storage_keys.dart';
import '../storage/local_store.dart';
import '../utils/birthday_notifications.dart';
import 'birthdays_provider.dart';

class BirthdayNotifySettings {
  final bool enabled;
  final int daysBefore;
  const BirthdayNotifySettings({this.enabled = false, this.daysBefore = 1});

  BirthdayNotifySettings copyWith({bool? enabled, int? daysBefore}) =>
      BirthdayNotifySettings(
        enabled: enabled ?? this.enabled,
        daysBefore: daysBefore ?? this.daysBefore,
      );
}

class BirthdayNotifyNotifier extends Notifier<BirthdayNotifySettings> {
  @override
  BirthdayNotifySettings build() {
    final s = LocalStore.instance;
    return BirthdayNotifySettings(
      enabled: s.getBool(StorageKeys.birthdayNotifyEnabled) ?? false,
      daysBefore: s.getInt(StorageKeys.birthdayNotifyDaysBefore) ?? 1,
    );
  }

  Future<void> setEnabled(bool v) async {
    if (v) {
      // 켤 때 권한 요청.
      await BirthdayNotifications.requestPermission();
    }
    state = state.copyWith(enabled: v);
    await LocalStore.instance.setBool(StorageKeys.birthdayNotifyEnabled, v);
    await reschedule();
  }

  Future<void> setDaysBefore(int d) async {
    state = state.copyWith(daysBefore: d);
    await LocalStore.instance.setInt(StorageKeys.birthdayNotifyDaysBefore, d);
    await reschedule();
  }

  /// 생일 추가/삭제 등으로 목록이 바뀌면 호출 → 전체 재스케줄.
  Future<void> reschedule() async {
    await BirthdayNotifications.scheduleAll(
      ref.read(birthdaysProvider),
      enabled: state.enabled,
      daysBefore: state.daysBefore,
    );
  }
}

final birthdayNotifyProvider =
    NotifierProvider<BirthdayNotifyNotifier, BirthdayNotifySettings>(
        BirthdayNotifyNotifier.new);
