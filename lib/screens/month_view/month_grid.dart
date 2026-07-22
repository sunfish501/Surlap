import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/date_utils.dart' as du;
import '../../core/utils/todo_style.dart';
import '../../i18n/dates.dart' as dates;
import '../../i18n/strings.dart';
import '../../models/calendar_theme.dart';
import '../../models/day_template.dart';
import '../../models/event_item.dart';
import '../../models/record_template.dart';
import '../../models/template_range.dart';
import '../../models/todo_item.dart';
import 'day_cell.dart';
import 'multiday_span.dart';

const double _kBarTop = 36;
const double _kBadgeHeight = 17;
const double _kRibbonHeight = 13;
const double _kRibbonStep = 15;
const double _kDetailHeight = 112;

class MonthGrid extends StatefulWidget {
  final int year;
  final int month;
  final int weekStartDow;
  final Map<String, List<EventItem>> events;
  final Map<String, List<TodoItem>> todosByDate;
  final List<CalendarTheme> themes;
  final SurlapColors sh;
  final bool showPast;
  final Map<String, int> starred;
  final Set<String> circles;
  final List<DayTemplate> dayTemplates;
  final Map<String, Map<String, Map<String, dynamic>>> widgetValues;
  final List<TemplateRange> templateRanges;
  final Map<String, RecordTemplate> templatesById;
  final void Function(DateTime) onDayTap;
  final void Function(DateTime) onDayLongPress;
  final void Function(DateTime)? onDayDoubleTap;
  final bool heroCells;
  final double cellHeightFactor;
  final bool allowInternalScroll;

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
    this.dayTemplates = const [],
    this.widgetValues = const {},
    this.templateRanges = const [],
    this.templatesById = const {},
    required this.onDayTap,
    required this.onDayLongPress,
    this.onDayDoubleTap,
    this.heroCells = false,
    this.cellHeightFactor = 1.0,
    this.allowInternalScroll = true,
  });

  @override
  State<MonthGrid> createState() => _MonthGridState();
}

class _MonthGridState extends State<MonthGrid> {
  late DateTime _selectedDate;
  late int _leadingCount;
  late int _trailingInRow5;
  late DateTime _firstCell;

  SurlapColors get sh => widget.sh;

  @override
  void initState() {
    super.initState();
    _selectedDate = _initialSelection();
  }

