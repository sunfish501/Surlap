import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';
import '../providers/color_preset_provider.dart';
import '../providers/view_provider.dart';
import '../supabase/auth_service.dart';
import '../modals/backup_modal.dart';
import 'login/login_screen.dart';
import 'settings_view.dart' show SettingsSectionCard, SettingsRow;

/// 프로필 — 하단 nav 5번째 탭의 in-shell 뷰.
/// 계정 정보 + 설정 진입 + 다크모드 토글 + 백업/로그인.
class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sh = context.sh;
    final user = ref.watch(authProvider);
    final loggedIn = user != null;
    final isDark = ref.watch(colorPresetProvider).dark;

    return ListView(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, 120),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
          child: Text('프로필',
              style: AppType.title.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: sh.ink)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
          child: Text('내 계정과 앱 설정을 한곳에서',
              style: AppType.body.copyWith(color: sh.inkSoft)),
        ),

        // ── 계정 카드 ──
        _AccountCard(
          sh: sh,
          loggedIn: loggedIn,
          name: loggedIn ? userDisplayName(user) : '로그인하고 동기화하기',
          email: loggedIn ? (user.email ?? '') : '일정·시간표·테마를 기기 간 동기화',
          onTap: () => loggedIn ? null : showLoginScreen(context),
        ),
        const SizedBox(height: 18),

        // ── 앱 설정 ──
        SettingsSectionCard(
          sh: sh,
          title: '앱',
          child: Column(
            children: [
              SettingsRow(
                sh: sh,
                icon: Icons.settings_outlined,
                title: '설정',
                onTap: () =>
                    ref.read(viewProvider.notifier).setMode(ViewMode.settings),
              ),
              SettingsRow(
                sh: sh,
                icon: isDark
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded,
                title: '다크 모드',
                trailing: Switch.adaptive(
                  value: isDark,
                  activeThumbColor: sh.accent,
                  onChanged: (v) =>
                      ref.read(colorPresetProvider.notifier).setDark(v),
                ),
              ),
              SettingsRow(
                sh: sh,
                icon: Icons.backup_outlined,
                title: '정보 백업',
                onTap: () => showBackupModal(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── 계정 ──
        SettingsSectionCard(
          sh: sh,
          title: '계정',
          child: loggedIn
              ? SettingsRow(
                  sh: sh,
                  icon: Icons.logout_rounded,
                  title: '로그아웃',
                  onTap: () => ref.read(authProvider.notifier).signOut(),
                )
              : SettingsRow(
                  sh: sh,
                  icon: Icons.login_rounded,
                  title: '로그인하여 클라우드 동기화',
                  onTap: () => showLoginScreen(context),
                ),
        ),
      ],
    );
  }
}

// ── 계정 hero 카드 ──
class _AccountCard extends StatelessWidget {
  final SpaceHourColors sh;
  final bool loggedIn;
  final String name;
  final String email;
  final VoidCallback? onTap;

  const _AccountCard({
    required this.sh,
    required this.loggedIn,
    required this.name,
    required this.email,
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
                  Text(email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.label.copyWith(
                          fontSize: 12.5,
                          color: sh.ink.withValues(alpha: 0.55))),
                ],
              ),
            ),
            if (!loggedIn)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: sh.accent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('로그인',
                    style: AppType.label.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }
}
