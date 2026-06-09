import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';
import '../i18n/dates.dart' as i18nd;
import '../providers/view_provider.dart';
import '../providers/settings_provider.dart';
import '../screens/search_view.dart';
import 'calendar_filter_strip.dart';
import 'view_segment_control.dart';
import 'header_collapse.dart';

// ─── 월/연 상단 헤더 ──────────────────────────────────────────────
// 주/일(_WeekNav·day)과 동일한 단일 행 구조로 통일:
//   날짜 ‹ ›  +  세그먼트(연·월·주·일)  +  ⋮(검색·오늘)   /   아래 필터칩(접힘)
// 검색은 별도 바 대신 ⋮ 메뉴 → 시트로(전환 시 레이아웃 안 튐).
class AppHeader extends ConsumerWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sh = context.sh;
    final view = ref.watch(viewProvider);
    final notifier = ref.read(viewProvider.notifier);
    final isYear = view.mode == ViewMode.year;
    final isMonth = view.mode == ViewMode.events;

    if (!isMonth && !isYear) return const SizedBox.shrink();

    // 필터칩만 스크롤 접힘(연속 월간에서). 네비 행은 항상 보임.
    final scrollable = isMonth && ref.watch(settingsProvider).continuousView;
    final collapsed = scrollable && ref.watch(headerCollapsedProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 1행: 세그먼트 풀폭 (일 뷰와 동일 구조로 통일) ──
        const Padding(
          padding: EdgeInsets.fromLTRB(Gap.lg, Gap.xs, Gap.lg, Gap.sm),
          child: ViewSegmentControl(),
        ),
        // ── 2행: 날짜(좌, 탭→오늘) + 컨트롤(우) ──
        Padding(
          padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.sm),
          child: Row(
            children: [
              // 날짜 라벨 — 탭하면 오늘로. 공간 부족 시 자동 축소.
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    notifier.goToToday();
                    if (isYear) notifier.setMode(ViewMode.events);
                  },
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(
                          text: '${view.viewYear} ',
                          style: AppType.caption.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: sh.inkSoft),
                        ),
                        TextSpan(
                          text: isYear
                              ? i18nd.yearWord
                              : i18nd.monthName(view.viewMonth),
                          style: AppType.title.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              color: sh.ink),
                        ),
                      ]),
                      maxLines: 1,
                    ),
                  ),
                ),
              ),
              _NavBtn(
                icon: Icons.chevron_left_rounded,
                onTap: isYear ? notifier.prevYear : notifier.prevMonth,
                sh: sh,
              ),
              const SizedBox(width: 6),
              _NavBtn(
                icon: Icons.chevron_right_rounded,
                onTap: isYear ? notifier.nextYear : notifier.nextMonth,
                sh: sh,
              ),
              const SizedBox(width: 2),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, size: 20, color: sh.inkSoft),
                padding: EdgeInsets.zero,
                tooltip: '더보기',
                color: sh.card,
                onSelected: (v) {
                  if (v == 'search') showSearchSheet(context);
                  if (v == 'today') {
                    notifier.goToToday();
                    if (isYear) notifier.setMode(ViewMode.events);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'search',
                    child: Row(children: [
                      Icon(Icons.search_rounded, size: 18, color: sh.inkSoft),
                      const SizedBox(width: 10),
                      Text('일정 검색', style: TextStyle(color: sh.ink)),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'today',
                    child: Row(children: [
                      Icon(Icons.today_rounded, size: 18, color: sh.inkSoft),
                      const SizedBox(width: 10),
                      Text('오늘로', style: TextStyle(color: sh.ink)),
                    ]),
                  ),
                ],
              ),
            ],
          ),
        ),
        // 필터칩만 접힘.
        CollapsibleHeader(
          collapsed: collapsed,
          child: const CalendarFilterStrip(),
        ),
      ],
    );
  }
}

// ─── 탐색 화살표 버튼 (또렷한 박스형) ────────────────────────────
class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final SpaceHourColors sh;
  const _NavBtn({required this.icon, required this.onTap, required this.sh});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: sh.card2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sh.ink.withValues(alpha: 0.07)),
        ),
        child: Icon(icon, size: 22, color: sh.inkSoft),
      ),
    );
  }
}
