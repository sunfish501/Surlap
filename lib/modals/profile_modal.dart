import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';
import '../supabase/auth_service.dart';
import 'login_modal.dart';
import 'backup_modal.dart';

Future<void> showProfileModal(BuildContext context) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ProfileModal(),
    );

class ProfileModal extends ConsumerWidget {
  const ProfileModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sh = context.sh;
    final user = ref.watch(authProvider);
    final isLoggedIn = user != null;
    final displayName = isLoggedIn ? userDisplayName(user) : '로그인 안 됨';

    return FractionallySizedBox(
      heightFactor: 0.6,
      child: Container(
        decoration: BoxDecoration(
          color: sh.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // 그랩 핸들
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: sh.ink.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 10),
              child: Row(children: [
                Text('프로필 설정',
                    style: AppType.section.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: sh.ink)),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: sh.inkSoft, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ]),
            ),
            Divider(color: sh.border, height: 1),
            // 아바타 + 이름
            Padding(
              padding: const EdgeInsets.all(Gap.xl),
              child: Row(children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: sh.accentBg, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(
                    isLoggedIn && displayName.isNotEmpty
                        ? displayName[0].toUpperCase() : '👤',
                    style: AppType.title.copyWith(color: sh.accentInk,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(isLoggedIn ? displayName : '로그인 없이 사용 중',
                      style: AppType.section.copyWith(fontWeight: FontWeight.w700, color: sh.ink)),
                  if (user?.email != null)
                    Text(user!.email!, style: AppType.caption.copyWith(color: sh.inkSoft)),
                ]),
              ]),
            ),
            Divider(color: sh.border, height: 1),
            _Row(
              icon: Icons.backup_outlined,
              label: '정보 백업',
              sh: sh,
              onTap: () {
                Navigator.pop(context);
                showBackupModal(context);
              },
            ),
            if (!isLoggedIn)
              _Row(
                icon: Icons.login_rounded,
                label: '로그인하여 클라우드 동기화',
                sh: sh,
                onTap: () {
                  Navigator.pop(context);
                  showLoginModal(context);
                },
              )
            else
              _Row(
                icon: Icons.logout_rounded,
                label: '로그아웃',
                sh: sh,
                color: sh.danger,
                onTap: () async {
                  await ref.read(authProvider.notifier).signOut();
                  if (context.mounted) { Navigator.pop(context); }
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final SpaceHourColors sh;
  final Color? color;
  final VoidCallback onTap;
  const _Row({required this.icon, required this.label,
      required this.sh, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = color ?? sh.ink;
    return ListTile(
      leading: Icon(icon, color: c, size: 20),
      title: Text(label, style: AppType.body.copyWith(color: c)),
      trailing: Icon(Icons.chevron_right_rounded, color: sh.inkFaint, size: 18),
      onTap: onTap,
    );
  }
}
