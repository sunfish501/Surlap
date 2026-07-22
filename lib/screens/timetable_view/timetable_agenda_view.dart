import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/date_utils.dart' as du;
import '../../core/utils/todo_style.dart';
import '../../i18n/dates.dart' as i18nd;
import '../../i18n/strings.dart';
import '../../models/calendar_theme.dart';
import '../../models/event_item.dart';
import '../../models/todo_item.dart';
import '../../providers/events_provider.dart';
import '../../providers/neis_cache_provider.dart';
import '../../providers/recurring_events_provider.dart';
import '../../providers/recurring_provider.dart';
import '../../providers/themes_provider.dart';
import '../../providers/todos_provider.dart';
import 'quick_timetable_editor.dart';

/// Surlap v2.1 single-day schedule.
///
/// School periods, meals, weekly schedule entries, calendar events and todos
/// share one continuous 06:00-24:00 timeline.
class TimetableAgendaView extends ConsumerStatefulWidget {
  const TimetableAgendaView({super.key});

  @override
  ConsumerState<TimetableAgendaView> createState() =>
      _TimetableAgendaViewState();
}

class _TimetableAgendaViewState extends ConsumerState<TimetableAgendaView> {
  static const double _timeColumnWidth = 54;
  static const double _hourHeight = 72;
  static const int _firstMinute = 6 * 60;
  static const int _lastMinute = 24 * 60;
  static const double _timelineHeight = 18 * _hourHeight;

  static const Color _schoolColor = Color(0xFF5B7CFA);
  static const Color _mealColor = Color(0xFFF2A93B);
  static const Color _weeklyColor = Color(0xFF20A486);
  static const Color _eventColor = Color(0xFFE7658A);
  static const Color _todoColor = Color(0xFF7C5CFC);
  static const Color _darkBlockInk = Color(0xFF191525);

