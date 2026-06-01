import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
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
      dayNumColor = sh.accentInk;
    } else if (isSun) {
      dayNumColor = sh.danger.withValues(alpha: dimmed ? 0.4 : 1.0);
    } else if (isSat) {
      dayNumColor = sh.sat.withValues(alpha: dimmed ? 0.4 : 1.0);
    } else {
      dayNumColor = dimmed ? sh.inkFaint : sh.ink;
    }

    final visible = events.where((e) => !e.isTimetable).toList();

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: isToday ? sh.accentBg : sh.card,
          border: Border(
            right: BorderSide(color: sh.border, width: 0.5),
            bottom: BorderSide(color: sh.border, width: 0.5),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
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
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: hasCircle
                      ? BoxDecoration(
                          border: Border.all(
                              color: sh.accent
                                  .withValues(alpha: dimmed ? 0.3 : 0.7),
                              width: 1.5),
                          shape: BoxShape.circle)
                      : isToday
                          ? BoxDecoration(
                              color: sh.accent, shape: BoxShape.circle)
                          : null,
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight:
                          isToday ? FontWeight.w700 : FontWeight.w500,
                      color: isToday
                          ? (sh.dark ? sh.ink : Colors.white)
                          : dayNumColor,
                    ),
                  ),
                ),
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
