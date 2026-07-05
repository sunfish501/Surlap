import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../i18n/strings.dart';
import '../providers/view_provider.dart';
import 'coach_mark.dart';

// ─── Liquid Glass Floating Bottom Navigation (2026 리디자인) ─────
// 떠 있는 캡슐. 비활성 = 아이콘만, 활성 = 아이콘 + 라벨 알약(accent).
class SurlapBottomNav extends ConsumerWidget {
  const SurlapBottomNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(viewProvider);
    final notifier = ref.read(viewProvider.notifier);
    final sh = context.sh;
    final dark = sh.dark;

    final tabs = <_Tab>[
      _Tab(
        icon: Icons.home_rounded,
        label: tr('홈'),
        active: view.mode == ViewMode.home,
        onTap: () => notifier.setMode(ViewMode.home),
      ),
      _Tab(
        icon: Icons.calendar_month_rounded,
        label: tr('캘린더'),
        active: const {
          ViewMode.events,
          ViewMode.year,
          ViewMode.planner,
          ViewMode.day,
        }.contains(view.mode),
        onTap: () => notifier.setMode(ViewMode.events),
      ),
      _Tab(
        icon: Icons.grid_view_rounded,
        label: tr('스케줄'),
        active: view.mode == ViewMode.timetable,
        onTap: () => notifier.setMode(ViewMode.timetable),
        coachKey: coachKeyTabTimetable,
      ),
      _Tab(
        icon: Icons.palette_rounded,
        label: tr('공유'),
        active: view.mode == ViewMode.themes,
        onTap: () => notifier.setMode(ViewMode.themes),
      ),
      _Tab(
        icon: Icons.person_rounded,
        label: tr('프로필'),
        active: view.mode == ViewMode.profile ||
            view.mode == ViewMode.settings,
        onTap: () => notifier.setMode(ViewMode.profile),
        coachKey: coachKeyTabProfile,
      ),
    ];

    final accent = dark ? const Color(0xFFC9B6F0) : const Color(0xFF5A2DF4);
    final activeBg = dark
        ? const Color(0x388B6CFF) // .22
        : const Color(0x1F5A2DF4); // .12 — 액티브 알약 배경
    final inactive = dark
        ? Colors.white.withValues(alpha: 0.4)
        : const Color(0xFF14131A).withValues(alpha: 0.34);
    final tint = dark
        ? const Color(0xFF221E32).withValues(alpha: 0.6)
        : Colors.white.withValues(alpha: 0.74);
    final border = dark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFF14131A).withValues(alpha: 0.05);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 16,
      child: SafeArea(
        top: false,
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                key: coachKeyBottomNav,
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: border),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4A1FD0).withValues(alpha: 0.30),
                      blurRadius: 36,
                      offset: const Offset(0, 16),
                      spreadRadius: -16,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final t in tabs)
                      _NavItem(
                        tab: t,
                        accent: accent,
                        activeBg: activeBg,
                        inactive: inactive,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── nav 뒤 하단 scrim — 콘텐츠가 nav 뒤로 페이드 ──────────────────
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

class _Tab {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final GlobalKey? coachKey;

  const _Tab({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.coachKey,
  });
}

class _NavItem extends StatelessWidget {
  final _Tab tab;
  final Color accent;
  final Color activeBg;
  final Color inactive;
  const _NavItem({
    required this.tab,
    required this.accent,
    required this.activeBg,
    required this.inactive,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: tab.label,
      button: true,
      child: GestureDetector(
        key: tab.coachKey,
        onTap: tab.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          height: 40,
          padding: EdgeInsets.symmetric(horizontal: tab.active ? 15 : 0),
          constraints: BoxConstraints(minWidth: tab.active ? 0 : 44),
          decoration: BoxDecoration(
            color: tab.active ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(tab.icon, size: tab.active ? 23 : 24,
                  color: tab.active ? accent : inactive),
              if (tab.active) ...[
                const SizedBox(width: 6),
                Text(
                  tab.label,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: accent,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
