import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';
import '../widgets/coach_mark.dart';
import '../providers/view_provider.dart';
import '../utils/screenshot_util.dart';

// overlay 버튼 영역 높이 (status bar 제외)
const double kTopBarButtonH = 52.0;

// 달력 계열 뷰에서만 뷰 전환(점세개) 노출.
const _calendarModes = {
  ViewMode.events,
  ViewMode.year,
  ViewMode.planner,
  ViewMode.day,
};

// ─── 투명 상단 overlay 헤더 ──────────────────────────────────────
// Status bar 뒤쪽까지 자연스럽게 gradient가 깔리는 미니멀 상단 바.
// 좌: 이미지 저장 / 중앙: 로고 / 우: 뷰 전환(달력뷰 한정).
class AppOverlayTopBar extends ConsumerWidget {
  const AppOverlayTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPad = MediaQuery.of(context).padding.top;
    final sh = context.sh;
    final mode = ref.watch(viewProvider).mode;
    final showSwitcher = _calendarModes.contains(mode);

    final gradientColors = [
      sh.bg.withValues(alpha: 0.96),
      sh.bg.withValues(alpha: 0.82),
      sh.bg.withValues(alpha: 0.0),
    ];

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            height: topPad + kTopBarButtonH,
            padding: EdgeInsets.only(top: topPad, left: Gap.xl, right: Gap.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: gradientColors,
                stops: const [0.0, 0.65, 1.0],
              ),
            ),
            child: SizedBox(
              height: kTopBarButtonH,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // ── 왼쪽: 이미지로 저장 (스케줄표에서만) ──────────
                  Align(
                    alignment: Alignment.centerLeft,
                    child: mode == ViewMode.timetable
                        ? _TopIconBtn(
                            key: coachKeyBtnCategory,
                            icon: Icons.save_alt_rounded,
                            sh: sh,
                            onTap: captureAndSaveImage,
                          )
                        : const SizedBox(width: kMinTouch),
                  ),
                  // ── 중앙: (로고 제거 — 추후 다른 요소 배치 예정) ──
                  // ── 오른쪽: 뷰 전환 (달력뷰에서만) ───────────────
                  Align(
                    alignment: Alignment.centerRight,
                    child: showSwitcher
                        ? _TopIconBtn(
                            key: coachKeyBtnSettings,
                            icon: Icons.more_vert,
                            sh: sh,
                            onTap: () => _openViewSwitcher(context, ref, mode),
                          )
                        : const SizedBox(width: kMinTouch),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openViewSwitcher(BuildContext context, WidgetRef ref, ViewMode current) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => _ViewSwitcherSheet(current: current),
    );
  }
}

// ─── 아이콘 버튼 ─────────────────────────────────────────────────
class _TopIconBtn extends StatelessWidget {
  final IconData icon;
  final SpaceHourColors sh;
  final VoidCallback onTap;
  const _TopIconBtn(
      {super.key, required this.icon, required this.sh, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: kMinTouch,
      height: kMinTouch,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kMinTouch / 2),
        child: Center(child: Icon(icon, size: 20, color: sh.inkSoft)),
      ),
    );
  }
}

// ─── 뷰 전환 시트 (연간/월간/주간/일간) ──────────────────────────
class _ViewSwitcherSheet extends ConsumerWidget {
  final ViewMode current;
  const _ViewSwitcherSheet({required this.current});

  String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sh = context.sh;
    final notifier = ref.read(viewProvider.notifier);

    final items = [
      (label: '연간', icon: Icons.calendar_view_month_rounded,
          mode: ViewMode.year, onTap: () => notifier.setMode(ViewMode.year)),
      (label: '월간', icon: Icons.calendar_month_rounded,
          mode: ViewMode.events, onTap: () => notifier.setMode(ViewMode.events)),
      (label: '주간', icon: Icons.view_week_rounded,
          mode: ViewMode.planner,
          onTap: () => notifier.setWeekView(_todayKey())),
      (label: '일간', icon: Icons.view_day_rounded,
          mode: ViewMode.day, onTap: () => notifier.setDayView(_todayKey())),
    ];

    return Container(
      color: sh.card,
      padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.md, Gap.xl, Gap.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('보기 전환',
                style: AppType.label.copyWith(
                    fontWeight: FontWeight.w700, color: sh.inkSoft)),
          ),
          ...items.map((it) {
            final active = it.mode == current;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              minLeadingWidth: Gap.xl,
              leading: Icon(it.icon,
                  size: 21, color: active ? sh.accent : sh.inkSoft),
              title: Text(it.label,
                  style: AppType.body.copyWith(
                      color: active ? sh.accent : sh.ink,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w500)),
              trailing: active
                  ? Icon(Icons.check_rounded, size: 18, color: sh.accent)
                  : null,
              onTap: () {
                Navigator.pop(context);
                it.onTap();
              },
            );
          }),
        ],
      ),
    );
  }
}
