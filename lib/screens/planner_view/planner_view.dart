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
import '../../providers/neis_cache_provider.dart';
import '../../providers/settings_provider.dart';
import '../../supabase/neis_service.dart' show NeisSchool, academicVisibleForGrade;
import '../timetable_view/timetable_view.dart'
    show timetableSubjectsForDate, getDisplaySubjectName;
import '../../widgets/zoom_button.dart';
import '../../widgets/view_segment_control.dart';
import '../../widgets/calendar_filter_strip.dart';
import '../../widgets/header_collapse.dart';
import '../month_view/multiday_span.dart';
import '../../providers/academic_schedule_provider.dart';
import '../../providers/birthdays_provider.dart';
import '../../providers/filter_provider.dart';
import '../../providers/sports_provider.dart';
import '../../providers/shared_theme_events_provider.dart';
import '../../modals/add_edit_event_modal.dart';

class PlannerView extends ConsumerStatefulWidget {
  const PlannerView({super.key});

  @override
  ConsumerState<PlannerView> createState() => _PlannerViewState();
}

class _PlannerViewState extends ConsumerState<PlannerView> {
  int _weekOffset = 0;
  final _scrollCtrl = ScrollController();   // 본문(시간 슬롯)
  final _labelCtrl = ScrollController();    // 고정 시간 라벨열(본문 따라감)

  static const _dowNames = ['월', '화', '수', '목', '금', '토', '일'];
  static const _timeColW = 50.0;
  static const _baseRowH = 52.0;
  double _zoom = 1.0; // 확대/축소 — 시간 행 높이 배율.
  double get _rowH => _baseRowH * _zoom;
  static const _headerH = 52.0;
  static const _allDayH = 38.0;
  static const _bottomPad = 120.0; // 하단 네비/FAB 가림 방지

  @override
  void initState() {
    super.initState();
    // 본문 세로 스크롤에 시간 라벨열을 동기화(같은 컨트롤러 공유 시 desync 방지).
    _scrollCtrl.addListener(_syncLabel);
  }

  void _syncLabel() {
    if (!_labelCtrl.hasClients || !_scrollCtrl.hasClients) return;
    final o = _scrollCtrl.offset.clamp(
        _labelCtrl.position.minScrollExtent, _labelCtrl.position.maxScrollExtent);
    if (_labelCtrl.offset != o) _labelCtrl.jumpTo(o);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_syncLabel);
    _scrollCtrl.dispose();
    _labelCtrl.dispose();
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
    final hidden = ref.watch(filterProvider);
    final academicHidden = hidden.contains(academicThemeId);
    final birthdays = ref.watch(birthdaysProvider);
    final birthdayHidden = hidden.contains(birthdayThemeId);
    // 스포츠 경기(시간 있음) + 구독 공유 테마 일정 — 종일/타임 그리드에 머지.
    final sportsByDate = ref.watch(sportsEventsByDateProvider);
    final sharedByDate = ref.watch(sharedThemeEventsByDateProvider);
    final eventsWithSports = <String, List<EventItem>>{...events};
    void mergeExtra(Map<String, List<EventItem>> src) {
      src.forEach((k, items) {
        final vis = items
            .where((e) =>
                e.themeIds.isNotEmpty && !hidden.contains(e.themeIds.first))
            .toList();
        if (vis.isEmpty) return;
        eventsWithSports[k] = [...(eventsWithSports[k] ?? const []), ...vis];
      });
    }

