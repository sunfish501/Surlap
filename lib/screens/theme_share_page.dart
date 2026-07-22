import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';
import '../modals/theme_manager_modal.dart';
import 'sports/sports_subscription_section.dart';

/// 캘린더 공유와 스포츠 구독을 한 화면에서 관리한다.
class ThemeSharePage extends ConsumerWidget {
  const ThemeSharePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sh = context.sh;

    return DefaultTabController(
      length: 2,
      initialIndex: 0,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, 0),
            child: Container(
              height: 44,
              padding: const EdgeInsets.all(Gap.xs),
              decoration: BoxDecoration(
                color: sh.card2,
                borderRadius: BorderRadius.circular(Gap.md),
                border: Border.all(color: sh.border, width: Borders.hairline),
              ),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                dividerHeight: 0,
                splashBorderRadius: BorderRadius.circular(Radii.small),
                labelColor: sh.accent,
                unselectedLabelColor: sh.inkSoft,
                labelStyle: AppType.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: AppType.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                indicator: BoxDecoration(
                  color: sh.card,
                  borderRadius: BorderRadius.circular(Radii.small),
                  border: Border.all(color: sh.border, width: Borders.hairline),
                ),
                tabs: const [
                  Tab(text: '캘린더 공유'),
                  Tab(text: '스포츠 구독'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _ShareTab(sh: sh, child: const ThemeManagerBody()),
                _ShareTab(sh: sh, child: const SportsSubscriptionSection()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareTab extends StatelessWidget {
  const _ShareTab({required this.sh, required this.child});

  final SurlapColors sh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, Gap.xxl),
      children: [
        Container(
          padding: const EdgeInsets.all(Gap.lg),
          decoration: BoxDecoration(
            color: sh.card,
            borderRadius: BorderRadius.circular(Radii.card),
            border: Border.all(color: sh.border, width: Borders.hairline),
          ),
          child: child,
        ),
      ],
    );
  }
}
