import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart' as du;
import '../../models/event_item.dart';
import '../../providers/view_provider.dart';
import '../../providers/events_provider.dart';
import '../../providers/themes_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/filter_provider.dart';
import '../../providers/extras_provider.dart';
import '../../providers/day_widget_provider.dart';
import '../../providers/birthdays_provider.dart';
import '../../modals/add_edit_event_modal.dart';
import '../../modals/day_widget_input_modal.dart';
import 'day_cell.dart';

/// 연속 보기 — 세로로 끝없이 이어지는 주(週) 단위 캘린더.
/// 주 행 높이에 맞춰 마그네틱 스냅(커스텀 ScrollPhysics)되며, 위로 스크롤한
/// 맨 위 주의 달이 상단 월 네비와 동기화된다.
class ContinuousWeekView extends ConsumerStatefulWidget {
  const ContinuousWeekView({super.key});

  @override
  ConsumerState<ContinuousWeekView> createState() =>
      _ContinuousWeekViewState();
}

class _ContinuousWeekViewState extends ConsumerState<ContinuousWeekView> {
  static const double _rowH = 96.0;
  static const int _centerIndex = 5000;

  late final ScrollController _ctrl;
  late final DateTime _anchorWeekStart; // _centerIndex 주의 시작일
  late final int _weekStartDow;
  bool _programmatic = false;

  @override
  void initState() {
    super.initState();
    final v = ref.read(viewProvider);
    _weekStartDow = ref.read(settingsProvider).weekStartDow;
    _anchorWeekStart =
        _weekStart(DateTime(v.viewYear, v.viewMonth, 1), _weekStartDow);
    _ctrl = ScrollController(initialScrollOffset: _centerIndex * _rowH);
    _ctrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onScroll);
    _ctrl.dispose();
    super.dispose();
  }

  int _offsetInWeek(DateTime d, int wsd) => (d.weekday % 7 - wsd + 7) % 7;
  DateTime _weekStart(DateTime d, int wsd) =>
      DateTime(d.year, d.month, d.day - _offsetInWeek(d, wsd));

  DateTime _weekStartForIndex(int i) =>
      _anchorWeekStart.add(Duration(days: (i - _centerIndex) * 7));

  int _indexForDate(DateTime d) {
    final ws = _weekStart(d, _weekStartDow);
    final days = ws.difference(_anchorWeekStart).inDays;
    return _centerIndex + (days / 7).round();
  }

  // 맨 위 주의 "중간(목요일쯤)" 날짜 기준으로 달을 정해 네비와 동기화.
  void _onScroll() {
    if (_programmatic || !_ctrl.hasClients) return;
    final topIndex = (_ctrl.offset / _rowH).round();
    final mid = _weekStartForIndex(topIndex).add(const Duration(days: 3));
    final cur = ref.read(viewProvider);
    if (cur.viewYear != mid.year || cur.viewMonth != mid.month) {
      ref.read(viewProvider.notifier).setYearMonth(mid.year, mid.month);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;

    // 외부(월 네비/오늘 버튼)에서 달이 바뀌면 해당 달 1일이 든 주로 스냅.
    ref.listen<ViewState>(viewProvider, (prev, next) {
      if (prev == null) return;
      if (prev.viewYear == next.viewYear &&
          prev.viewMonth == next.viewMonth) {
        return;
      }
      if (!_ctrl.hasClients) return;
      final topIndex = (_ctrl.offset / _rowH).round();
      final curMid =
          _weekStartForIndex(topIndex).add(const Duration(days: 3));
      // 이미 그 달을 보고 있으면(=스크롤로 인한 변경) 다시 움직이지 않는다.
      if (curMid.year == next.viewYear && curMid.month == next.viewMonth) {
        return;
      }
      final target = _indexForDate(DateTime(next.viewYear, next.viewMonth, 1));
      _programmatic = true;
      _ctrl
          .animateTo(
            target * _rowH,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          )
          .whenComplete(() => _programmatic = false);
    });

    final headers = du.weekdayHeaders(_weekStartDow);

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: sh.border, width: 0.5)),
      ),
      child: Column(
        children: [
          // 요일 헤더
          Container(
            color: sh.card2,
            child: Row(
              children: headers.asMap().entries.map((e) {
                final dow = (_weekStartDow + e.key) % 7;
                final isSun = dow == DateTime.sunday % 7;
                final isSat = dow == DateTime.saturday;
                return Expanded(
                  child: Container(
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: sh.border, width: 0.5),
                        bottom: BorderSide(color: sh.border, width: 0.5),
                      ),
                    ),
                    child: Text(
                      e.value,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSun
                            ? sh.danger
                            : isSat
                                ? sh.sat
                                : sh.inkSoft,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _ctrl,
              physics: const _WeekSnapPhysics(itemExtent: _rowH),
              itemExtent: _rowH,
              itemBuilder: (context, index) =>
                  _WeekRow(weekStart: _weekStartForIndex(index)),
            ),
          ),
        ],
      ),
    );
  }
}

/// 주 행 높이에 자석처럼 스냅하는 ScrollPhysics.
class _WeekSnapPhysics extends ScrollPhysics {
  final double itemExtent;
  const _WeekSnapPhysics({required this.itemExtent, super.parent});

  @override
  _WeekSnapPhysics applyTo(ScrollPhysics? ancestor) =>
      _WeekSnapPhysics(itemExtent: itemExtent, parent: buildParent(ancestor));