  late DateTime _selectedDate;
  late final ScrollController _scrollController;
  Timer? _minuteTicker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedDate = _dateOnly(_now);
    _scrollController = ScrollController();
    _minuteTicker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToFocus());
  }

  @override
  void dispose() {
    _minuteTicker?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  bool get _isToday => du.isSameDay(_selectedDate, _now);

  void _selectDate(DateTime date) {
    setState(() => _selectedDate = _dateOnly(date));
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToFocus());
  }

  void _scrollToFocus() {
    if (!_scrollController.hasClients) return;
    final focusMinute = _isToday ? _now.hour * 60 + _now.minute : 8 * 60;
    final target = ((focusMinute - _firstMinute) / 60 * _hourHeight - 112)
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(
      target,
      duration: Motion.base,
      curve: Motion.curve,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    final entries = _buildEntries(context);
    final placed = _placeEntries(entries);
    final bottomPadding = 32 + MediaQuery.paddingOf(context).bottom;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AgendaHeader(
          date: _selectedDate,
          isToday: _isToday,
          sh: sh,
          onPrevious: () =>
              _selectDate(_selectedDate.subtract(const Duration(days: 1))),
          onNext: () => _selectDate(_selectedDate.add(const Duration(days: 1))),
          onToday: () => _selectDate(DateTime.now()),
          onEdit: () => showQuickTimetableEditor(context),
        ),
        const SizedBox(height: Gap.sm),
        _CategoryLegend(sh: sh),
        const SizedBox(height: Gap.md),
        Divider(height: 1, thickness: Borders.hairline, color: sh.border),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: SizedBox(
              height: _timelineHeight,
              child: LayoutBuilder(
                builder: (context, constraints) => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _TimelineGrid(sh: sh),
                    for (final item in placed)
                      _AgendaBlock(
                        item: item,
                        availableWidth:
                            constraints.maxWidth - _timeColumnWidth - Gap.lg,
                        sh: sh,
                        now: _now,
                        selectedDate: _selectedDate,
                        onTap: item.entry.todo == null
                            ? null
                            : () => ref
                                  .read(todosProvider.notifier)
                                  .toggleDone(item.entry.todo!.id),
                      ),
                    if (_isToday &&
                        _nowMinute >= _firstMinute &&
                        _nowMinute <= _lastMinute)
                      _NowMarker(now: _now),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  int get _nowMinute => _now.hour * 60 + _now.minute;

  List<_AgendaEntry> _buildEntries(BuildContext context) {
    final key = du.toDateKey(_selectedDate);
    final dayIndex = _selectedDate.weekday - 1;
    final neis = ref.watch(neisCacheProvider);
    final weekly = ref.watch(recurringProvider);
    final localEvents = ref.watch(eventsProvider)[key] ?? const <EventItem>[];
    final recurringEvents =
        ref.watch(recurringEventsByDateProvider)[key] ?? const <EventItem>[];
    final themes = ref.watch(themesProvider);
    final todos =
        ref.watch(todosProvider).where((todo) => todo.dateKey == key).toList()
          ..sort(_sortTodos);

    final entries = <_AgendaEntry>[];
    if (_isInCurrentCacheWeek(_selectedDate)) {
      final periods = neis.timetable[dayIndex] ?? const <int, String>{};
      final sortedPeriods = periods.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      for (final period in sortedPeriods) {
        final start = period.key <= 4
            ? 8 * 60 + period.key * 60
            : 9 * 60 + period.key * 60;
        entries.add(
          _AgendaEntry(
            title: period.value.trim(),
            subtitle:
                '${period.key}교시 · ${_formatMinutes(start)}–${_formatMinutes(start + 50)}',
            startMinute: start,
            endMinute: start + 50,
            color: _schoolColor,
            kind: _AgendaKind.school,
          ),
        );
      }

      final lunch = neis.lunch[dayIndex]?.trim();
      if (lunch != null && lunch.isNotEmpty) {
        entries.add(
          _AgendaEntry(
            title: lunch.replaceAll('\n', ' · '),
            subtitle: '${tr('급식')} · 13:00–13:50',
            startMinute: 13 * 60,
            endMinute: 13 * 60 + 50,
            color: _mealColor,
            kind: _AgendaKind.meal,
          ),
        );
      }
    }

    final weeklyItems =
        (weekly[dayIndex] ?? const <int, String>{}).entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));
    for (final item in weeklyItems) {
      if (item.value.trim().isEmpty) continue;
      final start = item.key * 60;
      entries.add(
        _AgendaEntry(
          title: item.value.trim(),
          subtitle:
              '${tr('매주 반복')} · ${_formatMinutes(start)}–${_formatMinutes(start + 50)}',
          startMinute: start,
          endMinute: start + 50,
          color: _weeklyColor,
          kind: _AgendaKind.weekly,
        ),
      );
    }

    final calendarItems = <EventItem>[
      ...localEvents.where((event) => !event.isTimetable),
      ...recurringEvents.where((event) => !event.isTimetable),
    ];
    var allDaySlot = _firstMinute + 8;
    for (final event in calendarItems) {
      final parsedStart = _parseTime(event.tm);
      final start = parsedStart ?? allDaySlot;
      final parsedEnd = _parseTime(event.te);
      final end = parsedEnd != null && parsedEnd > start
          ? parsedEnd
          : start + (parsedStart == null ? 42 : 60);
      if (parsedStart == null) allDaySlot += 46;
      entries.add(
        _AgendaEntry(
          title: event.t.trim(),
          subtitle: parsedStart == null
              ? tr('종일 일정')
              : '${tr('일정')} · ${_formatMinutes(start)}–${_formatMinutes(end)}',
          startMinute: start,
          endMinute: end,
          color: _eventColorFor(event, themes),
          kind: _AgendaKind.event,
        ),
      );
    }

    var todoSlot = 18 * 60;
    for (final todo in todos) {
      entries.add(
        _AgendaEntry(
          title: todo.title,
          subtitle: todo.done
              ? tr('완료한 할 일')
              : todo.inProgress
              ? tr('진행 중인 할 일')
              : tr('오늘 할 일'),
          startMinute: todoSlot,
          endMinute: todoSlot + 40,
          color: todoStatusColor(todo.status, todo.priority, context.sh),
          kind: _AgendaKind.todo,
          todo: todo,
        ),
      );
      todoSlot += 44;
    }

    return entries
        .where(
          (entry) =>
              entry.endMinute > _firstMinute && entry.startMinute < _lastMinute,
        )
        .map((entry) => entry.clamped(_firstMinute, _lastMinute))
        .toList();
  }

  bool _isInCurrentCacheWeek(DateTime date) {
    final today = _dateOnly(DateTime.now());
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    return !date.isBefore(monday) && !date.isAfter(sunday);
  }

  static int _sortTodos(TodoItem a, TodoItem b) {
    int rank(TodoItem item) => item.hasPriority ? item.priority : 99;
    final priority = rank(a).compareTo(rank(b));
    return priority != 0
        ? priority
        : (a.createdAt ?? '').compareTo(b.createdAt ?? '');
  }

  static int? _parseTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 24 ||
        minute < 0 ||
        minute > 59 ||
        (hour == 24 && minute != 0)) {
      return null;
    }
    return hour * 60 + minute;
  }

  static String _formatMinutes(int total) {
    final safe = total.clamp(0, 24 * 60);
    final hour = safe ~/ 60;
    final minute = safe % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  Color _eventColorFor(EventItem event, List<CalendarTheme> themes) {
    if (event.sport && event.sportColor != null) {
      return Color(event.sportColor!);
    }
    for (final id in event.themeIds) {
      for (final theme in themes) {
        if (theme.id == id) return theme.colorValue;
      }
    }
    return _eventColor;
  }

  static List<_PlacedEntry> _placeEntries(List<_AgendaEntry> entries) {
    final sorted = [...entries]
      ..sort((a, b) {
        final start = a.startMinute.compareTo(b.startMinute);
        return start != 0 ? start : a.endMinute.compareTo(b.endMinute);
      });
    final result = <_PlacedEntry>[];
    var cursor = 0;
    while (cursor < sorted.length) {
      final group = <_AgendaEntry>[];
      var groupEnd = sorted[cursor].visualEndMinute;
      var end = cursor;
      while (end < sorted.length &&
          (end == cursor || sorted[end].startMinute < groupEnd)) {
        group.add(sorted[end]);
        if (sorted[end].visualEndMinute > groupEnd) {
          groupEnd = sorted[end].visualEndMinute;
        }
        end++;
      }

      final laneEnds = <int>[];
      final laneFor = <_AgendaEntry, int>{};
      for (final entry in group) {
        var lane = laneEnds.indexWhere(
          (laneEnd) => laneEnd <= entry.startMinute,
        );
        if (lane < 0) {
          lane = laneEnds.length;
          laneEnds.add(entry.visualEndMinute);
        } else {
          laneEnds[lane] = entry.visualEndMinute;
        }
        laneFor[entry] = lane;
      }
      for (final entry in group) {
        result.add(
          _PlacedEntry(
            entry: entry,
            lane: laneFor[entry]!,
            laneCount: laneEnds.length,
          ),
        );
      }
      cursor = end;
    }
    return result;
  }
}

