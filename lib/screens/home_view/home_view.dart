import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/date_utils.dart' as du;
import '../../core/utils/todo_style.dart';
import '../../i18n/dates.dart' as i18nd;
import '../../i18n/strings.dart';
import '../../modals/add_edit_event_modal.dart';
import '../../modals/add_todo_modal.dart';
import '../../modals/event_detail_sheet.dart';
import '../../models/calendar_theme.dart';
import '../../models/event_item.dart';
import '../../models/todo_item.dart';
import '../../providers/academic_schedule_provider.dart';
import '../../providers/birthdays_provider.dart';
import '../../providers/events_provider.dart';
import '../../providers/filter_provider.dart';
import '../../providers/neis_cache_provider.dart';
import '../../providers/recurring_events_provider.dart';
import '../../providers/recurring_provider.dart';
import '../../providers/shared_theme_events_provider.dart';
import '../../providers/sports_provider.dart';
import '../../providers/themes_provider.dart';
import '../../providers/todos_provider.dart';
import '../../providers/view_provider.dart';
import '../../supabase/neis_service.dart';
import '../../widgets/pressable.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  SchoolMeals? _meals;
  bool _mealLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadMeal();
  }

  Future<void> _loadMeal() async {
    final school = NeisSchool.load();
    if (school == null) {
      if (mounted) setState(() => _mealLoaded = true);
      return;
    }

    if (mounted) {
      setState(() {
        _meals = null;
        _mealLoaded = false;
      });
    }

    final date = du.toDateKey(DateTime.now()).replaceAll('-', '');
    try {
      final meals = await fetchMeals(school, date);
      if (!mounted) return;
      setState(() {
        _meals = meals;
        _mealLoaded = true;
      });
    } catch (error, stackTrace) {
      debugPrint('[Home] meal fetch failed: $error\n$stackTrace');
      if (mounted) setState(() => _mealLoaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayKey = du.toDateKey(now);
    final notifier = ref.read(viewProvider.notifier);

    final hiddenThemes = ref.watch(filterProvider);
    bool eventIsVisible(EventItem event) {
      final themeIds = event.themeIds;
      if (themeIds.isEmpty) return !hiddenThemes.contains('__none__');
      return themeIds.every((id) => !hiddenThemes.contains(id));
    }

    final storedEvents = ref.watch(eventsProvider);
    final storedToday = (storedEvents[todayKey] ?? const <EventItem>[]).where(
      (event) => !event.isTimetable && eventIsVisible(event),
    );
    final recurringEvents =
        ref.watch(recurringEventsByDateProvider)[todayKey] ?? const [];
    final sharedEvents =
        ref.watch(sharedThemeEventsByDateProvider)[todayKey] ?? const [];
    final sportsEvents =
        ref.watch(sportsEventsByDateProvider)[todayKey] ?? const [];
    final birthdays = hiddenThemes.contains(birthdayThemeId)
        ? const <EventItem>[]
        : ref
              .watch(birthdaysProvider)
              .where(
                (birthday) =>
                    birthday.month == now.month && birthday.day == now.day,
              )
              .map(
                (birthday) => EventItem(
                  t: birthday.name,
                  th: birthdayThemeId,
                  birthday: true,
                ),
              );
    final academicEvents = hiddenThemes.contains(academicThemeId)
        ? const <EventItem>[]
        : (ref.watch(academicScheduleProvider)[todayKey] ?? const <String>[])
              .map(
                (name) =>
                    EventItem(t: name, th: academicThemeId, academic: true),
              );
    final todayEvents =
        <EventItem>[
          ...storedToday,
          ...recurringEvents.where(eventIsVisible),
          ...sharedEvents.where(eventIsVisible),
          ...sportsEvents.where(eventIsVisible),
          ...birthdays,
          ...academicEvents,
        ]..sort((a, b) {
          if (a.hasTime != b.hasTime) return a.hasTime ? 1 : -1;
          final time = (a.tm ?? '').compareTo(b.tm ?? '');
          return time != 0 ? time : a.t.compareTo(b.t);
        });

    final dueTodos =
        ref
            .watch(todosProvider)
            .where((todo) => todo.dateKey == todayKey && !todo.done)
            .toList()
          ..sort(_compareTodos);

    final school = NeisSchool.load();
    final isSchoolDay =
        now.weekday >= DateTime.monday && now.weekday <= DateTime.friday;
    final neis = ref.watch(neisCacheProvider);
    final cachedMeal = isSchoolDay ? neis.lunch[now.weekday - 1] : null;
    final meals =
        _meals ?? (cachedMeal == null ? null : SchoolMeals(lunch: cachedMeal));
    final mealMenu = _mealMenu(meals);
    final showMeal =
        school != null &&
        isSchoolDay &&
        (_mealLoaded || cachedMeal != null) &&
        mealMenu != null;

    final weekly = ref.watch(recurringProvider);
    final nextClass = school == null || !isSchoolDay
        ? null
        : _findNextClass(
            now,
            neis.timetable[now.weekday - 1] ?? const {},
            weekly[now.weekday - 1] ?? const {},
          );

    final themes = ref.watch(themesProvider);
    final highlight = hiddenThemes.contains(academicThemeId)
        ? null
        : ref.watch(nextAcademicHighlightProvider);
    final cards = <Widget>[
      if (highlight != null)
        _DDayCard(
          highlight: highlight,
          onTap: () => notifier.setDayView(highlight.dateKey),
        ),
      if (dueTodos.isNotEmpty)
        _TodayTodosCard(
          todos: dueTodos,
          onPlannerTap: () => notifier.setWeekView(todayKey),
          onToggle: (todo) =>
              ref.read(todosProvider.notifier).toggleDone(todo.id),
          onTodoTap: (todo) => showAddTodoModal(context, edit: todo),
        ),
      if (todayEvents.isNotEmpty)
        _TodayEventsCard(
          events: todayEvents,
          themes: themes,
          onHeaderTap: () => notifier.setDayView(todayKey),
          onEventTap: (event) =>
              _openEvent(context, event, storedEvents[todayKey] ?? const []),
        ),
      if (dueTodos.isEmpty && todayEvents.isEmpty)
        _HomeEmptyState(
          onAddTodo: () => showAddTodoModal(context, dateKey: todayKey),
          onAddEvent: () => showAddEditEventModal(context, dateKey: todayKey),
        ),
      if (showMeal)
        _MealCard(
          menu: mealMenu,
          onTap: () => notifier.setMode(ViewMode.timetable),
        ),
      if (nextClass != null)
        _NextClassCard(
          nextClass: nextClass,
          school: school!,
          onTap: () => notifier.setMode(ViewMode.timetable),
        ),
    ];

    final bottomPadding = 88.0 + MediaQuery.paddingOf(context).bottom;
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, bottomPadding),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              if (index.isOdd) return const SizedBox(height: _cardGap);
              return cards[index ~/ 2];
            }, childCount: cards.isEmpty ? 0 : cards.length * 2 - 1),
          ),
        ),
      ],
    );
  }

  void _openEvent(
    BuildContext context,
    EventItem event,
    List<EventItem> stored,
  ) {
    final index = stored.indexWhere(
      (item) =>
          identical(item, event) || (event.id != null && item.id == event.id),
    );
    if (index >= 0 && !event.academic && !event.birthday && !event.sport) {
      showAddEditEventModal(
        context,
        dateKey: du.toDateKey(DateTime.now()),
        editIndex: index,
      );
      return;
    }
    showEventDetailSheet(context, event);
  }
}

