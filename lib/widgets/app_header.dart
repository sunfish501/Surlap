import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';
import '../providers/view_provider.dart';
import '../screens/search_view.dart';
import 'calendar_filter_strip.dart';
import 'view_segment_control.dart';

// ─── 서브 헤더 (날짜 앵커) ────────────────────────────────────────
// 월간/연간에서만 표시. 주간/일간은 자체 헤더, 그 외 뷰는 자체 제목.
// 오늘 버튼·뷰 세그먼트·날짜 피커는 제거됨(전환은 상단바 점세개로).
class AppHeader extends ConsumerStatefulWidget {
  const AppHeader({super.key});

  @override
  ConsumerState<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends ConsumerState<AppHeader> {
  static const _monthNames = [
    '1월', '2월', '3월', '4월', '5월', '6월',
    '7월', '8월', '9월', '10월', '11월', '12월',
  ];

  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchCtrl.clear();
    _searchFocus.unfocus();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    final view = ref.watch(viewProvider);
    final notifier = ref.read(viewProvider.notifier);
    final isYear = view.mode == ViewMode.year;
    final isMonth = view.mode == ViewMode.events;

    // 앵커는 월간/연간에서만. (주간/일간/홈/스케줄표/테마/프로필 등은 숨김)
    if (!isMonth && !isYear) return const SizedBox.shrink();

    final searching = _query.trim().isNotEmpty;
    final hits = searching ? searchHits(ref, _query) : const <SearchHit>[];

    return Container(
      color: sh.bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.sm, Gap.xl, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1행: 검색창 (좌 검색아이콘 · 우 필터/뷰 아이콘) ──
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: sh.dark
                        ? const Color(0xFF1E1B2C)
                        : sh.ink.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: searching
                            ? sh.accent.withValues(alpha: 0.35)
                            : sh.ink.withValues(alpha: 0.06)),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => _searchFocus.requestFocus(),
                        behavior: HitTestBehavior.opaque,
                        child:
                            Icon(Icons.search_rounded, size: 20, color: sh.inkSoft),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          focusNode: _searchFocus,
                          style: AppType.body
                              .copyWith(fontSize: 15.5, color: sh.ink),
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                            hintText: '일정 검색하기',
                            hintStyle:
                                TextStyle(color: sh.inkSoft, fontSize: 15.5),
                            // 이중 배경 방지 — 컨테이너 하나만 배경.
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                            // 바 전체 높이를 탭 영역으로 — zero 패딩이면 글자 줄만 탭돼 포커스 안 잡힘.
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 13),
                          ),
                          onChanged: (v) => setState(() => _query = v),
                        ),
                      ),
                      if (searching)
                        GestureDetector(
                          onTap: _clearSearch,
                          behavior: HitTestBehavior.opaque,
                          child: Icon(Icons.close_rounded,
                              size: 20, color: sh.inkFaint),
                        ),
                    ],
                  ),
                ),
                // ── 뷰 전환 세그먼트(연·월·주·일) ──
                const SizedBox(height: 10),
                const ViewSegmentControl(),
                if (searching) ...[
                  const SizedBox(height: 8),
                  // ── 검색 결과(바 아래 바로) ──
                  Container(
                    constraints: const BoxConstraints(maxHeight: 340),
                    decoration: BoxDecoration(
                      color: sh.card,
                      borderRadius: BorderRadius.circular(18),
                      border:
                          Border.all(color: sh.ink.withValues(alpha: 0.06)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: sh.dark ? 0.35 : 0.10),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: hits.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(18),
                            child: Text('검색 결과가 없어요',
                                style: AppType.body
                                    .copyWith(color: sh.inkSoft)),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            itemCount: hits.length,
                            itemBuilder: (_, i) => SearchHitTile(
                              hit: hits[i],
                              sh: sh,
                              onTap: () {
                                if (hits[i].dateKey.isNotEmpty) {
                                  notifier.setDayView(hits[i].dateKey);
                                }
                                _clearSearch();
                              },
                            ),
                          ),
                  ),
                  const SizedBox(height: Gap.sm),
                ] else ...[
                  const SizedBox(height: 22),
                  // ── 2행: 월 제목(좌) + 이전/다음(우) ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            notifier.goToToday();
                            if (isYear) notifier.setMode(ViewMode.events);
                          },
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '${view.viewYear}년 ',
                                  style: AppType.title.copyWith(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      color: sh.inkSoft),
                                ),
                                if (!isYear)
                                  TextSpan(
                                    text: _monthNames[view.viewMonth - 1],
                                    style: AppType.title.copyWith(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                        color: sh.ink),
                                  ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _NavBtn(
                        icon: Icons.chevron_left_rounded,
                        onTap: isYear ? notifier.prevYear : notifier.prevMonth,
                        sh: sh,
                      ),
                      const SizedBox(width: 8),
                      _NavBtn(
                        icon: Icons.chevron_right_rounded,
                        onTap: isYear ? notifier.nextYear : notifier.nextMonth,
                        sh: sh,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                ],
              ],
            ),
          ),
          // ── 3행: 필터 칩(검색 중이 아닐 때만, 같은 좌측 기준선) ──
          if (!searching) ...[
            const CalendarFilterStrip(),
            const SizedBox(height: 10),
          ],
        ],
      ),
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
      // 색칠된 Container 자체는 hit-test 안 됨 — 아이콘만 탭되던 문제 → 버튼 전체 탭.
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: sh.card2,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: sh.ink.withValues(alpha: 0.07)),
        ),
        child: Icon(icon, size: 24, color: sh.inkSoft),
      ),
    );
  }
}
