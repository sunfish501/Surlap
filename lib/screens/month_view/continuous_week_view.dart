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
import '../../providers/academic_schedule_provider.dart';
import '../../modals/day_action_sheet.dart';
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
              // 자유 스크롤 — 주 단위 강제 스냅 제거(스냅 위치 어긋남 해결).
              physics: const AlwaysScrollableScrollPhysics(),
              itemExtent: _rowH,
              itemBuilder: (context, index) {
                final ws = _weekStartForIndex(index);
                // 이 주가 새 달의 1일을 포함하면 월 경계 구분선 표시
                final containsMonthStart = List.generate(7,
                    (i) => DateTime(ws.year, ws.month, ws.day + i))
                    .any((d) => d.day == 1);
                return _WeekRow(
                  weekStart: ws,
                  showTopBorder: containsMonthStart,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekRow extends ConsumerWidget {
  final DateTime weekStart;
  final bool showTopBorder;
  const _WeekRow({required this.weekStart, this.showTopBorder = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventsProvider);
    final themes = ref.watch(themesProvider);
    final hiddenThemes = ref.watch(filterProvider);
    final circles = ref.watch(circlesProvider);
    final academic = ref.watch(academicScheduleProvider);
    final widgetValues = ref.watch(widgetValuesProvider);
    final dayTemplates = ref.watch(dayTemplatesProvider);
    final birthdays = ref.watch(birthdaysProvider);
    final sh = context.sh;

    // 월 경계 구분선 (1일이 포함된 주의 상단에 은은한 라인)
    Widget row = Row(
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
          if (!hiddenThemes.contains(birthdayThemeId))
            ...birthdays
                .where((b) => b.month == date.month && b.day == date.day)
                .map((b) => EventItem(
                    t: b.name, th: birthdayThemeId, birthday: true)),
          if (!hiddenThemes.contains(academicThemeId))
            ...(academic[key] ?? const [])
                .map((n) =>
                    EventItem(t: n, th: academicThemeId, academic: true)),
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
          hasCircle: circles.contains(key),
          applicableTemplates: applicable,
          dateWidgetValues: widgetValues[key] ?? {},
          onTap: () => _handleDayTap(context, ref, date),
          onLongPress: () => _handleDayTap(context, ref, date),
          onDoubleTap: () =>
              ref.read(circlesProvider.notifier).toggle(key),
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

    if (!showTopBorder) return row;

    // 월 경계: 은은한 상단 라인 추가 (Stack으로 row 위에 오버레이)
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: sh.border, width: 1.5)),
      ),
      child: row,
    );
  }

  void _handleDayTap(BuildContext context, WidgetRef ref, DateTime date) {
    showDayActionSheet(context, du.toDateKey(date), date);
  }
}
