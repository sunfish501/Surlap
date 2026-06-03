import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';
import '../providers/view_provider.dart';

// ─── 서브 헤더 (날짜 앵커 / 모토 / 뷰 세그먼트) ───────────────────
// 브랜드 행·공유·더보기는 AppOverlayTopBar(투명 overlay)로 이전됨.
// 이 위젯은 overlay 아래에 위치하는 일반 sub-header.
class AppHeader extends ConsumerStatefulWidget {
  const AppHeader({super.key});

  @override
  ConsumerState<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends ConsumerState<AppHeader> {
  bool _pickerOpen = false;

  static const _monthNames = [
    '1월','2월','3월','4월','5월','6월',
    '7월','8월','9월','10월','11월','12월',
  ];

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    final view = ref.watch(viewProvider);
    final notifier = ref.read(viewProvider.notifier);
    final isHome = view.mode == ViewMode.home;
    final isTimetable = view.mode == ViewMode.timetable;
    final isStudy = view.mode == ViewMode.study;
    final isSettings = view.mode == ViewMode.settings || view.mode == ViewMode.themes;
    final isYear = view.mode == ViewMode.year;

    return Container(
      color: sh.bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 날짜 앵커 + 탐색 (홈·시간표·공부위젯에서 숨김) ──────
          // 시간표·공부위젯 제목은 각 View가 직접 그린다.
          if (isHome || isTimetable || isStudy || isSettings)
            const SizedBox.shrink()
          else
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.sm, Gap.xl, 0),
            child: Row(
                    children: [
                      // 날짜 라벨 탭 → 날짜 피커
                      GestureDetector(
                        onTap: () =>
                            setState(() => _pickerOpen = !_pickerOpen),
                        child: Text(
                          isYear
                              ? '${view.viewYear}년'
                              : '${view.viewYear}년 ${_monthNames[view.viewMonth - 1]}',
                          style: AppType.title.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: sh.ink),
                        ),
                      ),
                      const Spacer(),
                      _NavBtn(
                        label: '＜',
                        onTap: isYear
                            ? () => notifier.prevYear()
                            : () => notifier.prevMonth(),
                        sh: sh,
                      ),
                      _NavBtn(
                        label: '＞',
                        onTap: isYear
                            ? () => notifier.nextYear()
                            : () => notifier.nextMonth(),
                        sh: sh,
                      ),
                      const SizedBox(width: Gap.xs),
                      _TodayBtn(
                        onTap: () {
                          notifier.goToToday();
                          if (isYear) notifier.setMode(ViewMode.events);
                        },
                        sh: sh,
                      ),
                    ],
                  ),
          ),

          // 날짜 피커 팝업
          if (_pickerOpen && !isTimetable)
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.xs, Gap.xl, 0),
              child: _DatePickerPopup(
                year: view.viewYear,
                month: view.viewMonth,
                sh: sh,
                onSelect: (y, m) {
                  notifier.setYearMonth(y, m);
                  if (isYear) notifier.setMode(ViewMode.events);
                  setState(() => _pickerOpen = false);
                },
              ),
            ),

          // ── 뷰 세그먼트 탭 (홈·시간표·공부위젯에서 숨김) ──────
          // 시간표·공부위젯은 세그먼트(연/월/주/일) 대상이 아니므로 숨긴다.
          if (!isHome && !isTimetable && !isStudy && !isSettings) Padding(
            padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.sm, Gap.xl, Gap.sm),
            child: _ViewSegment(view: view, notifier: notifier, sh: sh),
          ),
        ],
      ),
    );
  }
}

// ─── 알약형 뷰 세그먼트 탭 ────────────────────────────────────────
class _ViewSegment extends StatelessWidget {
  final ViewState view;
  final ViewNotifier notifier;
  final SpaceHourColors sh;

  const _ViewSegment({
    required this.view,
    required this.notifier,
    required this.sh,
  });

