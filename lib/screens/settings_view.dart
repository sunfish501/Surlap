import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';
import '../providers/settings_provider.dart';
import '../providers/themes_provider.dart';
import '../providers/filter_provider.dart';
import '../providers/birthdays_provider.dart';
import '../providers/view_provider.dart';
import '../providers/academic_schedule_provider.dart';
import '../supabase/auth_service.dart';
import '../modals/neis_setup_modal.dart';
import '../modals/birthday_manager_modal.dart';
import '../modals/profile_modal.dart';
import '../modals/login_dialog.dart';
import '../widgets/coach_mark.dart';

/// 보기 설정 — 하단 nav의 한 탭으로, 다른 뷰처럼 좌우 viewer(AnimatedSwitcher)
/// 안에서 전환되는 in-shell 뷰. (push 페이지 아님 → 자체 헤더를 그린다)
class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sh = context.sh;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final themes = ref.watch(themesProvider);
    final hidden = ref.watch(filterProvider);
    final birthdays = ref.watch(birthdaysProvider);
    final user = ref.watch(authProvider);
    final loggedIn = user != null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, 120),
      children: [
        // ── 자체 헤더 (뒤로 → 프로필) ──
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 4, 4),
          child: Row(
            children: [
              GestureDetector(
                onTap: () =>
                    ref.read(viewProvider.notifier).setMode(ViewMode.profile),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      size: 20, color: sh.ink),
                ),
              ),
              Text('설정',
                  style: AppType.title.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: sh.ink)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
          child: Text('내 계정과 캘린더 표시 방식을 한곳에서',
              style: AppType.body.copyWith(color: sh.inkSoft)),
        ),

        // ── 계정 hero 카드 (Airbnb 톤) ──
        _AccountCard(
          sh: sh,
          loggedIn: loggedIn,
          name: loggedIn ? userDisplayName(user) : '로그인하고 동기화하기',
          subtitle: loggedIn
              ? '모든 기기에서 안전하게 동기화 중'
              : '일정 · 시간표 · 테마를 기기 간 동기화해요',
          onTap: () =>
              loggedIn ? showProfileModal(context) : showLoginDialog(context),
        ),
        const SizedBox(height: 18),

        // ── 카테고리 ──
        SettingsSectionCard(
          sh: sh,
          title: '카테고리',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              CategoryFilterChip(
                label: '전체',
                color: sh.inkSoft,
                selected: hidden.isEmpty,
                sh: sh,
                onTap: () {
                  final f = ref.read(filterProvider.notifier);
                  if (hidden.isEmpty) {
                    f.setAll(themes.map((t) => t.id).toList());
                  } else {
                    f.clear();
                  }
                },
              ),
              ...themes.map((t) => CategoryFilterChip(
                    label: t.name,
                    color: t.colorValue,
                    selected: !hidden.contains(t.id),
                    sh: sh,
                    onTap: () =>
                        ref.read(filterProvider.notifier).toggle(t.id),
                  )),
              // 생일 — 별도 카테고리. 등록된 생일이 있을 때만 노출.
              if (birthdays.isNotEmpty)
                CategoryFilterChip(
                  label: '생일',
                  color: sh.birthdayColor,
                  selected: !hidden.contains(birthdayThemeId),
                  sh: sh,
                  onTap: () => ref
                      .read(filterProvider.notifier)
                      .toggle(birthdayThemeId),
                ),
              // 학사일정(NEIS) — 별도 카테고리. 데이터가 있을 때만 노출.
              if (ref.watch(academicScheduleProvider).isNotEmpty)
                CategoryFilterChip(
                  label: '학사일정',
                  color: sh.academicColor,
                  selected: !hidden.contains(academicThemeId),
                  sh: sh,
                  onTap: () => ref
                      .read(filterProvider.notifier)
                      .toggle(academicThemeId),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── 보기 옵션 ──
        SettingsSectionCard(
          sh: sh,
          title: '보기 옵션',
          child: Column(
            children: [
              SettingsRow(
                sh: sh,
                icon: Icons.history_rounded,
                title: '지난 날 표시',
                trailing: _IosSwitch(
                    value: settings.showPast,
                    onChanged: notifier.setShowPast,
                    sh: sh),
              ),
              SettingsRow(
                sh: sh,
                icon: Icons.notifications_outlined,
                title: '알림',
                trailing: _IosSwitch(
                    value: settings.notifyEnabled,
                    onChanged: notifier.setNotify,
                    sh: sh),
              ),
              SettingsRow(
                sh: sh,
                icon: Icons.view_stream_outlined,
                title: '연속 보기',
                trailing: _IosSwitch(
                    value: settings.continuousView,
                    onChanged: notifier.setContinuousView,
                    sh: sh),
              ),
              SettingsRow(
                sh: sh,
                icon: Icons.calendar_today_outlined,
                title: '주 시작일',
                trailing: _WeekStartPill(
                    dow: settings.weekStartDow,
                    onSelected: notifier.setWeekStart,
                    sh: sh),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── 더보기 ──
        SettingsSectionCard(
          sh: sh,
          title: '더보기',
          child: Column(
            children: [
              SettingsRow(
                sh: sh,
                icon: Icons.lightbulb_outline_rounded,
                title: '사용법 안내',
                onTap: () {
                  // 코치마크는 루트(하단 nav)를 가리킨다. settings는 이제 뷰이므로
                  // 페이지를 닫을 필요 없이 루트 컨텍스트로 바로 표시한다.
                  final rootCtx =
                      Navigator.of(context, rootNavigator: true).context;
                  showCoachMarks(rootCtx);
                },
              ),
              SettingsRow(
                sh: sh,
                icon: Icons.school_outlined,
                title: '학교 연결 (NEIS)',
                onTap: () => showNeisSetupModal(context),
              ),
              SettingsRow(
                sh: sh,
                icon: Icons.cake_outlined,
                title: birthdays.isEmpty
                    ? '생일 챙기기'
                    : '생일 챙기기 (${birthdays.length}명)',
                onTap: () => showBirthdayManagerModal(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── 계정 hero 카드 ──────────────────────────────────────────────
class _AccountCard extends StatelessWidget {
  final SpaceHourColors sh;
  final bool loggedIn;
  final String name;
  final String subtitle;
  final VoidCallback onTap;

  const _AccountCard({
    required this.sh,
    required this.loggedIn,
    required this.name,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initial =
        loggedIn && name.isNotEmpty ? name.substring(0, 1).toUpperCase() : null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              sh.accent.withValues(alpha: 0.14),
              sh.accent.withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: sh.accent.withValues(alpha: 0.16)),
        ),
        child: Row(
          children: [
            // 아바타
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: sh.accent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: sh.accent.withValues(alpha: 0.32),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: initial != null
                  ? Text(initial,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800))
                  : const Icon(Icons.person_rounded,
                      color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            // 이름 + 부제
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.title.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: sh.ink)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (loggedIn) ...[
                        Icon(Icons.cloud_done_rounded,
                            size: 13, color: sh.accent),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.label.copyWith(
                                fontSize: 12.5,
                                color: sh.ink.withValues(alpha: 0.55))),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // CTA pill
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: loggedIn ? sh.ink.withValues(alpha: 0.05) : sh.accent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(loggedIn ? '관리' : '로그인',
                  style: AppType.label.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: loggedIn
                          ? sh.ink.withValues(alpha: 0.7)
                          : Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 섹션 카드 ───────────────────────────────────────────────────
class SettingsSectionCard extends StatelessWidget {
  final SpaceHourColors sh;
  final String title;
  final Widget child;
  const SettingsSectionCard(
      {super.key, required this.sh, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
          child: Text(title,
              style: AppType.label.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: sh.ink.withValues(alpha: 0.42))),
        ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: sh.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: sh.ink.withValues(alpha: 0.04)),
          ),
          child: child,
        ),
      ],
    );
  }
}

// ─── 카테고리 칩 ─────────────────────────────────────────────────
class CategoryFilterChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final SpaceHourColors sh;

  const CategoryFilterChip({
    super.key,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
    required this.sh,
  });

  @override
  Widget build(BuildContext context) {
    final brand = sh.accent;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? brand.withValues(alpha: 0.10)
              : sh.ink.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: selected ? brand.withValues(alpha: 0.28) : Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 7),
            Text(label,
                style: AppType.label.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? brand : sh.ink.withValues(alpha: 0.5))),
            if (selected) ...[
              const SizedBox(width: 6),
              Icon(Icons.check_rounded, size: 15, color: brand),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── 설정 행 ─────────────────────────────────────────────────────
class SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final SpaceHourColors sh;

  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    required this.sh,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 11),
        child: Row(
          children: [
            Icon(icon, size: 20, color: sh.ink.withValues(alpha: 0.48)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title,
                  style: AppType.body.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      color: sh.ink)),
            ),
            ?trailing,
            if (trailing == null && onTap != null)
              Icon(Icons.chevron_right_rounded, size: 20, color: sh.inkFaint),
          ],
        ),
      ),
    );
  }
}

// ─── iOS 스타일 스위치 ───────────────────────────────────────────
class _IosSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final SpaceHourColors sh;
  const _IosSwitch(
      {required this.value, required this.onChanged, required this.sh});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.88,
      child: Switch.adaptive(
        value: value,
        activeThumbColor: sh.accent,
        activeTrackColor: sh.accent.withValues(alpha: 0.24),
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: sh.ink.withValues(alpha: 0.10),
        onChanged: onChanged,
      ),
    );
  }
}

// ─── 주 시작일 pill ──────────────────────────────────────────────
class _WeekStartPill extends StatelessWidget {
  final int dow; // 0=일, 1=월, 6=토
  final ValueChanged<int> onSelected;
  final SpaceHourColors sh;
  const _WeekStartPill(
      {required this.dow, required this.onSelected, required this.sh});

  static const _labels = {1: '월요일', 0: '일요일', 6: '토요일'};

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      onSelected: onSelected,
      color: sh.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (_) => [
        for (final e in _labels.entries)
          PopupMenuItem(
            value: e.key,
            child: Text(e.value,
                style: AppType.body.copyWith(
                    color: sh.ink,
                    fontWeight:
                        e.key == dow ? FontWeight.w700 : FontWeight.w400)),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: sh.ink.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_labels[dow] ?? '월요일',
                style: AppType.body.copyWith(
                    fontSize: 14, fontWeight: FontWeight.w700, color: sh.ink)),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 18, color: sh.ink.withValues(alpha: 0.55)),
          ],
        ),
      ),
    );
  }
}

