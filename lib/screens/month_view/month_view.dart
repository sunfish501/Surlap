import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/date_utils.dart' as du;
import '../../i18n/dates.dart' as dates;
import '../../i18n/strings.dart';
import '../../modals/day_action_sheet.dart';
import '../../models/event_item.dart';
import '../../models/todo_item.dart';
import '../../providers/academic_schedule_provider.dart';
import '../../providers/birthdays_provider.dart';
import '../../providers/day_widget_provider.dart';
import '../../providers/events_provider.dart';
import '../../providers/extras_provider.dart';
import '../../providers/filter_provider.dart';
import '../../providers/record_templates_provider.dart';
import '../../providers/recurring_events_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/shared_theme_events_provider.dart';
import '../../providers/sports_provider.dart';
import '../../providers/template_ranges_provider.dart';
import '../../providers/themes_provider.dart';
import '../../providers/todos_provider.dart';
import '../../providers/view_provider.dart';
import 'continuous_month_list.dart';
import 'month_grid.dart';

String calendarMonthKey(DateTime month) =>
    '${month.year}-${month.month.toString().padLeft(2, '0')}';

/// Builds the date-to-items lookup once, so lazy month creation is O(1)
/// instead of scanning every stored date at each month boundary.
Map<String, Map<String, List<T>>> indexCalendarItemsByMonth<T>(
  Map<String, List<T>> items,
) {
  final result = <String, Map<String, List<T>>>{};
  for (final entry in items.entries) {
    if (entry.key.length < 10 || entry.key[4] != '-' || entry.key[7] != '-') {
      continue;
    }
    final monthKey = entry.key.substring(0, 7);
    result.putIfAbsent(monthKey, () => <String, List<T>>{})[entry.key] =
        entry.value;
  }
  return result;
}

class MonthView extends ConsumerStatefulWidget {
  const MonthView({super.key});

  @override
  ConsumerState<MonthView> createState() => _MonthViewState();
}

class _MonthViewState extends ConsumerState<MonthView> {
  static const double _minimumMonthExtent = 600;
  late DateTime _targetMonth;
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    final view = ref.read(viewProvider);
    _targetMonth = DateTime(view.viewYear, view.viewMonth);
    _visibleMonth = _targetMonth;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ViewState>(viewProvider, (previous, next) {
      if (next.mode != ViewMode.events) return;
      final nextMonth = DateTime(next.viewYear, next.viewMonth);
      if (_sameMonth(nextMonth, _visibleMonth) ||
          _sameMonth(nextMonth, _targetMonth)) {
        return;
      }
      setState(() => _targetMonth = nextMonth);
    });

    final events = ref.watch(eventsProvider);
    final themes = ref.watch(themesProvider);
    final settings = ref.watch(settingsProvider);
    final hiddenThemes = ref.watch(filterProvider);
    final starred = ref.watch(starredProvider);
    final circles = ref.watch(circlesProvider);
    final widgetValues = ref.watch(widgetValuesProvider);
    final dayTemplates = ref.watch(dayTemplatesProvider);
    final birthdays = ref.watch(birthdaysProvider);
    final todos = ref.watch(todosProvider);
    final templateRanges = ref.watch(templateRangesProvider);
    final templatesById = ref.watch(recordTemplatesByIdProvider);
    final sh = context.sh;

    final todosByDate = <String, List<TodoItem>>{};
    for (final todo in todos) {
      final dateKey = todo.dateKey;
      if (dateKey == null) continue;
      todosByDate.putIfAbsent(dateKey, () => []).add(todo);
    }

    final mergedEvents = <String, List<EventItem>>{};
    for (final entry in events.entries) {
      final visible = entry.value.where((item) {
        if (hiddenThemes.isEmpty) return true;
        final ids = item.themeIds;
        if (ids.isEmpty) return !hiddenThemes.contains('__none__');
        return ids.every((id) => !hiddenThemes.contains(id));
      }).toList();
      if (visible.isNotEmpty) mergedEvents[entry.key] = visible;
    }

    if (!hiddenThemes.contains(academicThemeId)) {
      ref.watch(academicScheduleProvider).forEach((dateKey, names) {
        mergedEvents[dateKey] = [
          ...(mergedEvents[dateKey] ?? const <EventItem>[]),
          for (final name in names)
            EventItem(t: name, th: academicThemeId, academic: true),
        ];
      });
    }

    ref.watch(sportsEventsByDateProvider).forEach((dateKey, items) {
      final visible = items
          .where((event) => !hiddenThemes.contains(event.themeIds.first))
          .toList();
      if (visible.isNotEmpty) {
        mergedEvents[dateKey] = [
          ...(mergedEvents[dateKey] ?? const <EventItem>[]),
          ...visible,
        ];
      }
    });

    ref.watch(sharedThemeEventsByDateProvider).forEach((dateKey, items) {
      final visible = items
          .where(
            (event) =>
                event.themeIds.isNotEmpty &&
                !hiddenThemes.contains(event.themeIds.first),
          )
          .toList();
      if (visible.isNotEmpty) {
        mergedEvents[dateKey] = [
          ...(mergedEvents[dateKey] ?? const <EventItem>[]),
          ...visible,
        ];
      }
    });

