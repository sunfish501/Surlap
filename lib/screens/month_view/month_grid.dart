import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/date_utils.dart' as du;
import '../../models/event_item.dart';
import '../../models/todo_item.dart';
import '../../models/calendar_theme.dart';
import '../../models/day_template.dart';
import '../../models/template_range.dart';
import '../../models/record_template.dart';
import 'day_cell.dart';
import 'multiday_span.dart';

class MonthGrid extends StatelessWidget {
  final int year;
  final int month;
  final int weekStartDow;
  final Map<String, List<EventItem>> events;
  final Map<String, List<TodoItem>> todosByDate;
  final List<CalendarTheme> themes;
  final SpaceHourColors sh;
  final bool showPast;
  final Map<String, int> starred;
  final Set<String> circles;
  final Map<String, String> memos;
  final List<DayTemplate> dayTemplates;
  final Map<String, Map<String, Map<String, dynamic>>> widgetValues;
  /// 기록 템플릿 적용 기간 — 셀 뱃지/하이라이트 계산용.
  final List<TemplateRange> templateRanges;
  /// 기록 템플릿 id→정의(셀 뱃지 이모지 조회).
  final Map<String, RecordTemplate> templatesById;
  final void Function(DateTime) onDayTap;
  final void Function(DateTime) onDayLongPress;
  final void Function(DateTime)? onDayDoubleTap;
  final void Function(String memoKey, String current)? onMemoTap;
  /// 날짜 셀 Hero 줌인 활성화 (단일 월 그리드에서만 — 연속 보기는 끔).
  final bool heroCells;

  const MonthGrid({
    super.key,
    required this.year,
    required this.month,
    required this.weekStartDow,
    required this.events,
    this.todosByDate = const {},
    required this.themes,
    required this.sh,
    required this.showPast,
    this.starred = const {},
    this.circles = const {},
    this.memos = const {},
    this.dayTemplates = const [],
    this.widgetValues = const {},
    this.templateRanges = const [],
    this.templatesById = const {},
    required this.onDayTap,
    required this.onDayLongPress,
    this.onDayDoubleTap,
    this.onMemoTap,
    this.heroCells = false,
  });

