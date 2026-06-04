import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/date_utils.dart' as du;
import '../../providers/events_provider.dart';
import '../../providers/themes_provider.dart';
import '../../providers/view_provider.dart';
import '../../providers/recurring_provider.dart';
import '../../providers/todos_provider.dart';
import '../../providers/academic_schedule_provider.dart';
import '../../providers/birthdays_provider.dart';
import '../../providers/filter_provider.dart';
import '../../core/utils/todo_style.dart';
import '../../models/event_item.dart';
import '../../models/todo_item.dart';
import '../../models/calendar_theme.dart';
import '../../modals/add_edit_event_modal.dart';
import '../../modals/add_todo_modal.dart';

/// 일별 뷰 — 주간 뷰의 하루를 확대한 형태.
/// 왼쪽에 시간대(0~23시) 축을 두고, 시간 일정은 해당 시각에 블록으로 배치한다.
class DayView extends ConsumerStatefulWidget {
  final String dateKey;
  const DayView({super.key, required this.dateKey});

  @override
  ConsumerState<DayView> createState() => _DayViewState();
}

class _DayViewState extends ConsumerState<DayView> {
  static const _timeColW = 44.0;
  static const _rowH = 48.0;

  late final ScrollController _scroll;

  @override
  void initState() {
    super.initState();
    final date = du.fromDateKey(widget.dateKey);
    final now = DateTime.now();
    // 오늘이면 현재 시각 근처, 아니면 오전 7시쯤부터 보이게.
    final startHour = du.isSameDay(date, now)
        ? (now.hour - 1).clamp(0, 20)
        : 7;
    _scroll = ScrollController(initialScrollOffset: startHour * _rowH);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    final events = ref.watch(eventsProvider);
    final themes = ref.watch(themesProvider);
    final date = du.fromDateKey(widget.dateKey);
    final items = events[widget.dateKey] ?? [];
    final now = DateTime.now();
    final isToday = du.isSameDay(date, now);

    final filter = ref.watch(filterProvider);
    final allDay = [
      ...items.where((e) => !e.hasTime && !e.isTimetable),
      // 생일(별도 카테고리)
      if (!filter.contains(birthdayThemeId))
        ...ref
            .watch(birthdaysProvider)
            .where((b) => b.month == date.month && b.day == date.day)
            .map((b) =>
                EventItem(t: b.name, th: birthdayThemeId, birthday: true)),
      // NEIS 학사일정(읽기 전용, 별도 카테고리)
      if (!filter.contains(academicThemeId))
        ...(ref.watch(academicScheduleProvider)[widget.dateKey] ?? const [])
            .map((n) =>
                EventItem(t: n, th: academicThemeId, academic: true)),
    ];
    final timed = items.where((e) => e.hasTime && !e.isTimetable).toList()
      ..sort((a, b) => (a.tm ?? '').compareTo(b.tm ?? ''));
    final dayTodos = ref
        .watch(todosProvider)
        .where((t) => t.dateKey == widget.dateKey)
        .toList()
      ..sort((a, b) {
        int rank(TodoItem t) => t.hasPriority ? t.priority : 99;
        final r = rank(a).compareTo(rank(b));
        return r != 0 ? r : (a.createdAt ?? '').compareTo(b.createdAt ?? '');
      });
    // 이 날짜의 요일에 해당하는 반복 일정(시간표 탭에서 작성).
    final recurringForDay =
        ref.watch(recurringProvider)[weekdayIndex(date)] ?? const {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 날짜 헤더
        Padding(
          padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.sm, Gap.xl, Gap.sm),
          child: Row(
            children: [
              GestureDetector(
                onTap: () =>
                    ref.read(viewProvider.notifier).setMode(ViewMode.events),
                child: Icon(Icons.arrow_back_ios_rounded,
                    size: 16, color: sh.inkSoft),
              ),
              const SizedBox(width: Gap.md),
              Text(
                '${date.month}월 ${date.day}일',
                style: AppType.title.copyWith(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: sh.ink),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  _dowName(date.weekday),
                  style: AppType.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isToday ? sh.accent : sh.inkSoft),
                ),
              ),
              const Spacer(),
              // 추가 — soft accent 원형 버튼(일정/할 일 선택).
              GestureDetector(
                onTap: _showAddChooser,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: sh.accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add_rounded, size: 20, color: sh.accent),
                ),
              ),
            ],
          ),
        ),
        // 종일 일정
        if (allDay.isNotEmpty) _AllDayBar(items: allDay, themes: themes, sh: sh),
        // 할 일
        if (dayTodos.isNotEmpty)
          _TodoBar(
            todos: dayTodos,
            sh: sh,
            onToggle: (id) => ref.read(todosProvider.notifier).toggleDone(id),
            onTapTodo: (t) => showAddTodoModal(context, edit: t),
          ),
        // 시간 축 + 하루 타임라인
        Expanded(
          child: LayoutBuilder(builder: (context, constraints) {
            final dayColW = constraints.maxWidth - _timeColW;
            return SingleChildScrollView(
              controller: _scroll,
              padding: const EdgeInsets.only(bottom: 110),
              child: SizedBox(
                height: _rowH * 24,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 시간 레이블 컬럼
                    SizedBox(
                      width: _timeColW,
                      child: Column(
                        children: List.generate(24, (h) {
                          return SizedBox(
                            height: _rowH,
                            child: Align(
                              alignment: Alignment.topRight,
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(right: 6, top: 2),
                                child: Text(
                                  h == 0 ? '' : '$h:00',
                                  style: TextStyle(
                                      fontSize: 10, color: sh.inkFaint),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    // 하루 컬럼
                    Expanded(
                      child: Stack(
                        children: [
                          // 시간 그리드 (탭하면 일정 추가)
                          GestureDetector(
                            onTapDown: (_) => showAddEditEventModal(context,
                                dateKey: widget.dateKey),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  left:
                                      BorderSide(color: sh.border, width: 0.5),
                                ),
                              ),
                              child: Column(
                                children: List.generate(
                                  24,
                                  (h) => Container(
                                    height: _rowH,
                                    decoration: BoxDecoration(
                                      border: Border(
                                        top: BorderSide(
                                            color: sh.border, width: 0.5),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // 반복 일정(시간표 탭에서 작성) — 해당 요일에만 표시
                          ..._recurringBlocks(recurringForDay, dayColW, sh),
                          // 시간 일정 블록
                          ..._eventBlocks(timed, dayColW, themes, sh, events),
                          // 현재 시각 선
                          if (isToday)
                            _NowLine(
                                hour: now.hour, minute: now.minute, rowH: _rowH, sh: sh),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // 반복 일정 블록 — soft tint + 반복 아이콘으로 일반 일정과 구분.
  List<Widget> _recurringBlocks(
      Map<int, String> byHour, double colW, SpaceHourColors sh) {
    final blocks = <Widget>[];
    byHour.forEach((hour, title) {
      blocks.add(Positioned(
        top: hour * _rowH + 1,
        left: 4,
        right: 6,
        height: _rowH - 2,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: Gap.sm, vertical: Gap.xs),
          decoration: BoxDecoration(
            color: sh.accent.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(8),
            border: Border(
                left: BorderSide(
                    color: sh.accent.withValues(alpha: 0.5), width: 3)),
          ),
          child: Row(
            children: [
              Icon(Icons.repeat_rounded, size: 12, color: sh.accent),
              const SizedBox(width: 4),
              Expanded(
                child: Text(title,
                    style: AppType.caption.copyWith(
                        fontWeight: FontWeight.w600, color: sh.accentInk),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ));
    });
    return blocks;
  }

  List<Widget> _eventBlocks(
    List<EventItem> timed,
    double colW,
    List<CalendarTheme> themes,
    SpaceHourColors sh,
    Map<String, List<EventItem>> events,
  ) {
    final blocks = <Widget>[];
    for (final e in timed) {
      final parts = e.tm!.split(':');
      final h = int.tryParse(parts[0]) ?? 0;
      final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      final top = h * _rowH + m * _rowH / 60;
      double height = _rowH;
      if (e.te != null && e.te!.contains(':')) {
        final ep = e.te!.split(':');
        final eh = int.tryParse(ep[0]) ?? h;
        final em = int.tryParse(ep[1]) ?? m;
        height = ((eh - h) * 60 + (em - m)) * _rowH / 60;
      }
      final thColor = e.themeIds.isNotEmpty
          ? themes
              .firstWhere(
                (t) => e.themeIds.contains(t.id),
                orElse: () =>
                    const CalendarTheme(id: '', name: '', color: '#6b8ec2'),
              )
              .colorValue
          : sh.accent;

      blocks.add(Positioned(
        top: top,
        left: 4,
        right: 6,
        height: height.clamp(20.0, double.infinity),
        child: GestureDetector(
          onTap: () {
            final idx = (events[widget.dateKey] ?? []).indexOf(e);
            showAddEditEventModal(context,
                dateKey: widget.dateKey, editIndex: idx);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: Gap.sm, vertical: Gap.xs),
            decoration: BoxDecoration(
              color: thColor.withValues(alpha: sh.dark ? 0.20 : 0.16),
              borderRadius: BorderRadius.circular(8),
              border: Border(left: BorderSide(color: thColor, width: 3)),
              boxShadow: sh.dark
                  ? [BoxShadow(
                      color: thColor.withValues(alpha: 0.22),
                      blurRadius: 10, spreadRadius: 0,
                      offset: const Offset(0, 1),
                    )]
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${e.tm} ',
                    style: TextStyle(
                        fontSize: 10,
                        color: sh.inkSoft,
                        fontWeight: FontWeight.w600)),
                Expanded(
                  child: Text(
                    e.t,
                    style: AppType.caption.copyWith(
                        fontWeight: FontWeight.w500, color: sh.ink),
                    maxLines: height > _rowH ? 3 : 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ));
    }
    return blocks;
  }

  String _dowName(int w) => ['월', '화', '수', '목', '금', '토', '일'][w - 1];

  // + 버튼 → 일정/할 일 선택.
  void _showAddChooser() {
    final sh = context.sh;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        color: sh.card,
        padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, Gap.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.event_rounded, color: sh.accent),
              title: Text('일정 추가', style: AppType.body.copyWith(color: sh.ink)),
              onTap: () {
                Navigator.pop(ctx);
                showAddEditEventModal(context, dateKey: widget.dateKey);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading:
                  Icon(Icons.check_circle_outline_rounded, color: sh.accent),
              title: Text('할 일 추가', style: AppType.body.copyWith(color: sh.ink)),
              onTap: () {
                Navigator.pop(ctx);
                showAddTodoModal(context, dateKey: widget.dateKey);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 할 일 바 ────────────────────────────────────────────────────
class _TodoBar extends StatelessWidget {
  final List<TodoItem> todos;
  final SpaceHourColors sh;
  final void Function(String id) onToggle;
  final void Function(TodoItem) onTapTodo;
  const _TodoBar(
      {required this.todos,
      required this.sh,
      required this.onToggle,
      required this.onTapTodo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(Gap.xl, 0, Gap.xl, Gap.sm),
      padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.sm),
      decoration: BoxDecoration(
        color: sh.card2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: sh.ink.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('할 일 (${todos.length})',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: sh.inkSoft,
                  letterSpacing: 0.4)),
          const SizedBox(height: 4),
          ...todos.map((t) {
            final c = todoPriorityColor(t.priority, sh);
            return InkWell(
              onTap: () => onTapTodo(t),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => onToggle(t.id),
                      child: Icon(
                        t.done
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 18,
                        color: t.done ? sh.accent : c,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (t.hasPriority) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: c.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text('P${t.priority}',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: c)),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        t.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.body.copyWith(
                          color: t.done ? sh.inkFaint : sh.ink,
                          decoration:
                              t.done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _AllDayBar extends StatelessWidget {
  final List<EventItem> items;
  final List<CalendarTheme> themes;
  final SpaceHourColors sh;
  const _AllDayBar(
      {required this.items, required this.themes, required this.sh});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(Gap.xl, 0, Gap.xl, Gap.sm),
      padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.sm),
      decoration: BoxDecoration(
        color: sh.accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: sh.accent.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('종일',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: sh.inkSoft,
                  letterSpacing: 0.4)),
          const SizedBox(height: 2),
          ...items.map((e) {
            final tinted = e.birthday || e.academic;
            final c = e.birthday ? sh.birthdayColor : sh.academicColor;
            final icon =
                e.birthday ? Icons.cake_rounded : Icons.school_rounded;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: tinted
                  ? Row(children: [
                      Icon(icon, size: 14, color: c),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(e.t,
                            style: AppType.body.copyWith(
                                color: c, fontWeight: FontWeight.w600)),
                      ),
                    ])
                  : Text(e.t, style: AppType.body.copyWith(color: sh.ink)),
            );
          }),
        ],
      ),
    );
  }
}

class _NowLine extends StatelessWidget {
  final int hour, minute;
  final double rowH;
  final SpaceHourColors sh;
  const _NowLine(
      {required this.hour,
      required this.minute,
      required this.rowH,
      required this.sh});

  @override
  Widget build(BuildContext context) {
    final top = hour * rowH + minute * rowH / 60;
    return Positioned(
      top: top - 1,
      left: 0,
      right: 0,
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: sh.danger,
              shape: BoxShape.circle,
              boxShadow: sh.dark
                  ? [BoxShadow(
                      color: sh.danger.withValues(alpha: 0.5),
                      blurRadius: 6, spreadRadius: 1,
                    )]
                  : null,
            ),
          ),
          Expanded(
            child: Container(
              height: 1.5,
              decoration: BoxDecoration(
                color: sh.danger.withValues(alpha: 0.7),
                boxShadow: sh.dark
                    ? [BoxShadow(
                        color: sh.danger.withValues(alpha: 0.4),
                        blurRadius: 4, spreadRadius: 1,
                      )]
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
