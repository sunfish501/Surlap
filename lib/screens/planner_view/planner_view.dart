import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/date_utils.dart' as du;
import '../../models/event_item.dart';
import '../../models/calendar_theme.dart';
import '../../providers/events_provider.dart';
import '../../providers/themes_provider.dart';
import '../../providers/view_provider.dart';
import '../../providers/recurring_provider.dart';
import '../../providers/academic_schedule_provider.dart';
import '../../providers/filter_provider.dart';
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
    // 기준 날짜: 월간에서 넘어온 viewDay(anchor)가 있으면 그 주, 없으면 이번 주.
    final anchorKey = ref.read(viewProvider).viewDay;
    final anchor = anchorKey != null ? du.fromDateKey(anchorKey) : DateTime.now();
    final dow = anchor.weekday; // 1=월…7=일
    final monday = anchor.subtract(Duration(days: dow - 1 - _weekOffset * 7));
    return List.generate(7, (i) => DateTime(monday.year, monday.month, monday.day + i));
  }

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    final events = ref.watch(eventsProvider);
    final themes = ref.watch(themesProvider);
    final academic = ref.watch(academicScheduleProvider);
    final academicHidden = ref.watch(filterProvider).contains(academicThemeId);
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
                                      color: sh.card,
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
                                          style: AppType.label.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: isToday
                                                ? sh.accent
                                                : isSun
                                                    ? sh.danger
                                                    : isSat
                                                        ? sh.sat
                                                        : sh.inkSoft,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        // 오늘은 브랜드 accent pill로 강조(홈·월간과 통일).
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: isToday ? 8 : 0,
                                              vertical: isToday ? 2 : 0),
                                          decoration: isToday
                                              ? BoxDecoration(
                                                  color: sh.accent,
                                                  borderRadius:
                                                      BorderRadius.circular(999),
                                                )
                                              : null,
                                          child: Text(
                                            '${d.month}/${d.day}',
                                            style: AppType.label.copyWith(
                                              fontSize: 12.5,
                                              fontWeight: isToday
                                                  ? FontWeight.w800
                                                  : FontWeight.w600,
                                              color:
                                                  isToday ? Colors.white : sh.ink,
                                            ),
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
                              final allDay = [
                                ...(events[dayKeys[i]] ?? [])
                                    .where((e) => !e.hasTime && !e.isTimetable),
                                if (!academicHidden)
                                  ...(academic[dayKeys[i]] ?? const [])
                                      .map((n) => EventItem(
                                          t: n,
                                          th: academicThemeId,
                                          academic: true)),
                              ];
                              return Expanded(
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
                                                .take(2)
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
                                      // 주간은 스크롤만 — 빈 칸 탭으로 추가하지 않음.
                                      return Expanded(
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
                                      );
                                    }),
                                  ),
                                  // 반복 일정 오버레이(시간표 탭에서 작성)
                                  ..._buildRecurringOverlays(sh),
                                  // 일반 이벤트 오버레이
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

  // 반복 일정(요일 기준) — 모든 주에 동일하게 표시, soft tint + 반복 아이콘.
  List<Widget> _buildRecurringOverlays(SpaceHourColors sh) {
    final recurring = ref.watch(recurringProvider);
    final colW = (MediaQuery.of(context).size.width - _timeColW) / 7;
    final overlays = <Widget>[];
    for (int i = 0; i < 7; i++) {
      final byHour = recurring[i];
      if (byHour == null) continue;
      byHour.forEach((hour, title) {
        overlays.add(Positioned(
          left: i * colW + 1,
          top: hour * _rowH + 1,
          width: colW - 2,
          height: _rowH - 2,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 1),
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
            decoration: BoxDecoration(
              color: sh.accent.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(6),
              border: Border(
                  left: BorderSide(
                      color: sh.accent.withValues(alpha: 0.5), width: 3)),
            ),
            child: Row(
              children: [
                Icon(Icons.repeat_rounded, size: 9, color: sh.accent),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(title,
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: sh.accentInk),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        ));
      });
    }
    return overlays;
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
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: thColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(7),
                border: Border(left: BorderSide(color: thColor, width: 3)),
              ),
              child: Text(
                e.t,
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w500, color: sh.ink),
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
      padding: const EdgeInsets.symmetric(horizontal: Gap.xl, vertical: Gap.xs),
      color: sh.bg,
      child: Row(
        children: [
          _NavBtn('＜', onPrev, sh),
          Expanded(
            child: Center(
              child: Text(label,
                  style: AppType.body.copyWith(fontWeight: FontWeight.w700, color: sh.ink)),
            ),
          ),
          _NavBtn('＞', onNext, sh),
          const SizedBox(width: Gap.xs + 2),
          InkWell(
            onTap: onToday,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: sh.accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('오늘',
                  style: AppType.caption.copyWith(
                      fontWeight: FontWeight.w700, color: sh.accent)),
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
        child: Text(label, style: AppType.section.copyWith(color: sh.inkSoft)),
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
    // 학사일정: 청록 + 학교 아이콘.
    if (item.academic) {
      final c = sh.academicColor;
      return Container(
        margin: const EdgeInsets.only(bottom: 1),
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(children: [
          Icon(Icons.school_rounded, size: 9, color: c),
          const SizedBox(width: 2),
          Expanded(
            child: Text(item.t,
                style: TextStyle(
                    fontSize: 10, color: c, fontWeight: FontWeight.w600),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ]),
      );
    }
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
