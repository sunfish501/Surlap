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

class MonthView extends ConsumerStatefulWidget {
  const MonthView({super.key});

  @override
  ConsumerState<MonthView> createState() => _MonthViewState();
}

class _MonthViewState extends ConsumerState<MonthView> {
  static const double _minimumMonthExtent = 600;

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(viewProvider);
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
          targetMonth: DateTime(view.viewYear, view.viewMonth),
          itemExtent: monthExtent,
          onVisibleMonthChanged: _syncHeaderMonth,
          itemBuilder: (context, month) {
            final monthEvents = _eventsForMonth(
              mergedEvents,
              birthdays,
              month,
              includeBirthdays: !hiddenThemes.contains(birthdayThemeId),
            );
            final monthTodos = _itemsForMonth(todosByDate, month);
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
    Map<String, List<EventItem>> events,
    List<Birthday> birthdays,
    DateTime month, {
    required bool includeBirthdays,
  }) {
    final result = _itemsForMonth(events, month);
    if (!includeBirthdays) return result;

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

  Map<String, List<T>> _itemsForMonth<T>(
    Map<String, List<T>> items,
    DateTime month,
  ) {
    final prefix = '${month.year}-${month.month.toString().padLeft(2, '0')}-';
    return Map<String, List<T>>.fromEntries(
      items.entries.where((entry) => entry.key.startsWith(prefix)),
    );
  }

  void _syncHeaderMonth(DateTime month) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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
}
