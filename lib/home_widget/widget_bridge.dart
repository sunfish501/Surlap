import 'dart:convert';
import 'dart:ui' show Color;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../core/utils/date_utils.dart' as du;
import '../i18n/dates.dart' as i18nd;
import '../i18n/strings.dart' as i18n;
import '../models/calendar_theme.dart';
import '../models/event_item.dart';
import '../models/todo_item.dart';
import '../providers/academic_schedule_provider.dart';
import '../providers/birthdays_provider.dart';
import '../providers/color_preset_provider.dart';
import '../providers/events_provider.dart';
import '../providers/filter_provider.dart';
import '../providers/neis_cache_provider.dart';
import '../providers/recurring_events_provider.dart';
import '../providers/recurring_provider.dart';
import '../providers/shared_theme_events_provider.dart';
import '../providers/sports_provider.dart';
import '../providers/themes_provider.dart';
import '../providers/todos_provider.dart';
import '../providers/user_type_provider.dart';

/// Writes the canonical payload consumed by both Android and iOS widgets.
///
/// Keep the legacy top-level fields until every installed widget has migrated.
/// New widget surfaces must prefer the versioned `small` and `medium` objects.
class WidgetBridge {
  static const appGroupId = 'group.com.kev208dev.Surlap';
  static const iosWidgetName = 'SurlapWidget';
  static const androidWidgetName = 'SurlapWidgetProvider';
  static const dataKey = 'hs_widget';

  static const schemaVersion = 2;
  static const _maxAllDay = 6;
  static const _maxTimed = 8;
  static const _maxTodos = 6;
  static const _mediumEventLimit = 3;
  static const _periodEndMinute = 50;

  static const _jewelPalette = <String>[
    '#3A3A78',
    '#2F4E7A',
    '#1F5A5A',
    '#243A6E',
    '#3E2E72',
    '#5A2E62',
    '#5A2E4E',
  ];

  static bool _inited = false;

  static Future<void> _ensureInit() async {
    if (_inited) return;
    await HomeWidget.setAppGroupId(appGroupId);
    _inited = true;
  }

  static Future<void> sync(WidgetRef ref) async {
    await _ensureInit();
    try {
      final payload = _build(ref);
      await HomeWidget.saveWidgetData<String>(dataKey, jsonEncode(payload));
      await _saveFlatKeys(payload);
      await HomeWidget.updateWidget(
        iOSName: iosWidgetName,
        androidName: androidWidgetName,
      );
    } catch (_) {
      // Widget sync must never interrupt the foreground app.
    }
  }

  static Future<void> _saveFlatKeys(Map<String, dynamic> payload) async {
    final medium = payload['medium'] as Map<String, dynamic>;
    final nextClass = medium['nextClass'] as Map<String, dynamic>;
    final small = payload['small'] as Map<String, dynamic>;

    // Existing Now/Next widgets still consume these keys directly.
    await HomeWidget.saveWidgetData<String>(
      'today',
      payload['dateLabel'] as String? ?? '',
    );
    await HomeWidget.saveWidgetData<String>(
      'schoolClass',
      payload['schoolClass'] as String? ?? '',
    );
    await HomeWidget.saveWidgetData<String>(
      'periods',
      jsonEncode(payload['periods'] ?? const []),
    );
    await HomeWidget.saveWidgetData<int>(
      'currentIndex',
      payload['currentIndex'] as int? ?? -1,
    );
    await HomeWidget.saveWidgetData<double>(
      'progress',
      (payload['progress'] as num?)?.toDouble() ?? 0,
    );
    await HomeWidget.saveWidgetData<int>(
      'minutesRemaining',
      payload['minutesRemaining'] as int? ?? 0,
    );
    for (final key in const [
      'nowName',
      'nowStart',
      'nowEnd',
      'nextName',
      'nextStart',
    ]) {
      await HomeWidget.saveWidgetData<String>(
        key,
        payload[key] as String? ?? '',
      );
    }

    // Flat v2 mirrors make gradual native migrations and debugging easier.
    await HomeWidget.saveWidgetData<int>('widgetSchemaVersion', schemaVersion);
    await HomeWidget.saveWidgetData<String>(
      'theme',
      payload['theme'] as String? ?? 'light',
    );
    await HomeWidget.saveWidgetData<String>(
      'accent',
      (payload['appearance'] as Map<String, dynamic>)['accent'] as String,
    );
    await HomeWidget.saveWidgetData<String>(
      'ddayTitle',
      small['title'] as String? ?? '',
    );
    await HomeWidget.saveWidgetData<String>(
      'ddayLabel',
      small['label'] as String? ?? '',
    );
    await HomeWidget.saveWidgetData<String>(
      'mediumEvents',
      jsonEncode(medium['events'] ?? const []),
    );
    await HomeWidget.saveWidgetData<String>('nextClass', jsonEncode(nextClass));
  }

