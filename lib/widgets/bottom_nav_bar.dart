import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../providers/view_provider.dart';
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
        isActive: const {
          ViewMode.events,
          ViewMode.year,
          ViewMode.planner,
          ViewMode.day,
        }.contains(view.mode),
        // 이미 캘린더 계열(연/월/주/일) 안이어도 탭하면 월간으로 복귀.
        onTap: () => notifier.setMode(ViewMode.events),
      ),
      _Tab(
        active: Icons.grid_view_rounded,
        inactive: Icons.grid_view_outlined,
        label: '스케줄표',
        isActive: view.mode == ViewMode.timetable,
        onTap: () => notifier.setMode(ViewMode.timetable),
        coachKey: coachKeyTabTimetable,
      ),
      _Tab(
        active: Icons.palette_rounded,
        inactive: Icons.palette_outlined,
        label: '공유 캘린더',
        isActive: view.mode == ViewMode.themes,
        onTap: () => notifier.setMode(ViewMode.themes),
      ),
      _Tab(
        active: Icons.person_rounded,
        inactive: Icons.person_outline_rounded,
        label: '프로필',
        // 설정은 프로필 안에서 진입하므로 두 모드 모두 프로필 탭을 활성으로.
        isActive: view.mode == ViewMode.profile || view.mode == ViewMode.settings,
        onTap: () => notifier.setMode(ViewMode.profile),
        coachKey: coachKeyTabProfile,
      ),
    ];

    // ── glass 색상 (다크/라이트 분기) ──────────────────────────
    // 밝은 배경에서도 사라지지 않도록 frost·border·shadow를 강하게.
    final tint = dark
        ? Colors.black.withValues(alpha: 0.40)
        : Colors.white.withValues(alpha: 0.48);
    final borderColor = dark
        ? Colors.white.withValues(alpha: 0.16)
        : Colors.white.withValues(alpha: 0.70);
    final shadowColor = Colors.black.withValues(alpha: dark ? 0.50 : 0.12);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 12,
      child: SafeArea(
        top: false,
        child: Center(
          child: GlassContainer(
            key: coachKeyBottomNav,
            borderRadius: 34,
            blur: 24,
            tint: tint,
            borderColor: borderColor,
            shadowColor: shadowColor,
            shadowBlur: 30,
            shadowOffset: const Offset(0, 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: SizedBox(
              height: 44,
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

// ─── nav 뒤 하단 scrim ───────────────────────────────────────────
// nav가 콘텐츠 위에 떠 있는 느낌을 강화. nav보다 아래 레이어에 두고,
// IgnorePointer로 터치를 막지 않는다.
class BottomNavScrim extends ConsumerWidget {
  const BottomNavScrim({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sh = context.sh;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Container(
          height: 170,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                sh.bg.withValues(alpha: 0.94),
                sh.bg.withValues(alpha: 0.55),
                sh.bg.withValues(alpha: 0.0),
              ],
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

    // Active: glass 위에서 거의 흰 capsule로 또렷하게 강조
    final activePillColor = dark
        ? Colors.white.withValues(alpha: 0.90)
        : Colors.white.withValues(alpha: 0.92);
    final activeIconColor = Colors.black.withValues(alpha: 0.92);
    final inactiveIconColor = dark
        ? Colors.white.withValues(alpha: 0.55)
        : Colors.black.withValues(alpha: 0.45);

    return Semantics(
      label: tab.label,
      button: true,
      child: GestureDetector(
        key: tab.coachKey,
        onTap: tab.onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 50,
          height: 44,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: active ? 44 : 36,
              height: active ? 36 : 34,
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