enum _AgendaKind { school, meal, weekly, event, todo }

class _AgendaEntry {
  final String title;
  final String subtitle;
  final int startMinute;
  final int endMinute;
  final Color color;
  final _AgendaKind kind;
  final TodoItem? todo;

  const _AgendaEntry({
    required this.title,
    required this.subtitle,
    required this.startMinute,
    required this.endMinute,
    required this.color,
    required this.kind,
    this.todo,
  });

  int get visualEndMinute =>
      endMinute - startMinute < 38 ? startMinute + 38 : endMinute;

  _AgendaEntry clamped(int minimum, int maximum) => _AgendaEntry(
    title: title,
    subtitle: subtitle,
    startMinute: startMinute.clamp(minimum, maximum),
    endMinute: endMinute.clamp(minimum, maximum),
    color: color,
    kind: kind,
    todo: todo,
  );
}

class _PlacedEntry {
  final _AgendaEntry entry;
  final int lane;
  final int laneCount;

  const _PlacedEntry({
    required this.entry,
    required this.lane,
    required this.laneCount,
  });
}

class _AgendaHeader extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final SurlapColors sh;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;
  final VoidCallback onEdit;

  const _AgendaHeader({
    required this.date,
    required this.isToday,
    required this.sh,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.xs, Gap.lg, 0),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                tr('스케줄'),
                style: AppType.titleLarge.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: sh.ink,
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                key: const ValueKey('timetable_quick_edit'),
                onPressed: onEdit,
                icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                label: Text(tr('빠른 편집')),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, kMinTouch),
                  padding: const EdgeInsets.symmetric(horizontal: Gap.sm),
                  side: BorderSide(color: sh.border),
                ),
              ),
              const SizedBox(width: Gap.xs),
              _TodayChip(selected: isToday, sh: sh, onTap: onToday),
            ],
          ),
          const SizedBox(height: Gap.sm),
          Row(
            children: [
              _DateArrow(
                icon: Icons.chevron_left_rounded,
                label: tr('이전 날'),
                sh: sh,
                onTap: onPrevious,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${date.year}',
                      style: AppType.eyebrow.copyWith(color: sh.inkFaint),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      i18nd.fullDate(date),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isToday
                            ? _TimetableAgendaViewState._todoColor
                            : sh.ink,
                      ),
                    ),
                  ],
                ),
              ),
              _DateArrow(
                icon: Icons.chevron_right_rounded,
                label: tr('다음 날'),
                sh: sh,
                onTap: onNext,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateArrow extends StatelessWidget {
  final IconData icon;
  final String label;
  final SurlapColors sh;
  final VoidCallback onTap;

  const _DateArrow({
    required this.icon,
    required this.label,
    required this.sh,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: IconButton(
        onPressed: onTap,
        constraints: const BoxConstraints.tightFor(
          width: kMinTouch,
          height: kMinTouch,
        ),
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: sh.card2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.small),
            side: BorderSide(color: sh.border, width: Borders.hairline),
          ),
        ),
        icon: Icon(icon, size: 22, color: sh.ink),
      ),
    );
  }
}

