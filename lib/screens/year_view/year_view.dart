import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../providers/view_provider.dart';
import '../../core/utils/date_utils.dart' as du;
import '../../providers/events_provider.dart';
import '../../utils/screenshot_util.dart' show screenshotKey;

// 연간 미니 월 카드 라운드(홈·캘린더 톤과 통일).
const double _yRadius = 18;

class YearView extends ConsumerWidget {
  const YearView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(viewProvider);
    final events = ref.watch(eventsProvider);
    final sh = context.sh;
    final year = view.viewYear;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.sm, Gap.xl, 110),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: Gap.sm,
        mainAxisSpacing: Gap.sm,
      ),
      itemCount: 12,
      itemBuilder: (context, i) {
        final month = i + 1;
        return _MiniMonthCard(
          year: year,
          month: month,
          events: events,
          sh: sh,
          onTap: (source) =>
              _zoomToMonth(context, ref, source, year, month, sh),
        );
      },
    );
  }
}

// ── 미니 월 카드 ────────────────────────────────────────────────────

class _MiniMonthCard extends StatelessWidget {
  final int year, month;
  final Map<String, List<dynamic>> events;
  final SpaceHourColors sh;
  final void Function(Rect source) onTap;

  const _MiniMonthCard({
    required this.year,
    required this.month,
    required this.events,
    required this.sh,
    required this.onTap,
  });

