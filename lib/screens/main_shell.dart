import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../providers/view_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/screenshot_util.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/app_header.dart';
import 'home_view/home_view.dart';
import 'month_view/month_view.dart';
import 'month_view/continuous_week_view.dart';
import 'year_view/year_view.dart';
import 'day_view/day_view.dart';
import 'planner_view/planner_view.dart';
import 'timetable_view/timetable_view.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(viewProvider);
    final settings = ref.watch(settingsProvider);
    final sh = context.sh;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: sh.dark ? Brightness.light : Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: sh.bg,
      resizeToAvoidBottomInset: false,
      // bottomNavigationBar 제거 — 플로팅 pill 바는 Stack으로 처리
      body: SafeArea(
        child: Stack(
          children: [
            // ── 메인 콘텐츠 ──
            Column(
              children: [
                const AppHeader(),
                Expanded(
                  child: RepaintBoundary(
                    key: screenshotKey,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, anim) => _SlideTransition(
                        animation: anim,
                        direction: view.slideDirection,
                        child: child,
                      ),
                      child: KeyedSubtree(
                        key: ValueKey('${view.mode}_${settings.continuousView}'),
                        child: _buildView(view.mode, view.viewDay, settings.continuousView),
                      ),
                    ),
                  ),
                ),
                // 하단 바 높이만큼 패딩 (플로팅 바에 가려지지 않도록)
                const SizedBox(height: 84),
              ],
            ),
            // ── 플로팅 하단 바 (Positioned) ──
            const SpaceHourBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildView(ViewMode mode, String? dayKey, bool continuous) {
    switch (mode) {
      case ViewMode.home:      return const HomeView();
      case ViewMode.events:
        return continuous ? const ContinuousWeekView() : const MonthView();
      case ViewMode.year:      return const YearView();
      case ViewMode.planner:   return const PlannerView();
      case ViewMode.day:       return DayView(dateKey: dayKey ?? _todayKey());
      case ViewMode.timetable: return const TimetableView();
    }
  }

  String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2,'0')}-${n.day.toString().padLeft(2,'0')}';
  }
}

class _SlideTransition extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;
  final int direction;

  const _SlideTransition({
    required this.child,
    required this.animation,
    required this.direction,
  });

  @override
  Widget build(BuildContext context) {
    if (direction == 0) {
      return FadeTransition(opacity: animation, child: child);
    }
    final offset = Tween<Offset>(
      begin: Offset(direction * 0.12, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(position: offset, child: child),
    );
  }
}