  @override
  Widget build(BuildContext context) {
    bool isActive(ViewMode m) => view.mode == m;

    String todayKey() {
      final n = DateTime.now();
      return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
    }

    final tabs = [
      (label: '연간', mode: ViewMode.year,
          onTap: () => notifier.setMode(ViewMode.year)),
      (label: '월간', mode: ViewMode.events,
          onTap: () => notifier.setMode(ViewMode.events)),
      // 주간 진입은 이번 주를 기준으로.
      (label: '주간', mode: ViewMode.planner,
          onTap: () => notifier.setWeekView(todayKey())),
      (label: '일별', mode: ViewMode.day,
          onTap: () => notifier.setDayView(todayKey())),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: sh.card2,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: tabs.map((t) {
          final active = isActive(t.mode);
          return Expanded(
            child: GestureDetector(
              onTap: t.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: active ? sh.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: sh.accent.withValues(alpha: 0.28),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  t.label,
                  textAlign: TextAlign.center,
                  style: AppType.label.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: active ? Colors.white : sh.inkSoft,
                      height: 1),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── 탐색 화살표 버튼 ────────────────────────────────────────────
class _NavBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final SpaceHourColors sh;
  const _NavBtn({required this.label, required this.onTap, required this.sh});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Text(label,
            style: AppType.body.copyWith(
                fontWeight: FontWeight.w500, color: sh.inkSoft)),
      ),
    );
  }
}

// ─── 오늘 버튼 ───────────────────────────────────────────────────
class _TodayBtn extends StatelessWidget {
  final VoidCallback onTap;
  final SpaceHourColors sh;
  const _TodayBtn({required this.onTap, required this.sh});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.small),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: Gap.sm + 2, vertical: Gap.xs),
        decoration: BoxDecoration(
          border: Border.all(color: sh.border),
          borderRadius: BorderRadius.circular(Radii.small),
        ),
        child: Text('오늘',
            style: AppType.caption.copyWith(
                fontWeight: FontWeight.w500, color: sh.inkSoft)),
      ),
    );
  }
}

// ─── 날짜 피커 팝업 ──────────────────────────────────────────────
class _DatePickerPopup extends StatefulWidget {
  final int year;
  final int month;
  final SpaceHourColors sh;
  final void Function(int, int) onSelect;
  const _DatePickerPopup({
    required this.year,
    required this.month,
    required this.sh,
    required this.onSelect,
  });

  @override
  State<_DatePickerPopup> createState() => _DatePickerPopupState();
}

class _DatePickerPopupState extends State<_DatePickerPopup> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    _year = widget.year;
    _month = widget.month;
  }

  @override
  Widget build(BuildContext context) {
    final sh = widget.sh;
    return Container(
      margin: const EdgeInsets.only(top: Gap.xs),
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(
        color: sh.card,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: sh.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PickerCol(
            items: List.generate(11, (i) => '${_year - 5 + i}년'),
            selected: 5,
            onChanged: (i) => setState(() => _year = _year - 5 + i),
            sh: sh,
          ),
          const SizedBox(width: Gap.sm),
          _PickerCol(
            items: List.generate(12, (i) => '${i + 1}월'),
            selected: _month - 1,
            onChanged: (i) => widget.onSelect(_year, i + 1),
            sh: sh,
          ),
        ],
      ),
    );
  }
}

class _PickerCol extends StatelessWidget {
  final List<String> items;
  final int selected;
  final void Function(int) onChanged;
  final SpaceHourColors sh;
  const _PickerCol({
    required this.items,
    required this.selected,
    required this.onChanged,
    required this.sh,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 160,
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (_, i) {
          final sel = i == selected;
          return GestureDetector(
            onTap: () => onChanged(i),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: sel
                  ? BoxDecoration(
                      color: sh.accentBg,
                      borderRadius: BorderRadius.circular(Radii.small))
                  : null,
              child: Center(
                child: Text(items[i],
                    style: AppType.body.copyWith(
                        fontWeight:
                            sel ? FontWeight.w700 : FontWeight.w400,
                        color: sel ? sh.accentInk : sh.inkSoft)),
              ),
            ),
          );
        },
      ),
    );
  }
}

