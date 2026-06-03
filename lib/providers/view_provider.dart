import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ViewMode { home, events, year, planner, day, timetable, study, settings, themes }

// 슬라이드 순서: home/timetable/study/settings/themes는 방향 없음(-1)
const _viewOrder = {
  ViewMode.home: -1,
  ViewMode.year: 0,
  ViewMode.events: 1,
  ViewMode.planner: 2,
  ViewMode.day: 3,
  ViewMode.timetable: -1,
  ViewMode.study: -1,
  ViewMode.settings: -1,
  ViewMode.themes: -1,
};

int viewIndex(ViewMode m) => _viewOrder[m] ?? -1;

class ViewState {
  final ViewMode mode;
  final int viewYear;
  final int viewMonth;
  final String? viewDay; // 'YYYY-MM-DD'
  final ViewMode? prevMode; // 슬라이드 방향 계산용

  const ViewState({
    this.mode = ViewMode.home,
    required this.viewYear,
    required this.viewMonth,
    this.viewDay,
    this.prevMode,
  });

  ViewState copyWith({
    ViewMode? mode, int? viewYear, int? viewMonth,
    String? viewDay, ViewMode? prevMode,
  }) => ViewState(
    mode: mode ?? this.mode,
    viewYear: viewYear ?? this.viewYear,
    viewMonth: viewMonth ?? this.viewMonth,
    viewDay: viewDay ?? this.viewDay,
    prevMode: prevMode ?? this.prevMode,
  );

  /// 슬라이드 방향: 1=왼쪽(앞으로), -1=오른쪽(뒤로), 0=없음
  int get slideDirection {
    if (prevMode == null) return 0;
    final from = viewIndex(prevMode!);
    final to = viewIndex(mode);
    if (from < 0 || to < 0 || from == to) return 0;
    return to > from ? 1 : -1;
  }
}

class ViewNotifier extends Notifier<ViewState> {
  @override
  ViewState build() {
    final now = DateTime.now();
    return ViewState(viewYear: now.year, viewMonth: now.month);
  }

  void setMode(ViewMode mode) {
    state = state.copyWith(mode: mode, prevMode: state.mode);
  }

  void setDayView(String dateKey) {
    state = state.copyWith(mode: ViewMode.day, viewDay: dateKey, prevMode: state.mode);
  }

  /// 주간 뷰로 이동하며 기준 날짜(주 anchor)를 전달.
  void setWeekView(String dateKey) {
    state = state.copyWith(
        mode: ViewMode.planner, viewDay: dateKey, prevMode: state.mode);
  }

  void goToToday() {
    final now = DateTime.now();
    state = state.copyWith(viewYear: now.year, viewMonth: now.month);
  }

  void prevMonth() {
    int m = state.viewMonth - 1;
    int y = state.viewYear;
    if (m < 1) { m = 12; y--; }
    state = state.copyWith(viewYear: y, viewMonth: m);
  }

  void nextMonth() {
    int m = state.viewMonth + 1;
    int y = state.viewYear;
    if (m > 12) { m = 1; y++; }
    state = state.copyWith(viewYear: y, viewMonth: m);
  }

  void prevYear() => state = state.copyWith(viewYear: state.viewYear - 1);
  void nextYear() => state = state.copyWith(viewYear: state.viewYear + 1);

  void setYearMonth(int year, int month) =>
      state = state.copyWith(viewYear: year, viewMonth: month);
}

final viewProvider =
    NotifierProvider<ViewNotifier, ViewState>(ViewNotifier.new);
