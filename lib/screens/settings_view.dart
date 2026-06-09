import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';
import '../providers/settings_provider.dart';
import '../providers/themes_provider.dart';
import '../providers/filter_provider.dart';
import '../providers/birthdays_provider.dart';
import '../providers/academic_schedule_provider.dart';
import '../providers/user_type_provider.dart';
import '../models/user_type.dart';
import '../supabase/neis_service.dart';
import '../modals/neis_setup_modal.dart';
import '../modals/birthday_manager_modal.dart';
import '../widgets/coach_mark.dart';
import '../widgets/school_logo.dart';
import 'feature_intro/feature_intro_screen.dart';

/// 보기 설정 — 하단 nav의 한 탭으로, 다른 뷰처럼 좌우 viewer(AnimatedSwitcher)
/// 안에서 전환되는 in-shell 뷰. (push 페이지 아님 → 자체 헤더를 그린다)
/// 설정 섹션들 — 프로필 뷰 안에 인라인으로 들어간다(별도 설정 화면 없음).
class SettingsSections extends ConsumerWidget {
  const SettingsSections({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sh = context.sh;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final themes = ref.watch(themesProvider);
    final hidden = ref.watch(filterProvider);
    final birthdays = ref.watch(birthdaysProvider);
    final userType = ref.watch(userTypeProvider);
    // 학교 연동(NEIS)은 초·중·고만. 유형 미선택(레거시)은 종전대로 노출.
    final showSchool = userType == null || userType.isSchoolStudent;
    final school = NeisSchool.load();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── 내 유형 ──
        SettingsSectionCard(
          sh: sh,
          title: '내 정보',
          child: SettingsRow(
            sh: sh,
            icon: Icons.badge_outlined,
            title: '내 유형',
            trailing: _TypePill(
                type: userType,
                sh: sh,
                onTap: () => _showTypePicker(context, ref, userType)),
            onTap: () => _showTypePicker(context, ref, userType),
          ),
        ),
        const SizedBox(height: 12),

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
                icon: Icons.auto_awesome_rounded,
                title: '기능 둘러보기',
                onTap: () => showFeatureIntro(context),
              ),
              if (showSchool)
                _SchoolRow(
                  sh: sh,
                  school: school,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            // 선택 표시는 채움/테두리/색으로만 — 체크 아이콘 제거(컴팩트).
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

// ─── 내 유형 pill ────────────────────────────────────────────────
class _TypePill extends StatelessWidget {
  final UserType? type;
  final SpaceHourColors sh;
  final VoidCallback onTap;
  const _TypePill({required this.type, required this.sh, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = type;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: sh.ink.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (t != null) ...[
              Text(t.emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
            ],
            Text(t?.label ?? '선택하기',
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

// 유형 선택 바텀시트.
void _showTypePicker(BuildContext context, WidgetRef ref, UserType? current) {
  const order = [
    UserType.elementary,
    UserType.middle,
    UserType.high,
    UserType.university,
    UserType.general,
  ];
  final sh = context.sh;
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      decoration: BoxDecoration(
        color: sh.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: sh.ink.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text('내 유형',
              style: AppType.section.copyWith(
                  fontSize: 18, fontWeight: FontWeight.w800, color: sh.ink)),
          const SizedBox(height: 4),
          Text('유형에 따라 급식·학교 연동 표시가 달라져요.',
              style: AppType.caption.copyWith(color: sh.inkSoft)),
          const SizedBox(height: 12),
          ...order.map((t) {
            final sel = t == current;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Text(t.emoji, style: const TextStyle(fontSize: 22)),
              title: Text(t.label,
                  style: AppType.body.copyWith(
                      fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                      color: sel ? sh.accentInk : sh.ink)),
              subtitle: Text(t.tagline,
                  style: AppType.label.copyWith(color: sh.inkSoft)),
              trailing: sel
                  ? Icon(Icons.check_circle_rounded, color: sh.accent, size: 20)
                  : null,
              onTap: () {
                ref.read(userTypeProvider.notifier).set(t);
                Navigator.pop(context);
              },
            );
          }),
        ],
      ),
    ),
  );
}

// ─── 학교 연결 행(로고/슬로건 표시) ────────────────────────────────
class _SchoolRow extends StatelessWidget {
  final SpaceHourColors sh;
  final NeisSchool? school;
  final VoidCallback onTap;
  const _SchoolRow({required this.sh, required this.school, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = school;
    if (s == null) {
      return SettingsRow(
        sh: sh,
        icon: Icons.school_outlined,
        title: '학교 연결 (NEIS)',
        onTap: onTap,
      );
    }
    final logo = s.logoUrl;
    final sub = s.slogan.isNotEmpty
        ? s.slogan
        : '${s.kind} · ${s.grade}학년 ${s.classNm}반';
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
        child: Row(
          children: [
            SchoolLogo(
              name: s.name,
              logoUrl: logo,
              fallbackUrl: s.logoFallbackUrl,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.body.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                          color: sh.ink)),
                  Text(sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.label.copyWith(
                          fontSize: 12, color: sh.inkSoft)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: sh.inkFaint),
          ],
        ),
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