    mergeExtra(sportsByDate);
    mergeExtra(sharedByDate);
    final days = _weekDays();
    final dayKeys = days.map(du.toDateKey).toList();
    final now = DateTime.now();
    final grade = NeisSchool.load()?.grade; // 다른 학년 학사일정 숨김용
    // 칸별 종일 일정(필터 + 생일/학사). 같은 이름 연속이면 가로 막대로 병합.
    final colAllDay = <List<EventItem>>[
      for (int i = 0; i < 7; i++)
        <EventItem>[
          ...(eventsWithSports[dayKeys[i]] ?? [])
              .where((e) => !e.hasTime && !e.isTimetable),
          if (!birthdayHidden)
            ...birthdays
                .where((b) =>
                    b.month == days[i].month && b.day == days[i].day)
                .map((b) =>
                    EventItem(t: b.name, th: birthdayThemeId, birthday: true)),
          if (!academicHidden)
            ...(academic[dayKeys[i]] ?? const [])
                .where((n) => academicVisibleForGrade(n, grade))
                .map((n) =>
                    EventItem(t: n, th: academicThemeId, academic: true)),
        ],
    ];
    final hasAllDay = colAllDay.any((l) => l.isNotEmpty);
    final allDaySpans = computeDaySpans(colAllDay, themes, sh);
    final allDaySlots = spanSlotCount(allDaySpans.spans);
    final allDayReserve = allDaySlots * (kSpanBarH + 2);
    final allDayH = hasAllDay ? _allDayH + allDayReserve : 0.0;
    return CollapseOnScroll(
      child: Column(
      children: [
        // 헤더(세그먼트 + 주 이동 + 필터칩) — 스크롤 시 부드럽게 접힘.
        CollapsibleHeader(
          collapsed: ref.watch(headerCollapsedProvider),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 통합 뷰 전환 세그먼트(연·월·주·일)
              const Padding(
                padding: EdgeInsets.fromLTRB(Gap.lg, Gap.xs, Gap.lg, 0),
                child: ViewSegmentControl(),
              ),
              // 주 이동 헤더(한 줄: 이동 + 토글 + 줌버튼)
              _WeekNav(
                days: days,
                sh: sh,
                showTimetable: ref.watch(settingsProvider).showTimetable,
                onToggleSchedule: () => ref
                    .read(settingsProvider.notifier)
                    .setShowTimetable(
                        !ref.read(settingsProvider).showTimetable),
                onZoomIn: () =>
                    setState(() => _zoom = (_zoom + 0.2).clamp(0.6, 2.0)),
                onZoomOut: () =>
                    setState(() => _zoom = (_zoom - 0.2).clamp(0.6, 2.0)),
                onPrev: () => setState(() => _weekOffset--),
                onNext: () => setState(() => _weekOffset++),
                onToday: () => setState(() => _weekOffset = 0),
              ),
              // 카테고리 필터칩 — 헤더 묶음 안에.
              const CalendarFilterStrip(),
            ],
          ),
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
                    SizedBox(height: _headerH + allDayH),
                    // 시간 레이블
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _labelCtrl,
                        physics: const NeverScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            ...List.generate(24, (h) {
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
                                          fontSize: 10.5, color: sh.inkFaint),
                                    ),
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: _bottomPad),
                          ],
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
                        // 종일 행 (없으면 0). 같은 이름 연속 = 가로 막대 병합.
                        SizedBox(
                          height: allDayH,
                          child: LayoutBuilder(builder: (ctx, c) {
                            final colW = c.maxWidth / 7;
                            return Stack(
                              children: [
                                Row(
                                  children: List.generate(7, (i) {
                                    final chips = colAllDay[i]
                                        .where((e) => !allDaySpans.spanned
                                            .contains('$i|${e.t}'))
                                        .toList();
                                    return Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: du.isSameDay(days[i], now)
                                              ? sh.accentBg
                                                  .withValues(alpha: 0.5)
                                              : sh.card2,
                                          border: Border(
                                            right: BorderSide(
                                                color: sh.border, width: 0.5),
                                            bottom:
                                                BorderSide(color: sh.border),
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 2),
                                        child: Padding(
                                          // 막대 슬롯만큼 아래로 밀어 칩과 겹침 방지.
                                          padding: EdgeInsets.only(
                                              top: allDayReserve),
                                          child: chips.isEmpty
                                              ? null
                                              // 넘치면 잘라(overflow 방지).
                                              : ClipRect(
                                                  child: SingleChildScrollView(
                                                    physics:
                                                        const NeverScrollableScrollPhysics(),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .stretch,
                                                      children: chips
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
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                                // 멀티데이 막대 오버레이.
                                ...allDaySpans.spans.map((s) => Positioned(
                                      top: s.slot * (kSpanBarH + 2) + 1,
                                      left: s.start * colW + 1.5,
                                      width: (s.end - s.start + 1) * colW - 3,
                                      height: kSpanBarH,
                                      child: SpanBar(span: s, sh: sh),
                                    )),
                              ],
                            );
                          }),
                        ),
                        // 시간 슬롯
                        Expanded(
                          child: SingleChildScrollView(
                            controller: _scrollCtrl,
                            child: Column(
                              children: [
                            SizedBox(
                              height: _rowH * 24,
                              child: Stack(
                                children: [
                                  // 그리드 라인 + 셀 배경
                                  Row(
                                    children: List.generate(7, (i) {
                                      final isToday =
                                          du.isSameDay(days[i], now);
                                      // 빈 칸을 탭하면 그 날(일간 뷰)로 이동.
                                      return Expanded(
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: () => ref
                                              .read(viewProvider.notifier)
                                              .setDayView(dayKeys[i]),
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
                                  // 시간표 수업 오버레이(읽기전용 — 수정은 스케줄표에서만)
                                  ..._buildRecurringOverlays(days, sh),
                                  // 일반 이벤트 오버레이(+스포츠 머지)
                                  ..._buildEventOverlays(
                                      days, dayKeys, eventsWithSports, themes, sh),
                                  // 현재 시각 선
                                  if (_weekOffset == 0)
                                    _NowLine(hour: now.hour, minute: now.minute,
                                        rowH: _rowH, sh: sh),
                                ],
                              ),
                            ),
                                const SizedBox(height: _bottomPad),
                              ],
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
      ),
    );
  }

  // 시간표 수업 오버레이 — NEIS·템플릿·주간반복 합산, 읽기전용. 토글로 on/off.
  List<Widget> _buildRecurringOverlays(List<DateTime> days, SpaceHourColors sh) {
    ref.watch(recurringProvider);
    ref.watch(neisCacheProvider);
    if (!ref.watch(settingsProvider).showTimetable) return const [];
    final colW = (MediaQuery.of(context).size.width - _timeColW) / 7;
    final overlays = <Widget>[];
    for (int i = 0; i < 7; i++) {
      final byHour = timetableSubjectsForDate(ref, days[i]);
      byHour.forEach((hour, title) {
        final name = getDisplaySubjectName(title);
        overlays.add(Positioned(
          left: i * colW + 2,
          top: hour * _rowH + 2,
          width: colW - 4,
          height: _rowH - 4,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            decoration: BoxDecoration(
              color: sh.accent.withValues(alpha: sh.dark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: sh.accent.withValues(alpha: 0.25)),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                    fontSize: 12,
                    letterSpacing: -0.3,
                    fontWeight: FontWeight.w700,
                    color: sh.dark ? sh.ink : sh.accentInk),
              ),
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
        final thColor = e.sport && e.sportColor != null
            ? Color(e.sportColor!)
            : e.themeIds.isNotEmpty
                ? themes.firstWhere(
                    (t) => e.themeIds.contains(t.id),
                    orElse: () =>
                        const CalendarTheme(id: '', name: '', color: '#6b8ec2'),
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
                softWrap: true,
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
  final bool showTimetable;
  final VoidCallback onToggleSchedule;
  final VoidCallback onZoomIn, onZoomOut;
  final VoidCallback onPrev, onNext, onToday;

  const _WeekNav({
    required this.days, required this.sh,
    required this.showTimetable, required this.onToggleSchedule,
    required this.onZoomIn, required this.onZoomOut,
    required this.onPrev, required this.onNext, required this.onToday,
  });

  // 그 달의 몇째 주(월요일 시작 기준).
  static int _weekOfMonth(DateTime d) {
    final first = DateTime(d.year, d.month, 1);
    final offset = (first.weekday - 1) % 7;
    return ((d.day + offset - 1) / 7).floor() + 1;
  }

  @override
  Widget build(BuildContext context) {
    final rep = days[3]; // 주 중간(목요일쯤) — 그 주가 속한 달 기준.
    final wom = _weekOfMonth(rep);
    return Container(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.xs, Gap.lg, Gap.sm),
      color: sh.bg,
      child: Row(
        children: [
          _NavBtn('＜', onPrev, sh),
          // 라벨 — 년도 작게, 월·주 크게. 탭하면 오늘로. 공간 부족 시 자동 축소.
          Flexible(
            child: GestureDetector(
            onTap: onToday,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text.rich(
                TextSpan(children: [
                  TextSpan(
                    text: '${rep.year} ',
                    style: AppType.caption.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: sh.inkSoft),
                  ),
                  TextSpan(
                    text: '${rep.month}월 $wom째주',
                    style: AppType.title.copyWith(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: sh.ink),
                  ),
                ]),
                ),
              ),
            ),
          ),
          ),
          _NavBtn('＞', onNext, sh),
          const Spacer(),
          // 스케줄 표시 토글(아이콘만).
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggleSchedule,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: showTimetable ? sh.accent.withValues(alpha: 0.10) : sh.card2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: showTimetable
                        ? sh.accent.withValues(alpha: 0.35)
                        : sh.ink.withValues(alpha: 0.08)),
              ),
              child: Icon(
                  showTimetable
                      ? Icons.event_available_rounded
                      : Icons.event_busy_rounded,
                  size: 20,
                  color: showTimetable ? sh.accent : sh.inkSoft),
            ),
          ),
          const SizedBox(width: 6),
          // 컴팩트 줌(+/−).
          ZoomButton(icon: Icons.remove_rounded, sh: sh, onTap: onZoomOut),
          const SizedBox(width: 6),
          ZoomButton(icon: Icons.add_rounded, sh: sh, onTap: onZoomIn),
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
    // 생일·학사일정: 아이콘 칩으로 구분.
    if (item.birthday || item.academic) {
      final c = item.birthday ? sh.birthdayColor : sh.academicColor;
      final icon =
          item.birthday ? Icons.cake_rounded : Icons.school_rounded;
      return Container(
        margin: const EdgeInsets.only(bottom: 1),
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(children: [
          Icon(icon, size: 9, color: c),
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
