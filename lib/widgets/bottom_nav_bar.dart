import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';
import '../core/utils/date_utils.dart' as du;
import '../providers/view_provider.dart';
import '../providers/color_preset_provider.dart';
import '../widgets/sidebar_drawer.dart';
import 'coach_mark.dart';

// ─── 하단 네비 (5탭) — 스킬셋 2026 구조 ─────────────────────────
// 홈 / 캘린더 / 시간표 / 기록 / 설정
class SpaceHourBottomNav extends ConsumerWidget {
  const SpaceHourBottomNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view     = ref.watch(viewProvider);
    final notifier = ref.read(viewProvider.notifier);
    final preset   = ref.watch(colorPresetProvider);
    final sh       = context.sh;

    final accent = preset.accent;

    final isHome       = view.mode == ViewMode.home;
    final isCalendar   = const {
      ViewMode.events, ViewMode.year, ViewMode.planner
    }.contains(view.mode);
    final isTimetable  = view.mode == ViewMode.timetable;
    final isRecord     = view.mode == ViewMode.day;

    String todayKey() {
      final n = DateTime.now();
      return du.toDateKey(n);
    }

    return Positioned(
      left: 0, right: 0, bottom: 16,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              key: coachKeyBottomNav,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              decoration: BoxDecoration(
                color: sh.dark
                    ? Colors.black.withValues(alpha: 0.72)
                    : Colors.white.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                    color: Colors.black.withValues(alpha: 0.06), width: 0.5),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x24000000),
                      blurRadius: 28,
                      offset: Offset(0, 8)),
                  BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 6,
                      offset: Offset(0, 2)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ─── 홈 ───
                  _NavTab(
                    icon: const Icon(Icons.home_outlined, size: 22),
                    label: '홈',
                    active: isHome,
                    accent: accent,
                    onTap: () => notifier.setMode(ViewMode.home),
                  ),
                  // ─── 캘린더 ───
                  _NavTab(
                    icon: const Icon(Icons.calendar_month_outlined, size: 22),
                    label: '캘린더',
                    active: isCalendar,
                    accent: accent,
                    onTap: () {
                      if (!isCalendar) notifier.setMode(ViewMode.events);
                    },
                  ),
                  // ─── 시간표 ───
                  _NavTab(
                    key: coachKeyTabTimetable,
                    icon: const Icon(Icons.grid_view_rounded, size: 22),
                    label: '시간표',
                    active: isTimetable,
                    accent: accent,
                    onTap: () => notifier.setMode(ViewMode.timetable),
                  ),
                  // ─── 기록 (오늘 일별 뷰) ───
                  _NavTab(
                    key: coachKeyTabProfile,
                    icon: const Icon(Icons.edit_note_rounded, size: 22),
                    label: '기록',
                    active: isRecord,
                    accent: accent,
                    onTap: () => notifier.setDayView(todayKey()),
                  ),
                  // ─── 설정 ───
                  _NavTab(
                    icon: const Icon(Icons.settings_outlined, size: 22),
                    label: '설정',
                    active: false,
                    accent: accent,
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const FractionallySizedBox(
                        heightFactor: 0.85,
                        child: SidebarDrawer(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── 탭 아이템 ───────────────────────────────────────────────────
class _NavTab extends StatelessWidget {
  final Widget icon;
  final String label;
  final bool active;
  final Color accent;
  final VoidCallback onTap;

  const _NavTab({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.accent,
    required this.onTap,
  });

  static const _inactive = Color(0xFF82828A);

  @override
  Widget build(BuildContext context) {
    final color = active ? accent : _inactive;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        constraints: const BoxConstraints(minWidth: 58),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: active ? accent.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconTheme(
              data: IconThemeData(color: color, size: 22),
              child: icon,
            ),
            const SizedBox(height: 3),
            Text(label,
                style: AppType.label.copyWith(
                    fontWeight: FontWeight.w600, color: color, height: 1)),
          ],
        ),
      ),
    );
  }
}
