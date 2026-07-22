import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';
import '../core/utils/date_utils.dart' as du;
import '../modals/add_edit_event_modal.dart';
import '../providers/theme_sharing_provider.dart';
import '../providers/view_provider.dart';
import '../utils/screenshot_util.dart';
import '../widgets/app_header.dart';
import '../widgets/dark_star_background.dart';
import '../widgets/surlap_app_bar.dart';
import '../widgets/surlap_navigation_drawer.dart';
import 'day_view/day_view.dart';
import 'home_view/home_view.dart';
import 'month_view/month_view.dart';
import 'planner_view/planner_view.dart';
import 'profile_view.dart';
import 'search_view.dart';
import 'theme_share_page.dart';
import 'timetable_view/timetable_agenda_view.dart';
import 'year_view/year_view.dart';

/// Surlap v2.1 전역 셸.
/// 하단 탭과 글래스 오버레이를 제거하고 햄버거 + 5개 목적지 드로어로 통일한다.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(viewProvider);
    final sh = context.sh;
    ref.watch(themeSharingProvider);

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: sh.bg,
        statusBarIconBrightness: sh.dark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: sh.bg,
        systemNavigationBarIconBrightness: sh.dark
            ? Brightness.light
            : Brightness.dark,
      ),
    );

    final searching = view.mode == ViewMode.search;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: sh.bg,
      drawer: const SurlapNavigationDrawer(),
      drawerScrimColor: Colors.black.withValues(alpha: 0.5),
      drawerEnableOpenDragGesture: !searching,
      onDrawerChanged: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      resizeToAvoidBottomInset: true,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _showsFab(view.mode)
          ? SizedBox.square(
              dimension: kMinTouch,
              child: FloatingActionButton(
                heroTag: 'surlap-add-event',
                elevation: 4,
                highlightElevation: 2,
                backgroundColor: sh.accent,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                tooltip: '일정 추가',
                onPressed: () => showAddEditEventModal(
                  context,
                  dateKey: view.viewDay ?? du.todayKey(),
                ),
                child: const Icon(Icons.add_rounded, size: 24),
              ),
            )
          : null,
      body: Column(
        children: [
          if (!searching)
            SurlapAppBar(onMenu: () => _scaffoldKey.currentState?.openDrawer()),
          if (!searching) const AppHeader(),
          Expanded(
            child: RepaintBoundary(
              key: screenshotKey,
              child: AnimatedSwitcher(
                duration: Motion.base,
                switchInCurve: Motion.curve,
                switchOutCurve: Motion.curve,
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: KeyedSubtree(
                  key: ValueKey(_viewKey(view)),
                  child: ColoredBox(
                    color: sh.bg,
                    child: sh.dark
                        ? DarkStarBackground(child: _buildView(view))
                        : _buildView(view),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _showsFab(ViewMode mode) => const {
    ViewMode.home,
    ViewMode.events,
    ViewMode.year,
    ViewMode.planner,
    ViewMode.day,
  }.contains(mode);

  String _viewKey(ViewState view) {
    // The visible month is scroll state, not a navigation destination.
    // Keeping this key stable prevents AnimatedSwitcher from destroying and
    // rebuilding the entire month grid whenever the header month changes.
    if (view.mode == ViewMode.events) return 'events';
    if (view.mode == ViewMode.year) return 'year_${view.viewYear}';
    if (view.mode == ViewMode.day || view.mode == ViewMode.planner) {
      return '${view.mode}_${view.viewDay}';
    }
    return '${view.mode}';
  }

  Widget _buildView(ViewState view) {
    switch (view.mode) {
      case ViewMode.home:
        return const HomeView();
      case ViewMode.profile:
      case ViewMode.settings:
        return const ProfileView();
      case ViewMode.themes:
        return const ThemeSharePage();
      case ViewMode.events:
        return const MonthView();
      case ViewMode.year:
        return const YearView();
      case ViewMode.planner:
        return const PlannerView();
      case ViewMode.day:
        return DayView(dateKey: view.viewDay ?? du.todayKey());
      case ViewMode.timetable:
        return const TimetableAgendaView();
      case ViewMode.search:
        return const SearchView();
    }
  }
}
