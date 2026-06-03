import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../providers/view_provider.dart';
import '../providers/settings_provider.dart';
import '../supabase/auth_service.dart';
import '../modals/login_dialog.dart';
import '../utils/screenshot_util.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/app_header.dart';
import '../widgets/app_top_bar.dart';
import 'home_view/home_view.dart';
import 'study_widgets_view.dart';
import 'settings_view.dart';
import 'theme_share_page.dart';
import 'month_view/month_view.dart';
import 'month_view/continuous_week_view.dart';
import 'year_view/year_view.dart';
import 'day_view/day_view.dart';
import 'planner_view/planner_view.dart';
import 'timetable_view/timetable_view.dart';

// 첫 진입 로그인 안내를 앱 프로세스당 1회만 띄우기 위한 플래그.
bool _loginPromptShown = false;

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

    // 로그인 안 된 첫 진입 → 중앙 floating 로그인 modal (1회).
    // 저장된 세션/자격증명으로 자동 로그인될 수 있으니 잠시 뒤 재확인.
    if (!_loginPromptShown) {
      _loginPromptShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 800));
        if (!context.mounted) return;
        final user = ProviderScope.containerOf(context, listen: false)
            .read(authProvider);
        if (user == null) showLoginDialog(context);
      });
    }

    // 투명 overlay 헤더가 status bar 영역까지 덮으므로
    // 콘텐츠는 그 높이만큼 내려서 시작한다.
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: sh.bg,
      resizeToAvoidBottomInset: false,
      // 콘텐츠가 상·하단 시스템 영역까지 확장되도록 허용
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // ── 메인 콘텐츠 (화면 전체 높이 채움) ──
          Column(
            children: [
              // overlay 헤더 높이만큼 공간 확보 (status bar + 바 높이)
              SizedBox(height: topInset + kTopBarButtonH),
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
              // 스크롤 콘텐츠 가림은 각 뷰 내부의 bottom padding으로 처리
            ],
          ),
          // ── 투명 overlay 상단 헤더 (status bar 위까지) ──
          const AppOverlayTopBar(),
          // ── nav 뒤 하단 scrim (nav보다 아래 레이어) ──
          const BottomNavScrim(),
          // ── glass 플로팅 하단 바 (콘텐츠 위 overlay) ──
          const SpaceHourBottomNav(),
        ],
      ),
    );
  }

  Widget _buildView(ViewMode mode, String? dayKey, bool continuous) {
    switch (mode) {
      case ViewMode.home:      return const HomeView();
      case ViewMode.study:     return const StudyWidgetsView();
      case ViewMode.settings:  return const SettingsView();
      case ViewMode.themes:    return const ThemeSharePage();
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