  static Map<String, dynamic> _build(WidgetRef ref) {
    final now = DateTime.now();
    final today = du.toDateKey(now);
    final nowHM = _hm(now.hour, now.minute);
    final themes = ref.read(themesProvider);
    final hiddenThemes = ref.read(filterProvider);
    final preset = ref.read(colorPresetProvider);

    final stored = ref.read(eventsProvider)[today] ?? const <EventItem>[];
    final recurring =
        ref.read(recurringEventsByDateProvider)[today] ?? const <EventItem>[];
    final shared =
        ref.read(sharedThemeEventsByDateProvider)[today] ?? const <EventItem>[];
    final sports =
        ref.read(sportsEventsByDateProvider)[today] ?? const <EventItem>[];
    final birthdays = ref
        .read(birthdaysProvider)
        .where(
          (birthday) => birthday.month == now.month && birthday.day == now.day,
        )
        .toList();
    final academicToday =
        ref.read(academicScheduleProvider)[today] ?? const <String>[];

    bool sharedVisible(EventItem event) =>
        event.themeIds.isNotEmpty &&
        !hiddenThemes.contains(event.themeIds.first);
    bool sportVisible(EventItem event) =>
        event.themeIds.isEmpty || !hiddenThemes.contains(event.themeIds.first);

    final entries = <_TodayEntry>[
      ...stored
          .where((event) => !event.isTimetable)
          .map((event) => _TodayEntry(event, 'event')),
      ...recurring.map((event) => _TodayEntry(event, 'event')),
      ...shared
          .where(sharedVisible)
          .map((event) => _TodayEntry(event, 'shared')),
      ...sports.where(sportVisible).map((event) => _TodayEntry(event, 'sport')),
      if (!hiddenThemes.contains(birthdayThemeId))
        ...birthdays.map(
          (birthday) => _TodayEntry(
            EventItem(t: birthday.name, th: birthdayThemeId, birthday: true),
            'birthday',
          ),
        ),
      if (!hiddenThemes.contains(academicThemeId))
        ...academicToday.map(
          (name) => _TodayEntry(
            EventItem(t: name, th: academicThemeId, academic: true),
            'academic',
          ),
        ),
    ]..sort(_compareTodayEntries);

    final allDay = entries.where((entry) => !entry.event.hasTime).toList();
    final timed = entries.where((entry) => entry.event.hasTime).toList();
    final nextTimedIndex = timed.indexWhere(
      (entry) => (entry.event.tm ?? '').compareTo(nowHM) >= 0,
    );

    final todos =
        ref.read(todosProvider).where((todo) => todo.dateKey == today).toList()
          ..sort(_byPriority);

    final dayIndex = now.weekday - 1;
    final neis = ref.read(neisCacheProvider);
    final weekly = ref.read(recurringProvider);
    final classSlots = _classSlots(
      now,
      neis.timetable[dayIndex] ?? const <int, String>{},
      weekly[dayIndex] ?? const <int, String>{},
    );
    final classState = _classState(now, classSlots);
    final nextClass = classSlots
        .where((slot) => slot.start.isAfter(now))
        .firstOrNull;

    final dday = _nearestAcademic(now, ref.read(academicScheduleProvider));
    final userType = ref.read(userTypeProvider);
    final classLabel = userType?.usesMeal == true
        ? i18n.tr('오늘 시간표')
        : i18n.tr('오늘');

    return {
      'schemaVersion': schemaVersion,
      'contract': 'surlap.widget.v2',
      'generatedAt': now.toUtc().toIso8601String(),
      'date': today,
      'lang': i18n.currentLang.name,
      'theme': preset.dark ? 'dark' : 'light',
      'appearance': {
        'dark': preset.dark,
        'accent': _hexColor(preset.accent),
        'background': _hexColor(preset.app),
        'surface': _hexColor(preset.card),
        'text': _hexColor(preset.ink),
        'textSoft': _hexColor(preset.inkSoft),
        'hairline': _hexColor(preset.hairline, includeAlpha: true),
      },
      'small': _smallPayload(dday),
      'medium': {
        'date': today,
        'dateLabel': _label(now),
        'events': entries
            .take(_mediumEventLimit)
            .map((entry) => _eventPayload(entry, themes))
            .toList(),
        'eventCount': entries.length,
        'nextClass': _nextClassPayload(nextClass),
      },

      // Legacy hs_widget contract. Do not remove before a native migration window.
      'dateLabel': _label(now),
      'schoolClass': classLabel,
      'weekday': now.weekday,
      'nowHM': nowHM,
      'nextIndex': nextTimedIndex,
      'todoCount': todos.length,
      'todoDone': todos.where((todo) => todo.done).length,
      'eventCount': entries.length,
      'allDay': allDay
          .take(_maxAllDay)
          .map(
            (entry) => {
              'title': entry.event.t,
              'color': _eventColor(entry.event, themes),
              'emoji': _emoji(entry.event),
            },
          )
          .toList(),
      'timed': timed
          .take(_maxTimed)
          .map(
            (entry) => {
              'title': entry.event.t,
              'time': entry.event.tm ?? '',
              'end': entry.event.te ?? '',
              'color': _eventColor(entry.event, themes),
              'emoji': _emoji(entry.event),
              'sport': entry.event.sport,
            },
          )
          .toList(),
      'todos': todos
          .take(_maxTodos)
          .map(
            (todo) => {
              'title': todo.title,
              'done': todo.done,
              'priority': todo.priority,
            },
          )
          .toList(),
      'periods': classSlots.map((slot) => slot.toLegacyJson()).toList(),
      'currentIndex': classState.currentIndex,
      'progress': classState.progress,
      'minutesRemaining': classState.minutesRemaining,
      'nowName': classState.current?.title ?? '',
      'nowStart': classState.current?.startLabel ?? '',
      'nowEnd': classState.current?.endLabel ?? '',
      'nextName': classState.next?.title ?? '',
      'nextStart': classState.next?.startLabel ?? '',
      'dark': preset.dark,
    };
  }