  @override
  Widget build(BuildContext context) {
    final headers = du.weekdayHeaders(weekStartDow);
    final firstCell = du.firstCellDate(year, month, weekStartDow);
    final viewMonth = DateTime(year, month);

    // memo boundary computation
    final firstDayDate = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final leadingCount = (firstDayDate.weekday % 7 - weekStartDow + 7) % 7;
    final firstTrailingIdx = leadingCount + daysInMonth;
    final trailingInRow5 = firstTrailingIdx >= 42
        ? 0
        : firstTrailingIdx <= 35
            ? 7
            : 42 - firstTrailingIdx;
    final monthInRow5 = 7 - trailingInRow5;

    final topMemoKey = '$year-${du.pad(month)}-top';
    final bottomMemoKey = '$year-${du.pad(month)}-bottom';

    return Column(
      children: [
        // 요일 헤더 행 — 배경 거의 투명, 경계선 없음
        Padding(
          padding: const EdgeInsets.only(top: Gap.sm, bottom: Gap.xs),
          child: Row(
            children: headers.asMap().entries.map((e) {
              final isSunHeader =
                  (weekStartDow + e.key) % 7 == DateTime.sunday % 7;
              final isSatHeader =
                  (weekStartDow + e.key) % 7 == DateTime.saturday;
              return Expanded(
                child: Center(
                  child: Text(
                    e.value,
                    style: AppType.label.copyWith(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                      color: isSunHeader
                          ? sh.sun.withValues(alpha: 0.85)
                          : isSatHeader
                              ? sh.sat.withValues(alpha: 0.85)
                              : sh.ink.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        // 날짜 그리드 (6행 × 7열)
        Expanded(
          child: Column(
            children: List.generate(6, (row) {
              // ── 첫 번째 행: 선행 메모 셀 + 날짜 셀 ──
              if (row == 0 && leadingCount > 0) {
                final cells = <Widget>[
                  Expanded(
                    flex: leadingCount,
                    child: _MemoCell(
                      text: memos[topMemoKey] ?? '',
                      sh: sh,
                      onTap: () => onMemoTap?.call(
                          topMemoKey, memos[topMemoKey] ?? ''),
                    ),
                  ),
                  ...List.generate(7 - leadingCount, (i) {
                    final col = leadingCount + i;
                    final cellDate = firstCell.add(Duration(days: col));
                    return _buildDayCell(cellDate, viewMonth);
                  }),
                ];
                return Expanded(child: Row(children: cells));
              }

              // ── 마지막 행: 날짜 셀 + 후행 메모 셀 ──
              if (row == 5 && trailingInRow5 > 0) {
                final cells = <Widget>[
                  ...List.generate(monthInRow5, (i) {
                    final cellDate = firstCell.add(Duration(days: 35 + i));
                    return _buildDayCell(cellDate, viewMonth);
                  }),
                  Expanded(
                    flex: trailingInRow5,
                    child: _MemoCell(
                      text: memos[bottomMemoKey] ?? '',
                      sh: sh,
                      onTap: () => onMemoTap?.call(
                          bottomMemoKey, memos[bottomMemoKey] ?? ''),
                    ),
                  ),
                ];
                return Expanded(child: Row(children: cells));
              }

              // ── 일반 행 (같은 이름 연속 일정 = 가로 막대 병합) ──
              return Expanded(
                child: _buildSpanningRow(
                  List.generate(
                      7, (col) => firstCell.add(Duration(days: row * 7 + col))),
                  viewMonth,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildDayCell(DateTime cellDate, DateTime viewMonth,
      {List<EventItem>? eventsOverride, double topReserve = 0}) {
    final key = du.toDateKey(cellDate);
    final cellEvents = eventsOverride ?? (events[key] ?? const <EventItem>[]);
    final applicable =
        dayTemplates.where((t) => t.enabled && t.scope.appliesTo(key)).toList();
    final dateWidgetValues = widgetValues[key] ?? {};
    final badges = recordBadgesForDate(
        key, templateRanges, dateWidgetValues, templatesById);
    return Expanded(
      child: DayCell(
        date: cellDate,
        viewMonth: viewMonth,
        events: cellEvents,
        todos: todosByDate[key] ?? const [],
        themes: themes,
        sh: sh,
        showPast: showPast,
        hasCircle: circles.contains(key),
        applicableTemplates: applicable,
        dateWidgetValues: dateWidgetValues,
        recordBadges: badges,
        onTap: () => onDayTap(cellDate),
        onLongPress: () => onDayLongPress(cellDate),
        onDoubleTap: onDayDoubleTap == null
            ? null
            : () => onDayDoubleTap!(cellDate),
        heroDateNumber: heroCells,
        topReserve: topReserve,
      ),
    );
  }

  // 한 주(7일) 행 — 같은 이름이 연속된 날을 가로 막대로 병합해 올린다.
  Widget _buildSpanningRow(List<DateTime> weekDates, DateTime viewMonth) {
    final colEvents = [
      for (final d in weekDates)
        (events[du.toDateKey(d)] ?? const <EventItem>[])
            .where((e) => !e.isTimetable)
            .toList()
    ];
    final res = computeDaySpans(colEvents, themes, sh);
    final reserve = spanSlotCount(res.spans) * kSpanBarH;
    final rowW = Row(
      children: List.generate(7, (col) {
        final cellEvents = colEvents[col]
            .where((e) => !res.spanned.contains('$col|${e.t}'))
            .toList();
        return _buildDayCell(weekDates[col], viewMonth,
            eventsOverride: cellEvents, topReserve: reserve);
      }),
    );
    if (res.spans.isEmpty) return rowW;
    return LayoutBuilder(builder: (ctx, c) {
      final colW = c.maxWidth / 7;
      const top = 36.0; // 날짜 숫자 아래(이벤트 영역 시작)
      return Stack(
        children: [
          rowW,
          ...res.spans.map((s) => Positioned(
                top: top + s.slot * kSpanBarH,
                left: s.start * colW + 1.5,
                width: (s.end - s.start + 1) * colW - 3,
                height: kSpanBarH - 2,
                child: SpanBar(span: s, sh: sh),
              )),
        ],
      );
    });
  }
}

class _MemoCell extends StatelessWidget {
  final String text;
  final SpaceHourColors sh;
  final VoidCallback? onTap;

  const _MemoCell({required this.text, required this.sh, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: sh.card2.withValues(alpha: 0.4),
          border: Border(
            bottom: BorderSide(
                color: sh.ink.withValues(alpha: 0.05), width: 1),
          ),
        ),
        padding: const EdgeInsets.all(Gap.sm),
        alignment: Alignment.topLeft,
        child: text.isNotEmpty
            ? Text(
                text,
                style: TextStyle(
                    fontSize: 9, color: sh.inkSoft, height: 1.3),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              )
            : Text(
                '메모...',
                style: TextStyle(
                    fontSize: 9,
                    color: sh.inkFaint.withValues(alpha: 0.5)),
              ),
      ),
    );
  }
}
