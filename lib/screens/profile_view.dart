import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';
import '../i18n/strings.dart';
import '../modals/backup_modal.dart';
import '../providers/color_preset_provider.dart';
import '../providers/view_provider.dart';
import '../supabase/auth_service.dart';
import 'login/login_screen.dart';
import 'settings_view.dart' show SettingsSections;

/// 마이 탭. 계정과 앱 설정의 진입점을 한 화면에 모은다.
class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sh = context.sh;
    final user = ref.watch(authProvider);
    final loggedIn = user != null;
    final isDark = ref.watch(colorPresetProvider).dark;

    return ListView(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, Gap.xxl),
      children: [
        _AccountCard(
          sh: sh,
          loggedIn: loggedIn,
          name: loggedIn ? userDisplayName(user) : tr('로그인하고 동기화하기'),
          email: loggedIn ? (user.email ?? '') : tr('일정과 데이터를 안전하게 보관하세요'),
          onTap: loggedIn ? null : () => showLoginScreen(context),
        ),
        const SizedBox(height: Gap.xl),
        _SettingsGroup(
          sh: sh,
          label: tr('일반'),
          children: [
            _SettingsTile(
              sh: sh,
              icon: isDark
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
              title: tr('다크 모드'),
              trailing: Switch.adaptive(
                value: isDark,
                activeThumbColor: Colors.white,
                activeTrackColor: sh.accent,
                inactiveThumbColor: sh.inkFaint,
                inactiveTrackColor: sh.border,
                onChanged: (value) =>
                    ref.read(colorPresetProvider.notifier).setDark(value),
              ),
            ),
            _SettingsTile(
              sh: sh,
              icon: Icons.tune_rounded,
              title: tr('앱 설정'),
              subtitle: tr('언어, 알림, 보기 옵션'),
              onTap: () => _showSettingsSheet(context),
            ),
          ],
        ),
        const SizedBox(height: Gap.xl),
        _SettingsGroup(
          sh: sh,
          label: tr('연동'),
          children: [
            _SettingsTile(
              sh: sh,
              icon: Icons.calendar_month_outlined,
              title: tr('공유 및 구독'),
              subtitle: tr('캘린더 공유, 스포츠 구독'),
              onTap: () =>
                  ref.read(viewProvider.notifier).setMode(ViewMode.themes),
            ),
          ],
        ),
        const SizedBox(height: Gap.xl),
        _SettingsGroup(
          sh: sh,
          label: tr('데이터'),
          children: [
            _SettingsTile(
              sh: sh,
              icon: Icons.cloud_upload_outlined,
              title: tr('백업 및 복원'),
              onTap: () => showBackupModal(context),
            ),
            if (loggedIn) ...[
              _SettingsTile(
                sh: sh,
                icon: Icons.logout_rounded,
                title: tr('로그아웃'),
                onTap: () => ref.read(authProvider.notifier).signOut(),
              ),
              _SettingsTile(
                sh: sh,
                icon: Icons.person_remove_outlined,
                title: tr('회원 탈퇴'),
                foregroundColor: sh.danger,
                onTap: () => _confirmDeleteAccount(context, ref),
              ),
            ] else
              _SettingsTile(
                sh: sh,
                icon: Icons.login_rounded,
                title: tr('로그인'),
                onTap: () => showLoginScreen(context),
              ),
          ],
        ),
      ],
    );
  }

  void _showSettingsSheet(BuildContext context) {
    final sh = context.sh;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: sh.bg,
      showDragHandle: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.xxl),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: Gap.lg),
              child: Text(
                tr('앱 설정'),
                style: AppType.titleLarge.copyWith(color: sh.ink),
              ),
            ),
            const SettingsSections(),
          ],
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.sh,
    required this.loggedIn,
    required this.name,
    required this.email,
    required this.onTap,
  });

  final SurlapColors sh;
  final bool loggedIn;
  final String name;
  final String email;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final initial = loggedIn && name.trim().isNotEmpty
        ? name.trim().characters.first.toUpperCase()
        : null;

    return Material(
      color: sh.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
        side: BorderSide(color: sh.border, width: Borders.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Gap.lg),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: sh.accent,
                  shape: BoxShape.circle,
                ),
                child: initial != null
                    ? Text(
                        initial,
                        style: AppType.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : const Icon(
                        Icons.person_outline_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
              ),
              const SizedBox(width: Gap.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.titleMedium.copyWith(color: sh.ink),
                    ),
                    const SizedBox(height: Gap.xs),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.bodySmall.copyWith(color: sh.inkSoft),
                    ),
                  ],
                ),
              ),
              if (!loggedIn)
                Icon(Icons.chevron_right_rounded, color: sh.inkFaint, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({
    required this.sh,
    required this.label,
    required this.children,
  });

  final SurlapColors sh;
  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Gap.xs, 0, Gap.xs, Gap.sm),
          child: Text(
            label.toUpperCase(),
            style: AppType.eyebrow.copyWith(color: sh.inkSoft),
          ),
        ),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: sh.card,
            borderRadius: BorderRadius.circular(Radii.card),
            border: Border.all(color: sh.border, width: Borders.hairline),
          ),
          child: Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index != children.length - 1)
                  Divider(
                    height: Borders.divider,
                    thickness: Borders.hairline,
                    indent: 56,
                    color: sh.border,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.sh,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.foregroundColor,
  });

  final SurlapColors sh;
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final foreground = foregroundColor ?? sh.ink;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 58),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Gap.md,
              vertical: Gap.sm,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Icon(icon, size: 20, color: foreground),
                ),
                const SizedBox(width: Gap.md),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppType.bodyLarge.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: AppType.bodySmall.copyWith(color: sh.inkSoft),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null)
                  trailing!
                else if (onTap != null)
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: sh.inkFaint,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(tr('회원 탈퇴')),
      content: Text(tr('계정과 클라우드에 저장된 데이터가 영구적으로 삭제돼요.\n이 작업은 되돌릴 수 없어요.')),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(tr('취소')),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: TextButton.styleFrom(foregroundColor: context.sh.danger),
          child: Text(tr('탈퇴')),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(authProvider.notifier).deleteAccount();
    messenger.showSnackBar(SnackBar(content: Text(tr('계정이 삭제되었어요'))));
  } catch (error) {
    messenger.showSnackBar(SnackBar(content: Text('${tr('탈퇴 실패')}: $error')));
  }
}
