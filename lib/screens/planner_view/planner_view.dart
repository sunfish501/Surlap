import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart' as du;
import '../../models/event_item.dart';
import '../../models/calendar_theme.dart';
import '../../providers/events_provider.dart';
import '../../providers/themes_provider.dart';
import '../../providers/view_provider.dart';
import '../../modals/add_edit_event_modal.dart';

class PlannerView extends ConsumerStatefulWidget {
  const PlannerView({super.key});

  @override
  ConsumerState<PlannerView> createState() => _PlannerViewState();
}

class _PlannerViewState extends ConsumerState<PlannerView> {
  int _weekOffset = 0;
  final _scrollCtrl = ScrollController();

  static const _dowNames = ['월', '화', '수', '목', '금', '토', '일'];
  static const _timeColW = 44.0;
  static const _rowH = 48.0;
  static const _headerH = 48.0;
  static const _allDayH = 36.0;

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  List<DateTime> _weekDays() {
    final today = DateTime.now();
    final dow = today.weekday; // 1=월…7=일
    final monday = today.subtract(Duration(days: dow - 1 - _weekOffset * 7));
    return List.generate(7, (i) => DateTime(monday.year, monday.month, monday.day + i));
  }

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    final events = ref.watch(eventsProvider);
    final themes = ref.watch(themesProvider);
    final days = _weekDays();
    final dayKeys = days.map(du.toDateKey).toList();
    final now = DateTime.now();
    return Column(
      children: [
        // 주 이동 헤더
        _WeekNav(
          days: days,
          sh: sh,
          onPrev: () => setState(() => _weekOffset--),
          onNext: () => setState(() => _weekOffset++),
          onToday: () => setState(() => _weekOffset = 0),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 고정 시간 레이블 컬럼
              SizedBox(
                width: _timeColW,
                child: Column(
                  children: [
                    // 요일 헤더 공간
                    SizedBox(height: _headerH + _allDayH),
                    // 시간 레이블
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollCtrl,
                        physics: const NeverScrollableScrollPhysics(),
                        child: Column(
                          children: List.generate(24, (h) {
                            return SizedBox(
                              height: _rowH,
                              child: Align(
                                alignment: Alignment.topRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 6, top: 2),
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
                    ),
                  ],
                ),
              ),
              // 날짜 컬럼들
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width - _timeColW,
                    child: Column(
                      children: [
                        // 요일 헤더
                        SizedBox(
                          height: _headerH,
                          child: Row(
                            children: List.generate(7, (i) {
                              final d = days[i];
                              final isToday = du.isSameDay(d, now);
                              final isSat = d.weekday == DateTime.saturday;
                              final isSun = d.weekday == DateTime.sunday;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => ref.read(viewProvider.notifier)
                                      .setDayView(dayKeys[i]),
                                  child: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isToday ? sh.accentBg : sh.card,
                                      border: Border(
                                        right: BorderSide(color: sh.border, width: 0.5),
                                        bottom: BorderSide(color: sh.border),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _dowNames[i],
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isToday
                                                ? sh.accentInk
                                                : isSun
                                                    ? sh.danger
                                                    : isSat
                                                        ? sh.sat
                                                        : sh.inkSoft,
                                          ),
                                        ),
                                        Text(
                                          '${d.month}/${d.day}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: isToday
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: isToday ? sh.accentInk : sh.ink,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        // 종일 행
                        SizedBox(
                          height: _allDayH,
                          child: Row(
                            children: List.generate(7, (i) {
                              final allDay = (events[dayKeys[i]] ?? [])
                                  .where((e) => !e.hasTime && !e.isTimetable)
                                  .toList();
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => showAddEditEventModal(context,
                                      dateKey: dayKeys[i]),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: du.isSameDay(days[i], now)
                                          ? sh.accentBg.withValues(alpha: 0.5)
                                          : sh.card2,
                                      border: Border(
                                        right: BorderSide(color: sh.border, width: 0.5),
                                        bottom: BorderSide(color: sh.border),
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 2),
                                    child: allDay.isEmpty
                                        ? null
                                        : SingleChildScrollView(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: allDay
                                                  .take(1)
                                                  .map((e) => _EventChip(
                                                        item: e,
                                                        themes: themes,
                                                        sh: sh,
                                                        onTap: () {},
                                                      ))
                                                  .toList(),
                                            ),
                                          ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        // 시간 슬롯
                        Expanded(
                          child: SingleChildScrollView(
                            controller: _scrollCtrl,
                            child: SizedBox(
                              height: _rowH * 24,
                              child: Stack(
                                children: [
                                  // 그리드 라인 + 셀 배경
                                  Row(
                                    children: List.generate(7, (i) {
                                      final isToday =
                                          du.isSameDay(days[i], now);
                                      return Expanded(
                                        child: GestureDetector(
                                          onTapDown: (_) {
                                            showAddEditEventModal(
                                              context,
                                              dateKey: dayKeys[i],
                                            );
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: isToday
                                                  ? sh.accentBg.withValues(alpha: 0.18)
                                                  : null,
                                              border: Border(
                                                right: BorderSide(
                                                    color: sh.border,
                                                    width: 0.5),
                                              ),
                                            ),
                                            child: Column(
                                              children: List.generate(24, (h) =>
                                                Container(
                                                  height: _rowH,
                                                  decoration: BoxDecoration(
                                                    border: Border(
                                                      top: BorderSide(
                                                          color: sh.border,
                                                          width: 0.5),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                  // 이벤트 오버레이
                                  ..._buildEventOverlays(
                                      days, dayKeys, events, themes, sh),
                                  // 현재 시각 선
                                  if (_weekOffset == 0)
                                    _NowLine(hour: now.hour, minute: now.minute,
                                        rowH: _rowH, sh: sh),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildEventOverlays(
    List<DateTime> days,
    List<String> dayKeys,
    Map<String, List<EventItem>> events,
    List<CalendarTheme> themes,
    SpaceHourColors sh,
  ) {
    final colW = (MediaQuery.of(context).size.width - _timeColW) / 7;
    final overlays = <Widget>[];

    for (int i = 0; i < 7; i++) {
      final timed = (events[dayKeys[i]] ?? [])
          .where((e) => e.hasTime && !e.isTimetable)
          .toList();
      for (final e in timed) {
        final parts = e.tm!.split(':');
        final h = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        final top = h * _rowH + m * _rowH / 60;
        double height = _rowH;
        if (e.te != null) {
          final ep = e.te!.split(':');
          final eh = int.parse(ep[0]);
          final em = int.parse(ep[1]);
          height = ((eh - h) * 60 + (em - m)) * _rowH / 60;
          if (height < 20) { height = 20; }
        }
        final thColor = e.themeIds.isNotEmpty
            ? themes.firstWhere(
                (t) => e.themeIds.contains(t.id),
                orElse: () => const CalendarTheme(id: '', name: '', color: '#6b8ec2'),
              ).colorValue
            : sh.accent;

        overlays.add(Positioned(
          left: i * colW + 1,
          top: top,
          width: colW - 2,
          height: height.clamp(18.0, double.infinity),
          child: GestureDetector(
            onTap: () {
              final idx = (events[dayKeys[i]] ?? []).indexOf(e);
              showAddEditEventModal(context, dateKey: dayKeys[i], editIndex: idx);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: thColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(4),
                border: Border(left: BorderSide(color: thColor, width: 3)),
              ),
              child: Text(
                e.t,
                style: TextStyle(fontSize: 10, color: sh.ink),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ));
      }
    }
    return overlays;
  }
}

class _WeekNav extends StatelessWidget {
  final List<DateTime> days;
  final SpaceHourColors sh;
  final VoidCallback onPrev, onNext, onToday;

  const _WeekNav({
    required this.days, required this.sh,
    required this.onPrev, required this.onNext, required this.onToday,
  });

  @override
  Widget build(BuildContext context) {
    final first = days.first;
    final last  = days.last;
    final label = first.month == last.month
        ? '${first.year}년 ${first.month}월'
        : '${first.month}월 ~ ${last.month}월';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      color: sh.bg,
      child: Row(
        children: [
          _NavBtn('＜', onPrev, sh),
          Expanded(
            child: Center(
              child: Text(label,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: sh.ink)),
            ),
          ),
          _NavBtn('＞', onNext, sh),
          const SizedBox(width: 6),
          InkWell(
            onTap: onToday,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: sh.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('오늘', style: TextStyle(fontSize: 12, color: sh.inkSoft)),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final SpaceHourColors sh;
  const _NavBtn(this.label, this.onTap, this.sh);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(label, style: TextStyle(fontSize: 16, color: sh.inkSoft)),
      ),
    );
  }
}

class _EventChip extends StatelessWidget {
  final EventItem item;
  final List<CalendarTheme> themes;
  final SpaceHourColors sh;
  final VoidCallback onTap;
  const _EventChip({required this.item, required this.themes,
    required this.sh, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = item.themeIds.isNotEmpty
        ? themes.firstWhere((t) => item.themeIds.contains(t.id),
            orElse: () => CalendarTheme(id:'', name:'', color:'#888888')).colorValue
        : sh.accent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 1),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(item.t,
            style: TextStyle(fontSize: 10, color: sh.ink),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _NowLine extends StatelessWidget {
  final int hour, minute;
  final double rowH;
  final SpaceHourColors sh;
  const _NowLine({required this.hour, required this.minute,
    required this.rowH, required this.sh});

  @override
  Widget build(BuildContext context) {
    final top = hour * rowH + minute * rowH / 60;
    return Positioned(
      top: top,
      left: 0, right: 0,
      child: Container(
        height: 1.5,
        color: sh.danger.withValues(alpha: 0.7),
      ),
    );
  }
}