  static Map<String, dynamic> _smallPayload(_AcademicDday? dday) => {
    'kind': 'academicDday',
    'available': dday != null,
    'title': dday?.title ?? '',
    'date': dday?.dateKey ?? '',
    'daysAway': dday?.daysAway ?? -1,
    'label': dday == null
        ? ''
        : dday.daysAway == 0
        ? 'D-DAY'
        : 'D-${dday.daysAway}',
  };

  static Map<String, dynamic> _eventPayload(
    _TodayEntry entry,
    List<CalendarTheme> themes,
  ) => {
    'id': entry.event.id ?? '',
    'title': entry.event.t,
    'kind': entry.kind,
    'allDay': !entry.event.hasTime,
    'start': entry.event.tm ?? '',
    'end': entry.event.te ?? '',
    'timeLabel': entry.event.hasTime ? entry.event.tm ?? '' : i18n.tr('종일'),
    'color': _eventColor(entry.event, themes),
  };

  static Map<String, dynamic> _nextClassPayload(_ClassSlot? slot) => {
    'available': slot != null,
    'title': slot?.title ?? '',
    'period': slot?.period ?? -1,
    'start': slot?.startLabel ?? '',
    'end': slot?.endLabel ?? '',
    'source': slot?.source ?? '',
  };

  static _AcademicDday? _nearestAcademic(
    DateTime now,
    Map<String, List<String>> schedule,
  ) {
    final today = DateTime(now.year, now.month, now.day);
    _AcademicDday? nearest;
    schedule.forEach((dateKey, names) {
      if (names.isEmpty) return;
      final date = DateTime.tryParse(dateKey);
      if (date == null) return;
      final day = DateTime(date.year, date.month, date.day);
      final daysAway = day.difference(today).inDays;
      if (daysAway < 0) return;
      for (final rawName in names) {
        final name = rawName.trim();
        if (name.isEmpty) continue;
        final candidate = _AcademicDday(dateKey, name, daysAway);
        if (nearest == null ||
            candidate.daysAway < nearest!.daysAway ||
            (candidate.daysAway == nearest!.daysAway &&
                candidate.title.compareTo(nearest!.title) < 0)) {
          nearest = candidate;
        }
      }
    });
    return nearest;
  }

  static List<_ClassSlot> _classSlots(
    DateTime now,
    Map<int, String> neisPeriods,
    Map<int, String> weeklyHours,
  ) {
    final slots = <_ClassSlot>[];
    final occupiedHours = <int>{};
    final periods = neisPeriods.keys.toList()..sort();
    for (final period in periods) {
      final title = neisPeriods[period]?.trim() ?? '';
      if (title.isEmpty) continue;
      final hour = _periodStartHour(period);
      occupiedHours.add(hour);
      slots.add(
        _ClassSlot(
          title: title,
          period: period,
          start: DateTime(now.year, now.month, now.day, hour),
          source: 'neis',
        ),
      );
    }
    final hours = weeklyHours.keys.toList()..sort();
    for (final hour in hours) {
      final title = weeklyHours[hour]?.trim() ?? '';
      if (title.isEmpty || occupiedHours.contains(hour)) continue;
      slots.add(
        _ClassSlot(
          title: title,
          period: _periodForHour(hour) ?? -1,
          start: DateTime(now.year, now.month, now.day, hour),
          source: 'weekly',
        ),
      );
    }
    slots.sort((a, b) => a.start.compareTo(b.start));
    return slots;
  }