  static const _monthNames = [
    '1월', '2월', '3월', '4월', '5월', '6월',
    '7월', '8월', '9월', '10월', '11월', '12월',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth = year == now.year && month == now.month;

    return GestureDetector(
      onTap: () {
        final box = context.findRenderObject();
        final rect = box is RenderBox && box.hasSize
            ? box.localToGlobal(Offset.zero) & box.size
            : Rect.zero;
        onTap(rect);
      },
      child: Container(
        decoration: BoxDecoration(
          color: sh.card,
          borderRadius: BorderRadius.circular(_yRadius),
          border: isCurrentMonth
              ? Border.all(color: sh.accent, width: 1.5)
              : Border.all(color: sh.ink.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: sh.dark ? 0.28 : 0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // 월 헤더
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isCurrentMonth
                    ? sh.accent.withValues(alpha: 0.12)
                    : sh.card2,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(_yRadius)),
              ),
              child: Center(
                child: Text(
                  _monthNames[month - 1],
                  style: AppType.label.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isCurrentMonth ? sh.accent : sh.inkSoft,
                  ),
                ),
              ),
            ),
            // 미니 캘린더 그리드 (이벤트 dot 포함)
            Expanded(
              child: _MiniMonthGrid(
                year: year,
                month: month,
                sh: sh,
                events: events,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 공유 미니 그리드 위젯 ─────────────────────────────────────────────
// _MiniMonthCard(년 뷰)와 _ZoomOverlay(전환 중) 양쪽에서 재사용.

class _MiniMonthGrid extends StatelessWidget {
  final int year, month;
  final SpaceHourColors sh;
  /// null이면 이벤트 dot 표시 안 함 (줌 오버레이에서 사용).
  final Map<String, List<dynamic>>? events;

  const _MiniMonthGrid({
    required this.year,
    required this.month,
    required this.sh,
    this.events,
  });

  static const _dow = ['일', '월', '화', '수', '목', '금', '토'];

  @override
  Widget build(BuildContext context) {
    final first = DateTime(year, month, 1);
    // 일요일 시작
    final startOffset = first.weekday % 7;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final cells = startOffset + daysInMonth;
    final rows = (cells / 7).ceil();
    final now = DateTime.now();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Column(
        children: [
          // 요일 헤더 (일=빨강, 토=파랑 살짝)
          Row(
            children: List.generate(
              7,
              (i) => Expanded(
                child: Center(
                  child: Text(_dow[i],
                      style: TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.w600,
                          color: i == 0
                              ? sh.sun.withValues(alpha: 0.7)
                              : i == 6
                                  ? sh.sat.withValues(alpha: 0.7)
                                  : sh.inkFaint)),
                ),
              ),
            ),
          ),
          // 날짜 셀
          Expanded(
            child: Column(
              children: List.generate(rows, (r) {
                return Expanded(
                  child: Row(
                    children: List.generate(7, (c) {
                      final idx = r * 7 + c;
                      final day = idx - startOffset + 1;
                      if (day < 1 || day > daysInMonth) {
                        return const Expanded(child: SizedBox());
                      }
                      final key =
                          du.toDateKey(DateTime(year, month, day));
                      final hasEvent =
                          events != null && (events![key] ?? []).isNotEmpty;
                      final isToday = year == now.year &&
                          month == now.month &&
                          day == now.day;
                      return Expanded(
                        child: Center(
                          child: Container(
                            width: 15,
                            height: 15,
                            decoration: isToday
                                ? BoxDecoration(
                                    color: sh.accent,
                                    shape: BoxShape.circle,
                                  )
                                : null,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Text(
                                  '$day',
                                  style: TextStyle(
                                    fontSize: 7.5,
                                    color: isToday ? Colors.white : sh.ink,
                                    fontWeight: isToday
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                  ),
                                ),
                                if (hasEvent)
                                  Positioned(
                                    bottom: isToday ? 1 : 0,
                                    child: Container(
                                      width: 3,
                                      height: 3,
                                      decoration: BoxDecoration(
                                        color:
                                            isToday ? Colors.white : sh.accent,
                                        shape: BoxShape.circle,
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
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 년→월 줌 전환 ─────────────────────────────────────────────────────
// Navigator 라우트가 아닌 AnimatedSwitcher 기반이라 Flutter Hero 대신
// 커스텀 Overlay로 구현. 출발 미니 월과 같은 날짜 그리드를 오버레이 안에
// 렌더한 뒤 폭 기준 유니폼 스케일로 확대 → 카드+날짜가 통째로 커지는 느낌.

void _zoomToMonth(BuildContext context, WidgetRef ref, Rect source,
    int year, int month, SpaceHourColors sh) {
  void switchView() {
    ref.read(viewProvider.notifier).setYearMonth(year, month);
    ref.read(viewProvider.notifier).setMode(ViewMode.events);
  }

  if (source == Rect.zero) {
    switchView();
    return;
  }
  final overlayState = Overlay.of(context);
  final box = screenshotKey.currentContext?.findRenderObject();
  final target = (box is RenderBox && box.hasSize)
      ? box.localToGlobal(Offset.zero) & box.size
      : Offset.zero & MediaQuery.of(context).size;

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _ZoomOverlay(
      source: source,
      target: target,
      sh: sh,
      year: year,
      month: month,
      monthLabel: '$month월',
      onSwitch: switchView,
      onDone: () => entry.remove(),
    ),
  );
  overlayState.insert(entry);
}

class _ZoomOverlay extends StatefulWidget {
  final Rect source, target;
  final SpaceHourColors sh;
  final int year, month;
  final String monthLabel;
  final VoidCallback onSwitch;
  final VoidCallback onDone;

  const _ZoomOverlay({
    required this.source,
    required this.target,
    required this.sh,
    required this.year,
    required this.month,
    required this.monthLabel,
    required this.onSwitch,
    required this.onDone,
  });

  @override
  State<_ZoomOverlay> createState() => _ZoomOverlayState();
}

class _ZoomOverlayState extends State<_ZoomOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 360));
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    });
    // 프레임 1: provider 수정을 빌드 사이클 밖에서 실행
    // (initState() 안에서 직접 호출 → "building 중 provider 수정" 에러)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onSwitch(); // MonthView를 오버레이 뒤에서 미리 빌드
      // 프레임 2: MonthView 빌드 완료 후 애니메이션 시작
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _c.forward();
      });
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sh = widget.sh;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeInOutCubic.transform(_c.value);
        final rect = Rect.lerp(widget.source, widget.target, t)!;
        // 반경: 작은 카드(_yRadius) → 가득 찰 때 0
        final br =
            BorderRadius.circular(_yRadius * (1.0 - t).clamp(0.0, 1.0));
        // 페이드아웃: t=0.6..1.0
        final fade =
            t < 0.6 ? 1.0 : (1 - (t - 0.6) / 0.4).clamp(0.0, 1.0);
        return IgnorePointer(
          child: Stack(
            children: [
              Positioned.fromRect(
                rect: rect,
                child: Opacity(opacity: fade, child: _card(sh, br, rect)),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 카드 + 내부 날짜 그리드를 통째로 스케일한다.
  ///
  /// • 폭 기준 유니폼 스케일(Transform.scale): 왜곡 없이 날짜가 함께 커짐.
  /// • 원점 = 소스 카드 크기를 기준으로 렌더 후 현재 rect 폭만큼 확대.
  /// • 스케일 넘치는 하단 부분은 Container(clipBehavior) 로 자연스럽게 잘림.
  Widget _card(SpaceHourColors sh, BorderRadius br, Rect currentRect) {
    final srcW = widget.source.width;
    final srcH = widget.source.height;
    // 폭 기준 유니폼 스케일 — 가로세로 같은 비율로 확대
    final scale = (currentRect.width / srcW).clamp(1.0, double.infinity);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: sh.card,
        borderRadius: br,
        border: Border.all(color: sh.accent, width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: srcW,
            height: srcH,
            child: Column(
              children: [
                // 월 헤더 (소스 크기 기준으로 렌더, scale로 같이 커짐)
                Container(
                  color: sh.accent.withValues(alpha: 0.12),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  alignment: Alignment.center,
                  child: Text(
                    widget.monthLabel,
                    style: AppType.label.copyWith(
                        fontWeight: FontWeight.w800, color: sh.accent),
                  ),
                ),
                // 날짜 그리드 (이벤트 dot 없이 날짜만)
                Expanded(
                  child: _MiniMonthGrid(
                    year: widget.year,
                    month: widget.month,
                    sh: sh,
                    // 전환 중엔 dot 불필요 (가벼움 유지)
                    events: null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
