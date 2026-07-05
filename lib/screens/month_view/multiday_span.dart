import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/todo_style.dart';
import '../../models/event_item.dart';
import '../../models/todo_item.dart';
import '../../models/calendar_theme.dart';

/// 여러 날 이어지는 같은 이름 일정의 가로 막대.
class DaySpan {
  final String title;
  final int start;
  final int end;
  final Color color;
  int slot = 0;
  DaySpan({
    required this.title,
    required this.start,
    required this.end,
    required this.color,
  });
}

const double kSpanBarH = 13.0;

Color eventColorFor(
    EventItem e, List<CalendarTheme> themes, SurlapColors sh) {
  if (e.birthday) return sh.birthdayColor;
  if (e.academic) return sh.academicColor;
  if (e.sport && e.sportColor != null) return Color(e.sportColor!);
  final ids = e.themeIds;
  if (ids.isNotEmpty) {
    try {
      return themes.firstWhere((t) => ids.contains(t.id)).colorValue;
    } catch (_) {}
  }
  return sh.accent;
}

/// 칸별 일정 리스트(가변 길이 N)에서 연속 동일 제목을 막대로 묶고 슬롯 배정.
/// 반환: spans(슬롯 포함) + spanned('col|title' 집합 — 셀 중복표시 방지용).
({List<DaySpan> spans, Set<String> spanned}) computeDaySpans(
  List<List<EventItem>> colEvents,
  List<CalendarTheme> themes,
  SurlapColors sh,
) {
  final n = colEvents.length;
  final present = <String, List<bool>>{};
  final firstOf = <String, EventItem>{};
  for (int i = 0; i < n; i++) {
    for (final e in colEvents[i]) {
      (present[e.t] ??= List.filled(n, false))[i] = true;
      firstOf.putIfAbsent(e.t, () => e);
    }
  }
  final spans = <DaySpan>[];
  present.forEach((title, arr) {
    int i = 0;
    while (i < n) {
      if (!arr[i]) {
        i++;
        continue;
      }
      int j = i;
      while (j + 1 < n && arr[j + 1]) {
        j++;
      }
      if (j > i) {
        spans.add(DaySpan(
          title: title,
          start: i,
          end: j,
          color: eventColorFor(firstOf[title]!, themes, sh),
        ));
      }
      i = j + 1;
    }
  });
  spans.sort((a, b) => a.start.compareTo(b.start));
  final slotEnds = <int>[];
  for (final s in spans) {
    int slot = 0;
    while (slot < slotEnds.length && slotEnds[slot] >= s.start) {
      slot++;
    }
    if (slot == slotEnds.length) {
      slotEnds.add(s.end);
    } else {
      slotEnds[slot] = s.end;
    }
    s.slot = slot;
  }
  final spanned = <String>{};
  for (final s in spans) {
    for (int c = s.start; c <= s.end; c++) {
      spanned.add('$c|${s.title}');
    }
  }
  return (spans: spans, spanned: spanned);
}

int spanSlotCount(List<DaySpan> spans) =>
    spans.isEmpty ? 0 : (spans.map((s) => s.slot).reduce((a, b) => a > b ? a : b) + 1);

// ─── 월간: 모든 일정/할일을 가로 색 바(span)로 ──────────────────────────
/// 한 주의 모든 일정/할일을 바로 표현. 단일일도 포함, 연속 동일 제목은 하나의
/// 긴 바로 묶고, 겹치는 바는 다른 레인(세로 슬롯)에 패킹한다.
class WeekBar {
  final int start; // 0..6
  final int end; // 0..6 (포함)
  final Color color;
  final String label;
  final bool isTodo;
  final bool done;
  final DateTime date; // 시작일(탭 → 상세)
  int lane = 0;
  WeekBar({
    required this.start,
    required this.end,
    required this.color,
    required this.label,
    required this.date,
    this.isTodo = false,
    this.done = false,
  });
}

({List<WeekBar> bars, int laneCount}) computeWeekBars(
  List<List<EventItem>> colEvents,
  List<List<TodoItem>> colTodos,
  List<DateTime> weekDates,
  List<CalendarTheme> themes,
  SurlapColors sh,
) {
  final n = colEvents.length; // 7
  final bars = <WeekBar>[];

  // 이벤트: 제목별로 모아 연속 구간을 바로.
  final present = <String, List<bool>>{};
  final firstOf = <String, EventItem>{};
  for (int i = 0; i < n; i++) {
    for (final e in colEvents[i]) {
      (present[e.t] ??= List.filled(n, false))[i] = true;
      firstOf.putIfAbsent(e.t, () => e);
    }
  }
  present.forEach((title, arr) {
    int i = 0;
    while (i < n) {
      if (!arr[i]) {
        i++;
        continue;
      }
      int j = i;
      while (j + 1 < n && arr[j + 1]) {
        j++;
      }
      bars.add(WeekBar(
        start: i,
        end: j,
        color: eventColorFor(firstOf[title]!, themes, sh),
        label: title,
        date: weekDates[i],
      ));
      i = j + 1;
    }
  });

  // 할 일: 단일일 바.
  for (int i = 0; i < n; i++) {
    for (final t in colTodos[i]) {
      bars.add(WeekBar(
        start: i,
        end: i,
        color: todoStatusColor(t.status, t.priority, sh),
        label: t.title,
        date: weekDates[i],
        isTodo: true,
        done: t.done,
      ));
    }
  }

  // 레인 패킹 — 시작 빠른 순(같으면 긴 바 먼저), 겹치면 다음 레인.
  bars.sort((a, b) {
    final s = a.start.compareTo(b.start);
    if (s != 0) return s;
    return (b.end - b.start).compareTo(a.end - a.start);
  });
  final laneEnds = <int>[];
  for (final bar in bars) {
    int lane = 0;
    while (lane < laneEnds.length && laneEnds[lane] >= bar.start) {
      lane++;
    }
    if (lane == laneEnds.length) {
      laneEnds.add(bar.end);
    } else {
      laneEnds[lane] = bar.end;
    }
    bar.lane = lane;
  }
  return (bars: bars, laneCount: laneEnds.length);
}

class SpanBar extends StatelessWidget {
  final DaySpan span;
  final SurlapColors sh;
  const SpanBar({super.key, required this.span, required this.sh});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: span.color.withValues(alpha: sh.dark ? 0.30 : 0.18),
        borderRadius: BorderRadius.circular(4),
        border: Border(left: BorderSide(color: span.color, width: 3)),
      ),
      child: Text(
        span.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: sh.dark ? sh.ink : span.color,
        ),
      ),
    );
  }
}