  @override
  void didUpdateWidget(covariant MonthGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.year != widget.year || oldWidget.month != widget.month) {
      _selectedDate = _initialSelection();
    }
  }

  DateTime _initialSelection() {
    final today = DateTime.now();
    if (today.year == widget.year && today.month == widget.month) {
      return DateTime(today.year, today.month, today.day);
    }
    return DateTime(widget.year, widget.month, 1);
  }

  List<RecordBadge> _badgesFor(DateTime date) {
    final dateKey = du.toDateKey(date);
    return recordBadgesForDate(
      dateKey,
      widget.templateRanges,
      widget.widgetValues[dateKey] ?? const {},
      widget.templatesById,
    );
  }

  ({
    List<DateTime> dates,
    List<List<EventItem>> colEvents,
    List<List<TodoItem>> colTodos,
    int leadMemo,
    int trailMemo,
    bool hasBadge,
  })
  _rowInfo(int row) {
    final rowDates = List.generate(
      7,
      (column) => _firstCell.add(Duration(days: row * 7 + column)),
    );
    final leadMemo = row == 0 && _leadingCount > 0 ? _leadingCount : 0;
    final trailMemo = row == 5 && _trailingInRow5 > 0 ? _trailingInRow5 : 0;
    final colEvents = <List<EventItem>>[];
    final colTodos = <List<TodoItem>>[];
    var hasBadge = false;

    for (var column = 0; column < 7; column++) {
      final isMemo = column < leadMemo || column >= 7 - trailMemo;
      if (isMemo) {
        colEvents.add(const []);
        colTodos.add(const []);
        continue;
      }
      final dateKey = du.toDateKey(rowDates[column]);
      colEvents.add(
        (widget.events[dateKey] ?? const <EventItem>[])
            .where((event) => !event.isTimetable)
            .toList(),
      );
      colTodos.add(widget.todosByDate[dateKey] ?? const []);
      if (!hasBadge && _badgesFor(rowDates[column]).isNotEmpty) {
        hasBadge = true;
      }
    }

    return (
      dates: rowDates,
      colEvents: colEvents,
      colTodos: colTodos,
      leadMemo: leadMemo,
      trailMemo: trailMemo,
      hasBadge: hasBadge,
    );
  }

  @override
  Widget build(BuildContext context) {
    final headers = du.weekdayHeaders(widget.weekStartDow);
    _firstCell = du.firstCellDate(
      widget.year,
      widget.month,
      widget.weekStartDow,
    );

    final firstDay = DateTime(widget.year, widget.month, 1);
    final daysInMonth = DateTime(widget.year, widget.month + 1, 0).day;
    _leadingCount = (firstDay.weekday % 7 - widget.weekStartDow + 7) % 7;
    final firstTrailingIndex = _leadingCount + daysInMonth;
    _trailingInRow5 = firstTrailingIndex >= 42
        ? 0
        : firstTrailingIndex <= 35
        ? 7
        : 42 - firstTrailingIndex;

    return Column(
      children: [
        Expanded(
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: sh.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: sh.border, width: Borders.hairline),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 32,
                  child: Row(
                    children: headers.asMap().entries.map((entry) {
                      final weekday = (widget.weekStartDow + entry.key) % 7;
                      final isSunday = weekday == DateTime.sunday % 7;
                      final isSaturday = weekday == DateTime.saturday;
                      return Expanded(
                        child: Center(
                          child: Text(
                            entry.value,
                            style: AppType.labelMedium.copyWith(
                              color: isSunday
                                  ? sh.sun.withValues(alpha: 0.72)
                                  : isSaturday
                                  ? sh.sat.withValues(alpha: 0.72)
                                  : sh.inkSoft,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final availableRowHeight = constraints.maxHeight / 6;
                      final baseRowHeight = availableRowHeight < 52
                          ? 52.0
                          : availableRowHeight;
                      final rowHeight = widget.allowInternalScroll
                          ? (baseRowHeight * widget.cellHeightFactor)
                                .clamp(52.0, double.infinity)
                                .toDouble()
                          : baseRowHeight;
                      final totalHeight = rowHeight * 6;
                      final grid = Column(
                        children: List.generate(
                          6,
                          (row) => SizedBox(
                            height: rowHeight,
                            child: _weekRow(row, rowHeight),
                          ),
                        ),
                      );
                      if (!widget.allowInternalScroll ||
                          totalHeight <= constraints.maxHeight + 0.5) {
                        return grid;
                      }
                      return SingleChildScrollView(
                        child: SizedBox(height: totalHeight, child: grid),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        _selectedDayCard(),
      ],
    );
  }

  Widget _weekRow(int row, double rowHeight) {
    final info = _rowInfo(row);
    final bars = computeWeekBars(
      info.colEvents,
      info.colTodos,
      info.dates,
      widget.themes,
      sh,
    ).bars;
    final barTop = _kBarTop + (info.hasBadge ? _kBadgeHeight : 0);
    final maxLanes = ((rowHeight - barTop - 2) / _kRibbonStep).floor().clamp(
      1,
      4,
    );
    final viewMonth = DateTime(widget.year, widget.month);
    final cells = [for (final date in info.dates) _dayCell(date, viewMonth)];

    if (bars.isEmpty) return Row(children: cells);

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnWidth = constraints.maxWidth / 7;
        return Stack(
          children: [
            Row(children: cells),
            IgnorePointer(
              child: Stack(
                children: [
                  for (final bar in bars)
                    if (bar.lane < maxLanes)
                      Positioned(
                        top: barTop + bar.lane * _kRibbonStep,
                        left: bar.start * columnWidth + 2,
                        width: (bar.end - bar.start + 1) * columnWidth - 4,
                        height: _kRibbonHeight,
                        child: _EventRibbon(bar: bar),
                      ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _dayCell(DateTime cellDate, DateTime viewMonth) {
    final isToday = du.isSameDay(cellDate, DateTime.now());
    final isSelected = du.isSameDay(cellDate, _selectedDate);
    final todayColor = sh.dark
        ? const Color(0xFF2A2540)
        : const Color(0xFFEBE4FD);

    return Expanded(
      child: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(color: isToday ? todayColor : Colors.transparent),
          ),
          Positioned.fill(
            child: DayCell(
              date: cellDate,
              viewMonth: viewMonth,
              events: const [],
              todos: const [],
              themes: widget.themes,
              sh: sh,
              showPast: widget.showPast,
              hasCircle: widget.circles.contains(du.toDateKey(cellDate)),
              recordBadges: _badgesFor(cellDate),
              onTap: () => setState(() => _selectedDate = cellDate),
              onLongPress: () => widget.onDayLongPress(cellDate),
              onDoubleTap: widget.onDayDoubleTap == null
                  ? null
                  : () => widget.onDayDoubleTap!(cellDate),
              heroDateNumber: widget.heroCells,
            ),
          ),
          if (isSelected && !isToday)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: sh.accent.withValues(alpha: 0.72),
                      width: Borders.divider,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _selectedDayCard() {
    final dateKey = du.toDateKey(_selectedDate);
    final dayEvents = (widget.events[dateKey] ?? const <EventItem>[])
        .where((event) => !event.isTimetable)
        .toList();
    final dayTodos = widget.todosByDate[dateKey] ?? const <TodoItem>[];
    final total = dayEvents.length + dayTodos.length;
    final rows = <Widget>[];

    for (final event in dayEvents) {
      if (rows.length >= 3) break;
      rows.add(_eventDetailRow(event));
    }
    for (final todo in dayTodos) {
      if (rows.length >= 3) break;
      rows.add(_todoDetailRow(todo));
    }

    final isToday = du.isSameDay(_selectedDate, DateTime.now());
    final title =
        '${_selectedDate.day}${tr('일')} (${dates.weekdayShort(_selectedDate.weekday)})${isToday ? ' · ${tr('오늘')}' : ''}';

    return SizedBox(
      height: _kDetailHeight,
      child: Material(
        color: sh.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: sh.border, width: Borders.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => widget.onDayTap(_selectedDate),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Gap.md,
              vertical: Gap.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.titleMedium.copyWith(
                    fontSize: 14,
                    color: sh.ink,
                  ),
                ),
                const SizedBox(height: Gap.xs),
                if (rows.isEmpty)
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        tr('이 날은 아직 비어있어요'),
                        style: AppType.bodySmall.copyWith(color: sh.inkSoft),
                      ),
                    ),
                  )
                else
                  ...rows,
                if (total > rows.length)
                  Text(
                    '+${total - rows.length}',
                    style: AppType.labelMedium.copyWith(color: sh.inkSoft),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _eventDetailRow(EventItem event) {
    final time = event.hasTime
        ? event.te == null || event.te!.isEmpty
              ? event.tm!
              : '${event.tm}–${event.te}'
        : tr('종일');
    return _detailRow(
      color: eventColorFor(event, widget.themes, sh),
      title: event.t,
      trailing: time,
    );
  }

  Widget _todoDetailRow(TodoItem todo) {
    return _detailRow(
      color: todoStatusColor(todo.status, todo.priority, sh),
      title: todo.title,
      trailing: tr('할 일'),
      done: todo.done,
    );
  }

  Widget _detailRow({
    required Color color,
    required String title,
    required String trailing,
    bool done = false,
  }) {
    return SizedBox(
      height: 21,
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: Gap.sm),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppType.bodySmall.copyWith(
                color: done ? sh.inkFaint : sh.ink,
                decoration: done ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          const SizedBox(width: Gap.sm),
          Text(
            trailing,
            style: AppType.labelMedium.copyWith(color: sh.inkSoft),
          ),
        ],
      ),
    );
  }
}

class _EventRibbon extends StatelessWidget {
  final WeekBar bar;

  const _EventRibbon({required this.bar});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: bar.done ? bar.color.withValues(alpha: 0.55) : bar.color,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        bar.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: const Color(
            0xFF14131A,
          ).withValues(alpha: bar.done ? 0.58 : 0.95),
          fontSize: 8,
          height: 1,
          fontWeight: FontWeight.w700,
          decoration: bar.done ? TextDecoration.lineThrough : null,
        ),
      ),
    );
  }
}