  static _ClassState _classState(DateTime now, List<_ClassSlot> slots) {
    var currentIndex = -1;
    _ClassSlot? current;
    _ClassSlot? next;
    var progress = 0.0;
    var minutesRemaining = 0;
    for (var index = 0; index < slots.length; index++) {
      final slot = slots[index];
      if (!now.isBefore(slot.start) && now.isBefore(slot.end)) {
        currentIndex = index;
        current = slot;
        final total = slot.end.difference(slot.start).inSeconds;
        progress = total == 0
            ? 0
            : (now.difference(slot.start).inSeconds / total).clamp(0, 1);
        minutesRemaining = slot.end.difference(now).inMinutes;
      } else if (next == null && slot.start.isAfter(now)) {
        next = slot;
      }
    }
    return _ClassState(
      currentIndex: currentIndex,
      current: current,
      next: next,
      progress: progress,
      minutesRemaining: minutesRemaining,
    );
  }

  static int _compareTodayEntries(_TodayEntry a, _TodayEntry b) {
    if (a.event.hasTime != b.event.hasTime) return a.event.hasTime ? 1 : -1;
    final time = (a.event.tm ?? '').compareTo(b.event.tm ?? '');
    return time != 0 ? time : a.event.t.compareTo(b.event.t);
  }

  static int _periodStartHour(int period) =>
      period <= 4 ? 8 + period : 9 + period;

  static int? _periodForHour(int hour) {
    if (hour >= 9 && hour <= 12) return hour - 8;
    if (hour >= 14 && hour <= 20) return hour - 9;
    return null;
  }

  static String _eventColor(EventItem event, List<CalendarTheme> themes) {
    if (event.birthday) return '#F05995';
    if (event.academic) return '#5DCAA5';
    if (event.sport) return _hex(event.sportColor ?? 0xFF6C63FF);
    if (event.themeIds.isNotEmpty) {
      for (final theme in themes) {
        if (theme.id == event.themeIds.first) {
          return '#${theme.color.replaceAll('#', '')}';
        }
      }
    }
    return '#8B7FF5';
  }

  static String _emoji(EventItem event) {
    if (event.sport) return event.sportEmoji ?? '🏆';
    if (event.birthday) return '🎂';
    if (event.academic) return '🎓';
    return '';
  }

  static String _hex(int argb) =>
      '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  static String _hexColor(Color color, {bool includeAlpha = false}) {
    final value = color.toARGB32();
    final rgb = (value & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
    if (!includeAlpha) return '#${rgb.toUpperCase()}';
    final alpha = ((value >> 24) & 0xFF).toRadixString(16).padLeft(2, '0');
    return '#${alpha.toUpperCase()}${rgb.toUpperCase()}';
  }

  static String _hm(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  static int _byPriority(TodoItem a, TodoItem b) {
    int rank(TodoItem todo) => todo.hasPriority ? todo.priority : 99;
    final priority = rank(a).compareTo(rank(b));
    return priority != 0
        ? priority
        : (a.createdAt ?? '').compareTo(b.createdAt ?? '');
  }

  static String _label(DateTime date) =>
      '${i18nd.monthDay(date)} (${i18nd.weekdayShort(date.weekday)})';
}

class _TodayEntry {
  final EventItem event;
  final String kind;

  const _TodayEntry(this.event, this.kind);
}

class _AcademicDday {
  final String dateKey;
  final String title;
  final int daysAway;

  const _AcademicDday(this.dateKey, this.title, this.daysAway);
}

class _ClassSlot {
  final String title;
  final int period;
  final DateTime start;
  final String source;

  const _ClassSlot({
    required this.title,
    required this.period,
    required this.start,
    required this.source,
  });

  DateTime get end =>
      start.add(const Duration(minutes: WidgetBridge._periodEndMinute));
  String get startLabel => WidgetBridge._hm(start.hour, start.minute);
  String get endLabel => WidgetBridge._hm(end.hour, end.minute);

  Map<String, dynamic> toLegacyJson() => {
    'name': title,
    'start': startLabel,
    'end': endLabel,
    'color':
        WidgetBridge._jewelPalette[(period > 0 ? period - 1 : start.hour) %
            WidgetBridge._jewelPalette.length],
  };
}

class _ClassState {
  final int currentIndex;
  final _ClassSlot? current;
  final _ClassSlot? next;
  final double progress;
  final int minutesRemaining;

  const _ClassState({
    required this.currentIndex,
    required this.current,
    required this.next,
    required this.progress,
    required this.minutesRemaining,
  });
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