  double _snapTarget(ScrollMetrics position, double velocity, Tolerance tol) {
    final current = position.pixels / itemExtent;
    double target;
    if (velocity < -tol.velocity) {
      target = current.floor() * itemExtent;
    } else if (velocity > tol.velocity) {
      target = current.ceil() * itemExtent;
    } else {
      target = current.round() * itemExtent;
    }
    return target.clamp(position.minScrollExtent, position.maxScrollExtent);
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    // 경계 밖이면 부모(범위 복귀)에 위임
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final tol = toleranceFor(position);
    final target = _snapTarget(position, velocity, tol);
    if ((target - position.pixels).abs() < tol.distance) return null;
    return ScrollSpringSimulation(spring, position.pixels, target, velocity,
        tolerance: tol);
  }

  @override
  bool get allowImplicitScrolling => false;
}

class _WeekRow extends ConsumerWidget {
  final DateTime weekStart;
  const _WeekRow({required this.weekStart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventsProvider);
    final themes = ref.watch(themesProvider);
    final hiddenThemes = ref.watch(filterProvider);
    final starred = ref.watch(starredProvider);
    final circles = ref.watch(circlesProvider);
    final widgetValues = ref.watch(widgetValuesProvider);
    final dayTemplates = ref.watch(dayTemplatesProvider);
    final birthdays = ref.watch(birthdaysProvider);
    final sh = context.sh;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(7, (i) {
        final date = DateTime(
            weekStart.year, weekStart.month, weekStart.day + i);
        final key = du.toDateKey(date);

        // 카테고리 필터 적용 + 생일 병합
        final dayEvents = <EventItem>[
          ...(events[key] ?? []).where((item) {
            if (hiddenThemes.isEmpty) return true;
            final ids = item.themeIds;
            if (ids.isEmpty) return !hiddenThemes.contains('__none__');
            return ids.every((id) => !hiddenThemes.contains(id));
          }),
          ...birthdays
              .where((b) => b.month == date.month && b.day == date.day)
              .map((b) => EventItem(t: '🎂 ${b.name}')),
        ];

        final applicable = dayTemplates
            .where((t) => t.enabled && t.scope.appliesTo(key))
            .toList();

        Widget cell = DayCell(
          date: date,
          viewMonth: date, // 연속 보기에선 흐리게 처리하지 않음
          events: dayEvents,
          themes: themes,
          sh: sh,
          showPast: true,
          starCount: starred[key] ?? 0,
          hasCircle: circles.contains(key),
          applicableTemplates: applicable,
          dateWidgetValues: widgetValues[key] ?? {},
          onTap: () => _handleDayTap(context, ref, date),
          onLongPress: () => _handleDayTap(context, ref, date),
        );

        // 매월 1일 셀에 월 라벨 오버레이 (달 경계 표시)
        if (date.day == 1) {
          cell = Stack(
            children: [
              Positioned.fill(child: cell),
              Positioned(
                top: 1,
                left: 2,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: sh.accentBg,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text('${date.month}월',
                      style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: sh.accentInk)),
                ),
              ),
            ],
          );
        }

        return Expanded(child: cell);
      }),
    );
  }

  void _handleDayTap(BuildContext context, WidgetRef ref, DateTime date) {
    final key = du.toDateKey(date);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _DayActionSheet(dateKey: key, date: date, ref: ref),
    );
  }
}

class _DayActionSheet extends StatelessWidget {
  final String dateKey;
  final DateTime date;
  final WidgetRef ref;

  const _DayActionSheet({
    required this.dateKey,
    required this.date,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    return Container(
      color: sh.card,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${date.month}월 ${date.day}일',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: sh.ink)),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.add_rounded,
            label: '일정 추가',
            color: sh.accent,
            onTap: () {
              Navigator.pop(context);
              showAddEditEventModal(context, dateKey: dateKey);
            },
          ),
          _ActionTile(
            icon: Icons.today_outlined,
            label: '이날 자세히 보기',
            color: sh.ink,
            onTap: () {
              Navigator.pop(context);
              ref.read(viewProvider.notifier).setDayView(dateKey);
            },
          ),
          _ActionTile(
            icon: Icons.bar_chart_rounded,
            label: '위젯 입력',
            color: sh.ink,
            onTap: () {
              Navigator.pop(context);
              showDayWidgetInputModal(context, dateKey);
            },
          ),
          Builder(builder: (ctx) {
            final starCount = ref.read(starredProvider)[dateKey] ?? 0;
            final starLabel = starCount == 0
                ? '별표 표시'
                : starCount < 3
                    ? '별표 추가 ($starCount/3)'
                    : '별표 해제';
            final starIcon = starCount >= 3
                ? Icons.star_rounded
                : Icons.star_border_rounded;
            return _ActionTile(
              icon: starIcon,
              label: starLabel,
              color: starCount > 0 ? const Color(0xFFF39C12) : sh.ink,
              onTap: () {
                Navigator.pop(context);
                ref.read(starredProvider.notifier).toggle(dateKey);
              },
            );
          }),
          Builder(builder: (ctx) {
            final hasCircle = ref.read(circlesProvider).contains(dateKey);
            return _ActionTile(
              icon: hasCircle
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              label: hasCircle ? '동그라미 해제' : '동그라미 표시',
              color: sh.ink,
              onTap: () {
                Navigator.pop(context);
                ref.read(circlesProvider.notifier).toggle(dateKey);
              },
            );
          }),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color, size: 20),
      title: Text(label, style: TextStyle(fontSize: 14, color: color)),
      onTap: onTap,
    );
  }
}
