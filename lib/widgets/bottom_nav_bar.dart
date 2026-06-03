import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/date_utils.dart' as du;
import '../providers/view_provider.dart';
import '../widgets/sidebar_drawer.dart';
import '../widgets/glass_container.dart';
import 'coach_mark.dart';

// ─── Glassmorphism Floating Bottom Navigation ───────────────────
// 유리판처럼 뒤 콘텐츠가 비치는 반투명 capsule. 화면 위에 overlay.
// Active: 밝은 capsule + 진한 아이콘 / Inactive: 흐린 아이콘
class SpaceHourBottomNav extends ConsumerWidget {
  const SpaceHourBottomNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view     = ref.watch(viewProvider);
    final notifier = ref.read(viewProvider.notifier);
    final sh       = context.sh;
    final dark     = sh.dark;

    String todayKey() => du.toDateKey(DateTime.now());

    // ── 탭 정의 ────────────────────────────────────────────────
    final tabs = [
      _Tab(
        active: Icons.home_rounded,
        inactive: Icons.home_outlined,
        label: '홈',
        isActive: view.mode == ViewMode.home,
        onTap: () => notifier.setMode(ViewMode.home),
      ),
      _Tab(
        active: Icons.calendar_month_rounded,
        inactive: Icons.calendar_month_outlined,
        label: '캘린더',
        isActive: const {ViewMode.events, ViewMode.year, ViewMode.planner}.contains(view.mode),
        onTap: () {
          if (!const {ViewMode.events, ViewMode.year, ViewMode.planner}.contains(view.mode)) {
            notifier.setMode(ViewMode.events);
          }
        },
      ),
      _Tab(
        active: Icons.grid_view_rounded,
        inactive: Icons.grid_view_outlined,
        label: '시간표',
        isActive: view.mode == ViewMode.timetable,
        onTap: () => notifier.setMode(ViewMode.timetable),
        coachKey: coachKeyTabTimetable,
      ),
      _Tab(
        active: Icons.edit_note_rounded,
        inactive: Icons.edit_note_rounded,
        label: '기록',
        isActive: view.mode == ViewMode.day,
        onTap: () => notifier.setDayView(todayKey()),
      ),
      _Tab(
        active: Icons.settings_rounded,
        inactive: Icons.settings_outlined,
        label: '설정',
        isActive: false,
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const FractionallySizedBox(
            heightFactor: 0.85,
            child: SidebarDrawer(),
          ),
        ),
        coachKey: coachKeyTabProfile,
      ),
    ];

    // ── glass 색상 (다크/라이트 분기) ──────────────────────────
    // 밝은 배경: 흰 frost(높은 불투명) + 옅은 어두운 hairline + shadow로 capsule 정의
    // 어두운 배경: 검정 frost + 밝은 border
    final tint = dark
        ? Colors.black.withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.62);
    final borderColor = dark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.black.withValues(alpha: 0.06);
    final shadowColor = Colors.black.withValues(alpha: dark ? 0.45 : 0.12);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 12,
      child: SafeArea(
        child: Center(
          child: GlassContainer(
            key: coachKeyBottomNav,
            borderRadius: 32,
            blur: 22,
            tint: tint,
            borderColor: borderColor,
            shadowColor: shadowColor,
            shadowBlur: 24,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: SizedBox(
              height: 58,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: tabs.map((t) => _NavBtn(tab: t, dark: dark)).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── 탭 데이터 모델 ──────────────────────────────────────────────
class _Tab {
  final IconData active;
  final IconData inactive;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final GlobalKey? coachKey;

  const _Tab({
    required this.active,
    required this.inactive,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.coachKey,
  });
}

// ─── 개별 탭 버튼 ────────────────────────────────────────────────
class _NavBtn extends StatelessWidget {
  final _Tab tab;
  final bool dark;

  const _NavBtn({required this.tab, required this.dark});

  @override
  Widget build(BuildContext context) {
    final active = tab.isActive;

    // Active: glass 위에서 더 밝은 capsule로 강조
    final activePillColor = dark
        ? Colors.white.withValues(alpha: 0.90)
        : Colors.white.withValues(alpha: 0.95);
    final activeIconColor = Colors.black.withValues(alpha: 0.90);
    final inactiveIconColor = dark
        ? Colors.white.withValues(alpha: 0.55)
        : Colors.black.withValues(alpha: 0.48);

    return Semantics(
      label: tab.label,
      button: true,
      child: GestureDetector(
        key: tab.coachKey,
        onTap: tab.onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 54,
          height: 58,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: active ? 46 : 38,
              height: active ? 42 : 38,
              decoration: BoxDecoration(
                color: active ? activePillColor : Colors.transparent,
                borderRadius: BorderRadius.circular(23),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: dark ? 0.22 : 0.10),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                active ? tab.active : tab.inactive,
                size: 22,
                color: active ? activeIconColor : inactiveIconColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