class _TodayChip extends StatelessWidget {
  final bool selected;
  final SurlapColors sh;
  final VoidCallback onTap;

  const _TodayChip({
    required this.selected,
    required this.sh,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected
            ? _TimetableAgendaViewState._todoColor.withValues(alpha: 0.12)
            : sh.card2,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected
                ? _TimetableAgendaViewState._todoColor.withValues(alpha: 0.42)
                : sh.border,
            width: Borders.hairline,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: kMinTouch),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gap.md),
              child: Center(
                child: Text(
                  tr('오늘'),
                  style: AppType.bodyMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: selected
                        ? _TimetableAgendaViewState._todoColor
                        : sh.inkSoft,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryLegend extends StatelessWidget {
  final SurlapColors sh;

  const _CategoryLegend({required this.sh});

  @override
  Widget build(BuildContext context) {
    const items = [
      (_TimetableAgendaViewState._schoolColor, '수업'),
      (_TimetableAgendaViewState._mealColor, '급식'),
      (_TimetableAgendaViewState._weeklyColor, '반복'),
      (_TimetableAgendaViewState._eventColor, '일정'),
      (_TimetableAgendaViewState._todoColor, '할 일'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
      child: Wrap(
        spacing: Gap.md,
        runSpacing: Gap.xs,
        children: [
          for (final item in items)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: item.$1,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  tr(item.$2),
                  style: AppType.labelMedium.copyWith(color: sh.inkSoft),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TimelineGrid extends StatelessWidget {
  final SurlapColors sh;

  const _TimelineGrid({required this.sh});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: _TimetableAgendaViewState._timeColumnWidth,
          top: 0,
          bottom: 0,
          child: VerticalDivider(
            width: 1,
            thickness: Borders.hairline,
            color: sh.border,
          ),
        ),
        for (var hour = 6; hour <= 24; hour++) ...[
          Positioned(
            left: 0,
            right: 0,
            top: (hour - 6) * _TimetableAgendaViewState._hourHeight,
            child: Row(
              children: [
                SizedBox(
                  width: _TimetableAgendaViewState._timeColumnWidth - Gap.sm,
                  child: Text(
                    '${hour.toString().padLeft(2, '0')}:00',
                    textAlign: TextAlign.right,
                    style: AppType.labelMedium.copyWith(
                      color: sh.inkFaint,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(width: Gap.sm),
                Expanded(
                  child: Divider(
                    height: 1,
                    thickness: Borders.hairline,
                    color: sh.border,
                  ),
                ),
              ],
            ),
          ),
          if (hour < 24)
            Positioned(
              left: _TimetableAgendaViewState._timeColumnWidth + Gap.sm,
              right: 0,
              top:
                  (hour - 6) * _TimetableAgendaViewState._hourHeight +
                  _TimetableAgendaViewState._hourHeight / 2,
              child: Divider(
                height: 1,
                thickness: Borders.hairline,
                color: sh.border.withValues(alpha: 0.45),
              ),
            ),
        ],
      ],
    );
  }
}

class _AgendaBlock extends StatelessWidget {
  final _PlacedEntry item;
  final double availableWidth;
  final SurlapColors sh;
  final DateTime now;
  final DateTime selectedDate;
  final VoidCallback? onTap;

  const _AgendaBlock({
    required this.item,
    required this.availableWidth,
    required this.sh,
    required this.now,
    required this.selectedDate,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final entry = item.entry;
    const gap = 4.0;
    final laneWidth =
        (availableWidth - gap * (item.laneCount - 1)) / item.laneCount;
    final top =
        (entry.startMinute - _TimetableAgendaViewState._firstMinute) /
            60 *
            _TimetableAgendaViewState._hourHeight +
        2;
    final naturalHeight =
        (entry.endMinute - entry.startMinute) /
            60 *
            _TimetableAgendaViewState._hourHeight -
        4;
    final height = naturalHeight.clamp(kMinTouch, double.infinity);
    final left =
        _TimetableAgendaViewState._timeColumnWidth +
        Gap.sm +
        item.lane * (laneWidth + gap);
    final end = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    ).add(Duration(minutes: entry.endMinute));
    final isPast = !end.isAfter(now);
    final background = Color.lerp(entry.color, Colors.white, 0.82)!;

    return Positioned(
      left: left,
      top: top,
      width: laneWidth,
      height: height,
      child: Opacity(
        opacity: isPast ? 0.5 : 1,
        child: Material(
          color: background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.small),
            side: BorderSide(
              color: entry.color.withValues(alpha: 0.20),
              width: Borders.hairline,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(Radii.small),
            child: Container(
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: entry.color, width: 3)),
              ),
              padding: const EdgeInsets.fromLTRB(Gap.sm, 5, 6, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (entry.kind == _AgendaKind.todo) ...[
                    Icon(
                      entry.todo!.done
                          ? Icons.check_circle_rounded
                          : entry.todo!.inProgress
                          ? Icons.timelapse_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 15,
                      color: entry.color,
                    ),
                    const SizedBox(width: 5),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          maxLines: height < 54 ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.bodyMedium.copyWith(
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                            color: _TimetableAgendaViewState._darkBlockInk,
                            decoration: entry.todo?.done == true
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        if (height >= 54) ...[
                          const SizedBox(height: 2),
                          Text(
                            entry.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.labelMedium.copyWith(
                              fontSize: 10,
                              color: _TimetableAgendaViewState._darkBlockInk
                                  .withValues(alpha: 0.62),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NowMarker extends StatelessWidget {
  final DateTime now;

  const _NowMarker({required this.now});

  @override
  Widget build(BuildContext context) {
    final minutes = now.hour * 60 + now.minute;
    final top =
        (minutes - _TimetableAgendaViewState._firstMinute) /
        60 *
        _TimetableAgendaViewState._hourHeight;
    const accent = _TimetableAgendaViewState._todoColor;

    return Positioned(
      left: 4,
      right: 0,
      top: top - 11,
      height: 22,
      child: IgnorePointer(
        child: Row(
          children: [
            Container(
              height: 22,
              padding: const EdgeInsets.symmetric(horizontal: 7),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(Radii.pill),
              ),
              child: Text(
                '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                style: AppType.labelMedium.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(child: Container(height: 2, color: accent)),
          ],
        ),
      ),
    );
  }
}