const double _cardGap = 10;

int _compareTodos(TodoItem a, TodoItem b) {
  int rank(TodoItem todo) => todo.hasPriority ? todo.priority : 99;
  final priority = rank(a).compareTo(rank(b));
  return priority != 0
      ? priority
      : (a.createdAt ?? '').compareTo(b.createdAt ?? '');
}

String? _mealMenu(SchoolMeals? meals) {
  final menu = meals?.lunch ?? meals?.breakfast ?? meals?.dinner;
  if (menu == null) return null;
  final items = menu
      .split(RegExp(r'[\n*]'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
  return items.isEmpty ? null : items.join(' · ');
}

_NextClass? _findNextClass(
  DateTime now,
  Map<int, String> neisPeriods,
  Map<int, String> weeklyHours,
) {
  final subjects = <int, String>{...neisPeriods};
  for (final entry in weeklyHours.entries) {
    final period = _periodForHour(entry.key);
    if (period != null && entry.value.trim().isNotEmpty) {
      subjects.putIfAbsent(period, () => entry.value.trim());
    }
  }

  final periods = subjects.keys.toList()..sort();
  for (final period in periods) {
    final hour = _periodStartHour(period);
    final start = DateTime(now.year, now.month, now.day, hour);
    if (start.isBefore(now)) continue;
    return _NextClass(
      period: period,
      subject: subjects[period]!,
      startHour: hour,
    );
  }
  return null;
}

int _periodStartHour(int period) => period <= 4 ? 8 + period : 9 + period;

int? _periodForHour(int hour) {
  if (hour >= 9 && hour <= 12) return hour - 8;
  if (hour >= 14 && hour <= 20) return hour - 9;
  return null;
}

class _NextClass {
  final int period;
  final String subject;
  final int startHour;

  const _NextClass({
    required this.period,
    required this.subject,
    required this.startHour,
  });
}

class _CardSurface extends StatelessWidget {
  final Widget child;
  final Color? color;
  final VoidCallback? onTap;

  const _CardSurface({required this.child, this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color ?? sh.card,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: sh.border, width: Borders.hairline),
      ),
      child: child,
    );
    return onTap == null ? card : Pressable(onTap: onTap, child: card);
  }
}

