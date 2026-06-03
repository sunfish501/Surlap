import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/date_utils.dart' as du;
import '../../models/event_item.dart';
import '../../models/calendar_theme.dart';
import '../../models/day_template.dart';
import 'day_cell.dart';

class MonthGrid extends StatelessWidget {
  final int year;
  final int month;
  final int weekStartDow;
  final Map<String, List<EventItem>> events;
  final List<CalendarTheme> themes;
  final SpaceHourColors sh;
  final bool showPast;
  final Map<String, int> starred;
  final Set<String> circles;
  final Map<String, String> memos;
  final List<DayTemplate> dayTemplates;
  final Map<String, Map<String, Map<String, dynamic>>> widgetValues;
  final void Function(DateTime) onDayTap;
  final void Function(DateTime) onDayLongPress;
  final void Function(String memoKey, String current)? onMemoTap;
  /// 날짜 셀 Hero 줌인 활성화 (단일 월 그리드에서만 — 연속 보기는 끔).
  final bool heroCells;

  const MonthGrid({
    super.key,
    required this.year,
    required this.month,
    required this.weekStartDow,
    required this.events,
    required this.themes,
    required this.sh,
    required this.showPast,
    this.starred = const {},
    this.circles = const {},
    this.memos = const {},
    this.dayTemplates = const [],
    this.widgetValues = const {},
    required this.onDayTap,
    required this.onDayLongPress,
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

              // ── 일반 행 ──
              return Expanded(
                child: Row(
                  children: List.generate(7, (col) {
                    final cellDate =
                        firstCell.add(Duration(days: row * 7 + col));
                    return _buildDayCell(cellDate, viewMonth);
                  }),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildDayCell(DateTime cellDate, DateTime viewMonth) {
    final key = du.toDateKey(cellDate);
    final cellEvents = events[key] ?? [];
    final applicable =
        dayTemplates.where((t) => t.enabled && t.scope.appliesTo(key)).toList();
    final dateWidgetValues = widgetValues[key] ?? {};
    return Expanded(
      child: DayCell(
        date: cellDate,
        viewMonth: viewMonth,
        events: cellEvents,
        themes: themes,
        sh: sh,
        showPast: showPast,
        starCount: starred[key] ?? 0,
        hasCircle: circles.contains(key),
        applicableTemplates: applicable,
        dateWidgetValues: dateWidgetValues,
        onTap: () => onDayTap(cellDate),
        onLongPress: () => onDayLongPress(cellDate),
        heroDateNumber: heroCells,
      ),
    );
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
