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
import '../providers/recurring_provider.dart';
import '../providers/shared_theme_events_provider.dart';
import '../providers/sports_provider.dart';
import '../providers/themes_provider.dart';
import '../providers/todos_provider.dart';
import '../providers/user_type_provider.dart';

class WidgetBridge {
  // 기존 iOS App Group / 위젯 ext 타깃 이름 유지(pbxproj 등록값과 일치 필수).
  // 새 이름으로 바꾸려면 Xcode 에서 타깃·entitlements 도 함께 갱신해야 위젯이 살아남.
  static const appGroupId = 'group.com.kev208dev.Surlap';
  static const iosWidgetName = 'SurlapWidget';
  static const androidWidgetName = 'SurlapWidgetProvider';
  static const dataKey = 'hs_widget';

  static const _maxAllDay = 6;
  static const _maxTimed = 8;
  static const _maxTodos = 6;

  // 시간표 교시 → 시작 시각(시간 정수) 매핑. timetable_view.dart 와 동일 규칙:
  //   1~4교시: 9, 10, 11, 12시 (8 + period)
  //   5~8교시: 14, 15, 16, 17시 (9 + period, 점심 13시 갭)
  static int _periodStartHour(int p) => p <= 4 ? 8 + p : 9 + p;
  static const _periodEndMinute = 50; // 교시 마치는 분(쉬는 시간 10분 가정)

  // 위젯 교시 세그먼트 주얼톤 (없을 때 폴백 — iOS/Android 양쪽 동일 팔레트).
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
      // Surlap Now/Next 카드를 위한 평탄화 키들도 함께 저장 — 위젯 네이티브가
      // 한 JSON 파싱 없이도 빠르게 읽을 수 있게(Android Glance/iOS UserDefaults 공용).
      await _saveFlatKeys(payload);
      await HomeWidget.updateWidget(
        iOSName: iosWidgetName,
        androidName: androidWidgetName,
      );
    } catch (_) {
      // 위젯 동기화 실패는 앱 동작에 영향 없도록 무시.
    }
  }

  static Future<void> _saveFlatKeys(Map<String, dynamic> p) async {
    await HomeWidget.saveWidgetData<String>('today', p['dateLabel'] as String? ?? '');
    await HomeWidget.saveWidgetData<String>('schoolClass', p['schoolClass'] as String? ?? '');
    await HomeWidget.saveWidgetData<String>('periods', jsonEncode(p['periods'] ?? const []));
    await HomeWidget.saveWidgetData<int>('currentIndex', (p['currentIndex'] as int?) ?? -1);
    await HomeWidget.saveWidgetData<double>('progress', (p['progress'] as num?)?.toDouble() ?? 0.0);
    await HomeWidget.saveWidgetData<int>('minutesRemaining', (p['minutesRemaining'] as int?) ?? 0);
    await HomeWidget.saveWidgetData<String>('nowName', p['nowName'] as String? ?? '');
    await HomeWidget.saveWidgetData<String>('nowStart', p['nowStart'] as String? ?? '');
    await HomeWidget.saveWidgetData<String>('nowEnd', p['nowEnd'] as String? ?? '');
    await HomeWidget.saveWidgetData<String>('nextName', p['nextName'] as String? ?? '');
    await HomeWidget.saveWidgetData<String>('nextStart', p['nextStart'] as String? ?? '');
    await HomeWidget.saveWidgetData<String>('accent', '#A98BFF');
    await HomeWidget.saveWidgetData<String>('theme', p['dark'] == true ? 'dark' : 'light');
  }

  static Map<String, dynamic> _build(WidgetRef ref) {
    final now = DateTime.now();
    final today = du.todayKey();
    final nowHM = _hm(now.hour, now.minute);

    final themes = ref.read(themesProvider);
    final filter = ref.read(filterProvider);
    final recurring = ref.read(recurringProvider);

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

    final timed = <EventItem>[
      ...stored.where((e) => e.hasTime && !e.isTimetable),
      ...sports.where(sportVisible),
      ...shared.where((e) => e.hasTime && sharedVisible(e)),
    ]..sort((a, b) => (a.tm ?? '').compareTo(b.tm ?? ''));

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

    // ── 오늘 교시 추출(Now/Next 카드) ─────────────────────────────
    // recurring: weekday(0=월..6=일) → hour → 과목명. 오늘 요일의 교시 1..7
    // 을 모아 시작/종료 시각 계산.
    final dowIdx = (now.weekday - 1).clamp(0, 6);
    final todayCol = recurring[dowIdx] ?? const <int, String>{};
    final periods = <Map<String, dynamic>>[];
    int currentPeriod = -1;
    int minutesRemaining = 0;
    double progress = 0;
    String nowName = '', nowStart = '', nowEnd = '';
    String nextName = '', nextStart = '';

    for (var p = 1; p <= 7; p++) {
      final h = _periodStartHour(p);
      final name = todayCol[h];
      if (name == null || name.trim().isEmpty) continue;
      final start = DateTime(now.year, now.month, now.day, h, 0);
      final end = DateTime(now.year, now.month, now.day, h, _periodEndMinute);
      final color = _jewelPalette[(p - 1) % _jewelPalette.length];
      periods.add({
        'name': name,
        'start': _hm(h, 0),
        'end': _hm(h, _periodEndMinute),
        'color': color,
      });
      if (now.isAfter(start) && now.isBefore(end) && currentPeriod < 0) {
        currentPeriod = periods.length - 1;
        nowName = name;
        nowStart = _hm(h, 0);
        nowEnd = _hm(h, _periodEndMinute);
        minutesRemaining = end.difference(now).inMinutes;
        final totalSec = end.difference(start).inSeconds;
        progress = totalSec == 0
            ? 0
            : (now.difference(start).inSeconds / totalSec).clamp(0.0, 1.0);
      } else if (currentPeriod >= 0 && nextName.isEmpty) {
        nextName = name;
        nextStart = _hm(h, 0);
      } else if (currentPeriod < 0 && now.isBefore(start) && nextName.isEmpty) {
        nextName = name;
        nextStart = _hm(h, 0);
      }
    }
    // 만약 진행 중 교시가 없으면 nowName 은 비워두되, 가장 가까운 미래 = next.
    // 추가로 next 가 비어 있으면 마지막 교시도 끝났다는 뜻 → 비워둠.

    final userType = ref.read(userTypeProvider);
    final classLabel =
        userType?.usesMeal == true ? i18n.tr('오늘 시간표') : i18n.tr('오늘');

    return {
      'date': today,
      'lang': i18n.currentLang.name,
      'dateLabel': _label(now),
      'schoolClass': classLabel,
      'weekday': now.weekday,
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
      // ── Surlap Now/Next 카드 ─────────────────────────────────
      'periods': periods,
      'currentIndex': currentPeriod,
      'progress': progress,
      'minutesRemaining': minutesRemaining,
      'nowName': nowName,
      'nowStart': nowStart,
      'nowEnd': nowEnd,
      'nextName': nextName,
      'nextStart': nextStart,
      'dark': false,
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
