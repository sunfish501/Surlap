import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/date_utils.dart' as du;
import '../../models/event_item.dart';
import '../../models/calendar_theme.dart';
import '../../models/day_template.dart';
import '../../day_widgets/widget_cell_renderer.dart';
import 'event_chip.dart';

class DayCell extends StatelessWidget {
  final DateTime date;
  final DateTime viewMonth;
  final List<EventItem> events;
  final List<CalendarTheme> themes;
  final SpaceHourColors sh;
  final bool showPast;
  final int starCount;
  final bool hasCircle;
  final List<DayTemplate> applicableTemplates;
  final Map<String, Map<String, dynamic>> dateWidgetValues;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  /// 셀 탭 시 날짜 숫자가 액션 시트 헤더로 줌인되는 Hero 전환.
  /// 연속 보기는 같은 날짜가 여러 그리드에 중복 렌더되어 태그가 충돌하므로 끈다.
  final bool heroDateNumber;

  const DayCell({
    super.key,
    required this.date,
    required this.viewMonth,
    required this.events,
    required this.themes,
    required this.sh,
    required this.showPast,
    this.starCount = 0,
    this.hasCircle = false,
    this.applicableTemplates = const [],
    this.dateWidgetValues = const {},
    required this.onTap,
    required this.onLongPress,
    this.heroDateNumber = false,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = du.isSameDay(date, now);
    final isCurrentMonth = date.month == viewMonth.month;
    final isPast = date.isBefore(DateTime(now.year, now.month, now.day));
    final isSun = date.weekday == DateTime.sunday;
    final isSat = date.weekday == DateTime.saturday;

    final dimmed = !isCurrentMonth || (!showPast && isPast && !isToday);

    Color dayNumColor;
    if (isToday) {
      dayNumColor = Colors.white;
    } else if (isSun) {
      dayNumColor = sh.sun.withValues(alpha: dimmed ? 0.35 : 1.0);
    } else if (isSat) {
      dayNumColor = sh.sat.withValues(alpha: dimmed ? 0.35 : 1.0);
    } else {
      dayNumColor = dimmed ? sh.ink.withValues(alpha: 0.30) : sh.ink;
    }

    final visible = events.where((e) => !e.isTimetable).toList();

    // 오늘: 브랜드 퍼플 원 + 은은한 글로우 / 선택 동그라미: 브랜드 테두리
    Widget dayNumber = Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: hasCircle
          ? BoxDecoration(
              border: Border.all(
                  color: sh.accent.withValues(alpha: dimmed ? 0.3 : 0.7),
                  width: 1.5),
              shape: BoxShape.circle)
          : isToday
              ? BoxDecoration(
                  color: sh.accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: sh.accent.withValues(alpha: 0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                )
              : null,
      child: Text(
        '${date.day}',
        style: AppType.label.copyWith(
          fontSize: isToday ? 13 : 12,
          fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
          color: dayNumColor,
        ),
      ),
    );
    if (heroDateNumber) {
      dayNumber = Hero(
        tag: 'daycell-${du.toDateKey(date)}',
        child: dayNumber,
      );
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          // 오늘 칸은 은은한 브랜드 틴트로 강조(따뜻한 톤).
          color: isToday
              ? sh.accent.withValues(alpha: sh.dark ? 0.12 : 0.06)
              : Colors.transparent,
          // 세로선 제거 — 가로선만 아주 약하게(planner 느낌)
          border: Border(
            bottom: BorderSide(
                color: sh.ink.withValues(alpha: 0.05), width: 1),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 날짜 숫자 + 별표/동그라미
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (starCount > 0)
                  Text(
                    List.filled(starCount, '★').join(),
                    style: TextStyle(
                        fontSize: 7,
                        color: const Color(0xFFF39C12)
                            .withValues(alpha: dimmed ? 0.4 : 1.0),
                        height: 1.2),
                  )
                else
                  const SizedBox(width: 1),
                dayNumber,
              ],
            ),
            // 이벤트 + 위젯 (남은 공간 채움, 오버플로우 클립)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...visible.take(3).map((e) => EventChip(
                        item: e,
                        themes: themes,
                        sh: sh,
                      )),
                  if (visible.length > 3)
                    Text('+${visible.length - 3}',
                        style: TextStyle(fontSize: 9, color: sh.inkSoft)),
                  if (applicableTemplates.isNotEmpty)
                    ..._buildWidgetRows(dimmed),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildWidgetRows(bool dimmed) {
    final rows = <Widget>[];
    for (final tpl in applicableTemplates) {
      final tplValues = dateWidgetValues[tpl.id] ?? {};
      for (final field in tpl.fields) {
        final value = tplValues[field.id];
        // skip fields with no value in compact mode
        final hasVal = value != null &&
            value != '' &&
            !(value is List && value.isEmpty) &&
            !(value is Map && value.isEmpty);
        if (!hasVal) continue;
        final w = WidgetCellRenderer(
          field: field,
          value: value,
          sh: sh,
          compact: true,
        );
        rows.add(Opacity(opacity: dimmed ? 0.5 : 1.0, child: w));
        if (rows.length >= 3) break; // max 3 rows in compact cell
      }
      if (rows.length >= 3) break;
    }
    return rows;
  }
}
