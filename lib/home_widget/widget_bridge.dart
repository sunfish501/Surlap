import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import '../core/utils/date_utils.dart' as du;
import '../i18n/strings.dart' as i18n;
import '../i18n/dates.dart' as i18nd;
import '../models/calendar_theme.dart';
import '../models/event_item.dart';
import '../models/todo_item.dart';
import '../providers/academic_schedule_provider.dart';
import '../providers/birthdays_provider.dart';
import '../providers/events_provider.dart';
import '../providers/filter_provider.dart';
import '../providers/shared_theme_events_provider.dart';
import '../providers/sports_provider.dart';
import '../providers/themes_provider.dart';
import '../providers/todos_provider.dart';

class WidgetBridge {
  static const appGroupId = 'group.com.spacehour.spacehour';
  static const iosWidgetName = 'HourSpaceWidget';
  static const androidWidgetName = 'HourSpaceWidgetProvider';
  static const dataKey = 'hs_widget';

  static const _maxAllDay = 6;
  static const _maxTimed = 8;
  static const _maxTodos = 6;

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
      await HomeWidget.updateWidget(
        iOSName: iosWidgetName,
        androidName: androidWidgetName,
      );
    } catch (_) {
      // 위젯 동기화 실패는 앱 동작에 영향 주지 않도록 무시
    }
  }

  static Map<String, dynamic> _build(WidgetRef ref) {
    final now = DateTime.now();
    final today = du.todayKey();
    final nowHM = _hm(now.hour, now.minute);

    final themes = ref.read(themesProvider);
    final filter = ref.read(filterProvider);

    final stored = ref.read(eventsProvider)[today] ?? const <EventItem>[];
    final shared =
        ref.read(sharedThemeEventsByDateProvider)[today] ?? const <EventItem>[];
    final sports =
        ref.read(sportsEventsByDateProvider)[today] ?? const <EventItem>[];
    final births = ref.read(birthdaysProvider).where(
        (b) => b.month == now.month && b.day == now.day);
    final academic = ref.read(academicScheduleProvider)[today] ?? const [];

    bool sharedVisible(EventItem e) =>
        e.themeIds.isNotEmpty && !filter.contains(e.themeIds.first);
    bool sportVisible(EventItem e) =>
        e.themeIds.isEmpty || !filter.contains(e.themeIds.first);

    // 종일 이벤트 (위)
    final allDay = <EventItem>[
      ...stored.where((e) => !e.hasTime && !e.isTimetable),
      ...shared.where((e) => !e.hasTime && sharedVisible(e)),
      if (!filter.contains(birthdayThemeId))
        ...births.map((b) =>
            EventItem(t: b.name, th: birthdayThemeId, birthday: true)),
      if (!filter.contains(academicThemeId))
        ...academic.map((n) =>
            EventItem(t: n, th: academicThemeId, academic: true)),
    ];

    // 시간 있는 이벤트 (스포츠 포함), 시작시간 정렬
    final timed = <EventItem>[
      ...stored.where((e) => e.hasTime && !e.isTimetable),
      ...sports.where(sportVisible),
      ...shared.where((e) => e.hasTime && sharedVisible(e)),
    ]..sort((a, b) => (a.tm ?? '').compareTo(b.tm ?? ''));

    // 현재 시각 기준 가장 가까운 다음 이벤트 index
    int nextIndex = -1;
    for (var i = 0; i < timed.length; i++) {
      if ((timed[i].tm ?? '').compareTo(nowHM) >= 0) {
        nextIndex = i;
        break;
      }
    }

    final todos = ref
        .read(todosProvider)
        .where((t) => t.dateKey == today)
        .toList()
      ..sort(_byPriority);

    return {
      'date': today,
      'lang': i18n.currentLang.name, // 위젯 네이티브가 정적 라벨 번역에 사용 가능
      'dateLabel': _label(now),
      'weekday': now.weekday, // 1=월 .. 7=일
      'nowHM': nowHM,
      'nextIndex': nextIndex,
      'todoCount': todos.length,
      'todoDone': todos.where((t) => t.done).length,
      'eventCount': allDay.length + timed.length,
      'allDay': allDay
          .take(_maxAllDay)
          .map((e) => {
                'title': e.t,
                'color': _color(e, themes),
                'emoji': _emoji(e),
              })
          .toList(),
      'timed': timed
          .take(_maxTimed)
          .map((e) => {
                'title': e.t,
                'time': e.tm ?? '',
                'end': e.te ?? '',
                'color': _color(e, themes),
                'emoji': _emoji(e),
                'sport': e.sport,
              })
          .toList(),
      'todos': todos
          .take(_maxTodos)
          .map((t) =>
              {'title': t.title, 'done': t.done, 'priority': t.priority})
          .toList(),
    };
  }

  static String _color(EventItem e, List<CalendarTheme> themes) {
    if (e.birthday) return '#F05995';
    if (e.academic) return '#5DCAA5';
    if (e.sport) return _hex(e.sportColor ?? 0xFF6C63FF);
    final ids = e.themeIds;
    if (ids.isNotEmpty) {
      for (final t in themes) {
        if (t.id == ids.first) {
          final c = t.color.replaceAll('#', '');
          return '#$c';
        }
      }
    }
    return '#8B7FF5';
  }

  static String _emoji(EventItem e) {
    if (e.sport) return e.sportEmoji ?? '🏆';
    if (e.birthday) return '🎂';
    if (e.academic) return '📚';
    return '';
  }

  static String _hex(int argb) =>
      '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  static String _hm(int h, int m) =>
      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

  static int _byPriority(TodoItem a, TodoItem b) {
    int rank(TodoItem t) => t.hasPriority ? t.priority : 99;
    final r = rank(a).compareTo(rank(b));
    if (r != 0) return r;
    return (a.createdAt ?? '').compareTo(b.createdAt ?? '');
  }

  static String _label(DateTime d) =>
      '${i18nd.monthDay(d)} (${i18nd.weekdayShort(d.weekday)})';
}
