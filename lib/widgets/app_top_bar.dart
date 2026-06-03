import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';
import '../widgets/coach_mark.dart';
import '../widgets/calendar_settings_sheet.dart';
import '../modals/theme_manager_modal.dart';
import '../modals/profile_modal.dart';
import '../utils/screenshot_util.dart';

// overlay 버튼 영역 높이 (status bar 제외)
const double kTopBarButtonH = 52.0;

enum _MoreAction { category, settings, profile }

// ─── 투명 상단 overlay 헤더 ──────────────────────────────────────
// Status bar 뒤쪽까지 자연스럽게 gradient가 깔리는 미니멀 상단 바.
// logo/앱이름 중앙 + 좌우 버튼만 표시. MainShell의 Positioned(top:0)에 배치.
class AppOverlayTopBar extends ConsumerWidget {
  const AppOverlayTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPad = MediaQuery.of(context).padding.top;
    final sh = context.sh;

    // 라이트 배경에서 자연스러운 페이드: 위(불투명) → 아래(투명)
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
                  // ── 왼쪽: 공유 ─────────────────────────────
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _TopIconBtn(
                      key: coachKeyBtnCategory,
                      icon: Icons.ios_share_outlined,
                      sh: sh,
                      onTap: captureAndShare,
                    ),
                  ),
                  // ── 중앙: 로고 (이미지 + 워드마크) ──────────
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          height: 24,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: Gap.xs),
                        Text(
                          'HourSpace',
                          style: AppType.body.copyWith(
                            fontWeight: FontWeight.w700,
                            color: sh.ink,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ── 오른쪽: 더보기 ─────────────────────────
                  Align(
                    alignment: Alignment.centerRight,
                    child: _TopIconBtn(
                      key: coachKeyBtnSettings,
                      icon: Icons.more_horiz,
                      sh: sh,
                      onTap: () => _openMore(context, ref, sh),
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

  void _openMore(BuildContext context, WidgetRef ref, SpaceHourColors sh) {
    showModalBottomSheet<_MoreAction>(
      context: context,
      builder: (_) => const _OverlayMoreSheet(),
    ).then((action) {
      if (action == null || !context.mounted) return;
      switch (action) {
        case _MoreAction.category:
          showThemeManagerModal(context);
        case _MoreAction.settings:
          showCalendarSettingsSheet(context);
        case _MoreAction.profile:
          showProfileModal(context);
      }
    });
  }
}

// ─── 아이콘 버튼 ─────────────────────────────────────────────────
class _TopIconBtn extends StatelessWidget {
  final IconData icon;
  final SpaceHourColors sh;
  final VoidCallback onTap;
  const _TopIconBtn({super.key, required this.icon, required this.sh, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: kMinTouch,
      height: kMinTouch,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kMinTouch / 2),
        // 보조 액션 — 시각적으로 약하게
        child: Center(child: Icon(icon, size: 19, color: sh.inkFaint)),
      ),
    );
  }
}

// ─── 더보기 시트 ─────────────────────────────────────────────────
class _OverlayMoreSheet extends StatelessWidget {
  const _OverlayMoreSheet();

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    return Container(
      color: sh.card,
      padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.md, Gap.xl, Gap.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            minLeadingWidth: Gap.xl,
            leading: Icon(Icons.label_outline_rounded, size: 20, color: sh.inkSoft),
            title: Text('카테고리 관리', style: AppType.body.copyWith(color: sh.ink)),
            trailing: Icon(Icons.chevron_right_rounded, size: 18, color: sh.inkFaint),
            onTap: () => Navigator.pop(context, _MoreAction.category),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            minLeadingWidth: Gap.xl,
            leading: Icon(Icons.settings_outlined, size: 20, color: sh.inkSoft),
            title: Text('설정', style: AppType.body.copyWith(color: sh.ink)),
            trailing: Icon(Icons.chevron_right_rounded, size: 18, color: sh.inkFaint),
            onTap: () => Navigator.pop(context, _MoreAction.settings),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            minLeadingWidth: Gap.xl,
            leading: Icon(Icons.person_outline_rounded, size: 20, color: sh.inkSoft),
            title: Text('프로필', style: AppType.body.copyWith(color: sh.ink)),
            trailing: Icon(Icons.chevron_right_rounded, size: 18, color: sh.inkFaint),
            onTap: () => Navigator.pop(context, _MoreAction.profile),
          ),
        ],
      ),
    );
  }
}
