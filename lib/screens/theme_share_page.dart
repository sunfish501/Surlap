import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';
import '../modals/theme_manager_modal.dart';
import 'sports/sports_subscription_section.dart';

/// 공유 캘린더 화면 — 2탭(아이콘): 공유 일정 / 스포츠 구독.
class ThemeSharePage extends ConsumerWidget {
  const ThemeSharePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sh = context.sh;
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // ── 탭바(아이콘만) ──
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, 0),
            child: TabBar(
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorColor: sh.accent,
              indicatorWeight: 2.5,
              labelColor: sh.accent,
              unselectedLabelColor: sh.inkSoft.withValues(alpha: 0.6),
              dividerColor: sh.ink.withValues(alpha: 0.06),
              tabs: const [
                Tab(
                  icon: Tooltip(
                    message: '공유 일정',
                    child: Icon(Icons.calendar_month_rounded, size: 24),
                  ),
                ),
                Tab(
                  icon: Tooltip(
                    message: '스포츠 구독',
                    child: Icon(Icons.sports_soccer_rounded, size: 24),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                // 탭1 — 공유 일정(캘린더 관리)
                ListView(
                  padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, 120),
                  children: const [ThemeManagerBody()],
                ),
                // 탭2 — 스포츠 구독
                ListView(
                  padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, 120),
                  children: const [SportsSubscriptionSection()],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
