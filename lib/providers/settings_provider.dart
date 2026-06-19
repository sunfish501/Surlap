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
  final String timetableEmptyLabel; // 빈 교시 표시 라벨(""=off)
  /// 달력 한 칸 높이 배율(0.8 ~ 1.4). 1.0=기본(현재 화면에 6주 균등 분배).
  /// 1.0 초과면 그리드가 스크롤 가능해지고 한 칸이 더 커진다.
  final double monthCellHeightFactor;

  const AppSettings({
    this.motto = '',
    this.weekStartDow = 1,
    this.showPast = true,
    this.continuousView = false,
    this.notifyEnabled = true,
    this.showTimetable = true,
    this.timetableEmptyLabel = '',
    this.monthCellHeightFactor = 1.0,
  });

  AppSettings copyWith({
    String? motto, int? weekStartDow, bool? showPast,
    bool? continuousView, bool? notifyEnabled, bool? showTimetable,
    String? timetableEmptyLabel,
    double? monthCellHeightFactor,
  }) => AppSettings(
    motto: motto ?? this.motto,
    weekStartDow: weekStartDow ?? this.weekStartDow,
    showPast: showPast ?? this.showPast,
    continuousView: continuousView ?? this.continuousView,
    notifyEnabled: notifyEnabled ?? this.notifyEnabled,
    showTimetable: showTimetable ?? this.showTimetable,
    timetableEmptyLabel: timetableEmptyLabel ?? this.timetableEmptyLabel,
    monthCellHeightFactor: monthCellHeightFactor ?? this.monthCellHeightFactor,
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
      timetableEmptyLabel:
          s.getString(StorageKeys.timetableEmptyLabel) ?? '',
      monthCellHeightFactor: double.tryParse(
              s.getString(StorageKeys.monthCellHeightFactor) ?? '') ??
          1.0,
    );
  }

  Future<void> setMonthCellHeightFactor(double v) async {
    final clamped = v.clamp(0.8, 1.4);
    state = state.copyWith(monthCellHeightFactor: clamped);
    await LocalStore.instance.setString(
        StorageKeys.monthCellHeightFactor, clamped.toStringAsFixed(2));
  }

  Future<void> setTimetableEmptyLabel(String v) async {
    state = state.copyWith(timetableEmptyLabel: v);
    await LocalStore.instance.setString(StorageKeys.timetableEmptyLabel, v);
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