class _DDayCard extends StatelessWidget {
  final AcademicHighlight highlight;
  final VoidCallback onTap;

  const _DDayCard({required this.highlight, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    final date = DateTime.tryParse(highlight.dateKey);
    final dDay = highlight.daysAway == 0 ? 'D-Day' : 'D-${highlight.daysAway}';

    return Pressable(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: sh.card,
          borderRadius: BorderRadius.circular(Radii.card),
          border: Border.all(color: sh.border, width: Borders.hairline),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 3, color: sh.danger),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              highlight.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppType.titleMedium.copyWith(
                                color: sh.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: Gap.xs),
                            Text(
                              '${date == null ? highlight.dateKey : i18nd.monthDay(date)} · ${tr('시험')}',
                              style: AppType.bodySmall.copyWith(
                                color: sh.inkSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: Gap.md),
                      Text(
                        dDay,
                        style: AppType.number.copyWith(
                          color: sh.danger,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayTodosCard extends StatelessWidget {
  final List<TodoItem> todos;
  final VoidCallback onPlannerTap;
  final void Function(TodoItem) onToggle;
  final void Function(TodoItem) onTodoTap;

  const _TodayTodosCard({
    required this.todos,
    required this.onPlannerTap,
    required this.onToggle,
    required this.onTodoTap,
  });

  @override
  Widget build(BuildContext context) {
    return _CardSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: '${tr('오늘 할 일')} ${todos.length}',
            trailing: _NavigationChip(label: tr('플래너'), onTap: onPlannerTap),
          ),
          const SizedBox(height: Gap.sm),
          for (var index = 0; index < todos.length; index++) ...[
            if (index > 0) const Divider(height: 1, indent: kMinTouch),
            _TodoRow(
              todo: todos[index],
              onToggle: () => onToggle(todos[index]),
              onTap: () => onTodoTap(todos[index]),
            ),
          ],
        ],
      ),
    );
  }
}

class _TodoRow extends StatelessWidget {
  final TodoItem todo;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  const _TodoRow({
    required this.todo,
    required this.onToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    final priorityColor = todoPriorityColor(todo.priority, sh);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.small),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kMinTouch),
        child: Row(
          children: [
            Semantics(
              button: true,
              label: '${tr('할 일')} ${todo.title}',
              child: SizedBox(
                width: kMinTouch,
                height: kMinTouch,
                child: GestureDetector(
                  key: ValueKey('todo_check_${todo.id}'),
                  behavior: HitTestBehavior.opaque,
                  onTap: onToggle,
                  child: Center(
                    child: Icon(
                      todoStatusIcon(todo.status),
                      size: 21,
                      color: todoStatusColor(todo.status, todo.priority, sh),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Text(
                todo.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppType.bodyLarge.copyWith(
                  color: sh.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (todo.hasPriority) ...[
              const SizedBox(width: Gap.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(Radii.pill),
                ),
                child: Text(
                  _priorityLabel(todo.priority),
                  style: AppType.labelMedium.copyWith(
                    color: priorityColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _priorityLabel(int priority) => switch (priority) {
  1 => tr('높음'),
  2 => tr('보통'),
  3 => tr('낮음'),
  _ => '',
};

class _TodayEventsCard extends StatelessWidget {
  final List<EventItem> events;
  final List<CalendarTheme> themes;
  final VoidCallback onHeaderTap;
  final void Function(EventItem) onEventTap;

  const _TodayEventsCard({
    required this.events,
    required this.themes,
    required this.onHeaderTap,
    required this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    return _CardSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onHeaderTap,
            borderRadius: BorderRadius.circular(Radii.small),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: kMinTouch),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _CardHeader(title: trf('오늘 일정 {0}개', [events.length])),
              ),
            ),
          ),
          const SizedBox(height: Gap.sm),
          for (var index = 0; index < events.length; index++) ...[
            if (index > 0)
              Divider(
                height: 1,
                thickness: Borders.hairline,
                color: sh.border,
                indent: 18,
              ),
            _EventRow(
              event: events[index],
              themes: themes,
              onTap: () => onEventTap(events[index]),
            ),
          ],
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  final EventItem event;
  final List<CalendarTheme> themes;
  final VoidCallback onTap;

  const _EventRow({
    required this.event,
    required this.themes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    final category = _eventCategory(event, themes);
    final color = _eventColor(event, themes, sh);
    final time = event.hasTime ? event.tm! : tr('종일');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.small),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.t,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.bodyLarge.copyWith(
                      color: sh.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$time · $category',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.bodySmall.copyWith(color: sh.inkSoft),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _eventCategory(EventItem event, List<CalendarTheme> themes) {
  if (event.academic) return tr('학사일정');
  if (event.birthday) return tr('생일');
  if (event.sport) return tr('스포츠');
  for (final theme in themes) {
    if (event.themeIds.contains(theme.id)) return theme.name;
  }
  return tr('일정');
}

Color _eventColor(
  EventItem event,
  List<CalendarTheme> themes,
  SurlapColors sh,
) {
  if (event.academic) return sh.academicColor;
  if (event.birthday) return sh.birthdayColor;
  if (event.sportColor != null) return Color(event.sportColor!);
  for (final theme in themes) {
    if (event.themeIds.contains(theme.id)) return theme.colorValue;
  }
  return sh.accent;
}

class _HomeEmptyState extends StatelessWidget {
  final VoidCallback onAddTodo;
  final VoidCallback onAddEvent;

  const _HomeEmptyState({required this.onAddTodo, required this.onAddEvent});

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    final actions = [
      OutlinedButton.icon(
        key: const ValueKey('home_add_todo'),
        onPressed: onAddTodo,
        icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
        label: Text(tr('할 일 추가')),
        style: _emptyActionStyle(sh),
      ),
      OutlinedButton.icon(
        key: const ValueKey('home_add_event'),
        onPressed: onAddEvent,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text(tr('일정 추가')),
        style: _emptyActionStyle(sh),
      ),
    ];

    return _CardSurface(
      child: Padding(
        key: const ValueKey('home_empty_state'),
        padding: const EdgeInsets.symmetric(vertical: Gap.md),
        child: Column(
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 32,
              color: sh.accent,
              semanticLabel: tr('오늘 일정'),
            ),
            const SizedBox(height: Gap.sm),
            Text(
              tr('오늘 예정된 일정이 없어요'),
              textAlign: TextAlign.center,
              style: AppType.titleMedium.copyWith(
                color: sh.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: Gap.xs),
            Text(
              tr('아직 할 일이 없어요'),
              textAlign: TextAlign.center,
              style: AppType.bodyMedium.copyWith(color: sh.inkSoft),
            ),
            const SizedBox(height: Gap.lg),
            LayoutBuilder(
              builder: (context, constraints) {
                final largeText =
                    MediaQuery.textScalerOf(context).scale(1) > 1.3;
                if (constraints.maxWidth < 280 || largeText) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      actions.first,
                      const SizedBox(height: Gap.sm),
                      actions.last,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: actions.first),
                    const SizedBox(width: Gap.sm),
                    Expanded(child: actions.last),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  ButtonStyle _emptyActionStyle(SurlapColors sh) => OutlinedButton.styleFrom(
    foregroundColor: sh.accent,
    minimumSize: const Size(0, kMinTouch),
    padding: const EdgeInsets.symmetric(horizontal: Gap.sm),
    side: BorderSide(color: sh.border),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Radii.small),
    ),
    textStyle: AppType.bodyMedium.copyWith(fontWeight: FontWeight.w700),
  );
}

class _MealCard extends StatelessWidget {
  final String menu;
  final VoidCallback onTap;

  const _MealCard({required this.menu, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    return _CardSurface(
      color: sh.dark ? const Color(0xFF172A26) : const Color(0xFFEAF6F2),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(title: tr('오늘 급식')),
          const SizedBox(height: Gap.sm),
          Text(
            menu,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppType.bodyLarge.copyWith(
              color: sh.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _NextClassCard extends StatelessWidget {
  final _NextClass nextClass;
  final NeisSchool school;
  final VoidCallback onTap;

  const _NextClassCard({
    required this.nextClass,
    required this.school,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    final start = nextClass.startHour.toString().padLeft(2, '0');
    return _CardSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: tr('다음 수업'),
            trailing: _NavigationChip(label: tr('시간표'), onTap: onTap),
          ),
          const SizedBox(height: Gap.sm),
          Pressable(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: kMinTouch),
              child: Row(
                children: [
                  Text(
                    trf('{0}교시', [nextClass.period]),
                    style: AppType.labelMedium.copyWith(
                      color: sh.accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: Gap.sm),
                  Expanded(
                    child: Text(
                      nextClass.subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.bodyLarge.copyWith(
                        color: sh.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: Gap.sm),
                  Flexible(
                    child: Text(
                      '$start:00–$start:50 · ${school.grade}학년 ${school.classNm}반',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: AppType.bodySmall.copyWith(color: sh.inkSoft),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _CardHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppType.labelMedium.copyWith(
              color: sh.inkSoft,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: Gap.sm), trailing!],
      ],
    );
  }
}

class _NavigationChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _NavigationChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.pill),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: kMinTouch,
            minHeight: kMinTouch,
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: sh.card2,
                borderRadius: BorderRadius.circular(Radii.pill),
                border: Border.all(color: sh.border, width: Borders.hairline),
              ),
              child: Text(
                label,
                style: AppType.labelMedium.copyWith(
                  color: sh.inkSoft,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
