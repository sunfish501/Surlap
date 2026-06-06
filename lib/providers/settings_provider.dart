import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/storage_keys.dart';
import '../storage/local_store.dart';

class AppSettings {
  final String motto;
  final int weekStartDow;  // 0=일, 1=월, 6=토
  final bool showPast;
  final bool continuousView;
  final bool notifyEnabled;
  final bool showTimetable; // 주간·일간 뷰에 시간표 수업 표시 여부

  const AppSettings({
    this.motto = '',
    this.weekStartDow = 1,
    this.showPast = true,
    this.continuousView = false,
    this.notifyEnabled = true,
    this.showTimetable = true,
  });

  AppSettings copyWith({
    String? motto, int? weekStartDow, bool? showPast,
    bool? continuousView, bool? notifyEnabled, bool? showTimetable,
  }) => AppSettings(
    motto: motto ?? this.motto,
    weekStartDow: weekStartDow ?? this.weekStartDow,
    showPast: showPast ?? this.showPast,
    continuousView: continuousView ?? this.continuousView,
    notifyEnabled: notifyEnabled ?? this.notifyEnabled,
    showTimetable: showTimetable ?? this.showTimetable,
  );
}

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final s = LocalStore.instance;
    return AppSettings(
      motto: s.getString(StorageKeys.motto) ?? '',
      weekStartDow: s.getInt(StorageKeys.weekStart) ?? 1,
      showPast: s.getString(StorageKeys.colorPreset) != null
          ? (s.getBool('calendar-show-past-v1') ?? true)
          : true,
      continuousView: s.getBool(StorageKeys.continuousView) ?? false,
      notifyEnabled: s.getBool(StorageKeys.notifyEnabled) ?? true,
      showTimetable: s.getBool(StorageKeys.showTimetable) ?? true,
    );
  }

  Future<void> setMotto(String v) async {
    state = state.copyWith(motto: v);
    await LocalStore.instance.setString(StorageKeys.motto, v);
  }

  Future<void> setWeekStart(int dow) async {
    state = state.copyWith(weekStartDow: dow);
    await LocalStore.instance.setInt(StorageKeys.weekStart, dow);
  }

  Future<void> setShowPast(bool v) async {
    state = state.copyWith(showPast: v);
    await LocalStore.instance.setBool('calendar-show-past-v1', v);
  }

  Future<void> setContinuousView(bool v) async {
    state = state.copyWith(continuousView: v);
    await LocalStore.instance.setBool(StorageKeys.continuousView, v);
  }

  Future<void> setNotify(bool v) async {
    state = state.copyWith(notifyEnabled: v);
    await LocalStore.instance.setBool(StorageKeys.notifyEnabled, v);
  }

  Future<void> setShowTimetable(bool v) async {
    state = state.copyWith(showTimetable: v);
    await LocalStore.instance.setBool(StorageKeys.showTimetable, v);
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