    ref.watch(recurringEventsByDateProvider).forEach((dateKey, items) {
      final visible = items.where((event) {
        if (event.themeIds.isEmpty) return true;
        return !hiddenThemes.contains(event.themeIds.first);
      }).toList();
      if (visible.isNotEmpty) {
        mergedEvents[dateKey] = [
          ...(mergedEvents[dateKey] ?? const <EventItem>[]),
          ...visible,
        ];
      }
    });

    final eventsByMonth = indexCalendarItemsByMonth(mergedEvents);
    final todosByMonth = indexCalendarItemsByMonth(todosByDate);
    final birthdaysByMonth = <int, List<Birthday>>{};
    for (final birthday in birthdays) {
      birthdaysByMonth.putIfAbsent(birthday.month, () => []).add(birthday);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final monthExtent = math.max(
          _minimumMonthExtent,
          constraints.maxHeight * 0.92,
        );
        final availableSidePadding = (constraints.maxWidth - 7 * kMinTouch) / 2;
        final sidePadding = math
            .max(0, math.min(Gap.lg, availableSidePadding))
            .toDouble();

        return ContinuousMonthList(
          targetMonth: _targetMonth,
          itemExtent: monthExtent,
          onVisibleMonthChanged: _syncHeaderMonth,
          itemBuilder: (context, month) {
            final monthEvents = _eventsForMonth(
              eventsByMonth[calendarMonthKey(month)] ??
                  const <String, List<EventItem>>{},
              birthdaysByMonth[month.month] ?? const <Birthday>[],
              month,
              includeBirthdays: !hiddenThemes.contains(birthdayThemeId),
            );
            final monthTodos =
                todosByMonth[calendarMonthKey(month)] ??
                const <String, List<TodoItem>>{};
            final monthTitle =
                '${month.year}${dates.yearWord} ${dates.monthName(month.month)}'
                    .trim();

            return Padding(
              padding: EdgeInsets.fromLTRB(sidePadding, 0, sidePadding, Gap.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 52,
                    child: Row(
                      children: [
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(
                              monthTitle,
                              key: ValueKey<String>(
                                'month-title-${month.year}-${month.month}',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppType.headlineLarge.copyWith(
                                color: sh.ink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        Tooltip(
                          message: tr('오늘'),
                          child: TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: sh.accentInk,
                              minimumSize: const Size(kMinTouch, kMinTouch),
                              padding: const EdgeInsets.symmetric(
                                horizontal: Gap.md,
                              ),
                            ),
                            onPressed: () =>
                                ref.read(viewProvider.notifier).goToToday(),
                            child: Text(
                              tr('오늘'),
                              style: AppType.labelMedium.copyWith(
                                color: sh.accentInk,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: MonthGrid(
                      year: month.year,
                      month: month.month,
                      weekStartDow: settings.weekStartDow,
                      events: monthEvents,
                      todosByDate: monthTodos,
                      themes: themes,
                      sh: sh,
                      showPast: settings.showPast,
                      starred: starred,
                      circles: circles,
                      dayTemplates: dayTemplates,
                      widgetValues: widgetValues,
                      templateRanges: templateRanges,
                      templatesById: templatesById,
                      onDayTap: (date) => ref
                          .read(viewProvider.notifier)
                          .setWeekView(du.toDateKey(date)),
                      onDayLongPress: (date) => _showDayActions(context, date),
                      onDayDoubleTap: (date) => ref
                          .read(circlesProvider.notifier)
                          .toggle(du.toDateKey(date)),
                      heroCells: true,
                      cellHeightFactor: settings.monthCellHeightFactor,
                      allowInternalScroll: false,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Map<String, List<EventItem>> _eventsForMonth(
    Map<String, List<EventItem>> monthEvents,
    List<Birthday> birthdays,
    DateTime month, {
    required bool includeBirthdays,
  }) {
    if (!includeBirthdays || birthdays.isEmpty) return monthEvents;
    final result = Map<String, List<EventItem>>.of(monthEvents);

    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    for (final birthday in birthdays) {
      if (birthday.month != month.month ||
          birthday.day < 1 ||
          birthday.day > daysInMonth) {
        continue;
      }
      final dateKey = du.toDateKey(
        DateTime(month.year, birthday.month, birthday.day),
      );
      result[dateKey] = [
        ...(result[dateKey] ?? const <EventItem>[]),
        EventItem(t: birthday.name, th: birthdayThemeId, birthday: true),
      ];
    }
    return result;
  }

  void _syncHeaderMonth(DateTime month) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _visibleMonth = DateTime(month.year, month.month);
      _targetMonth = _visibleMonth;
      final current = ref.read(viewProvider);
      if (current.viewYear == month.year && current.viewMonth == month.month) {
        return;
      }
      ref.read(viewProvider.notifier).setYearMonth(month.year, month.month);
    });
  }

  void _showDayActions(BuildContext context, DateTime date) {
    showDayActionSheet(context, du.toDateKey(date), date);
  }

  bool _sameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;
}
