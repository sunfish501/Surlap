import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';
import '../i18n/strings.dart';
import '../providers/color_preset_provider.dart';
import '../providers/view_provider.dart';
import '../supabase/auth_service.dart';

/// Surlap v2.1의 유일한 전역 내비게이션.
/// 하단 탭을 대신해 홈·캘린더·시간표·공유 및 구독·마이 5개 목적지만 노출한다.
class SurlapNavigationDrawer extends ConsumerWidget {
  const SurlapNavigationDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sh = context.sh;
    final view = ref.watch(viewProvider);
    final user = ref.watch(authProvider);
    final isDark = ref.watch(colorPresetProvider).dark;
    final name = user == null ? 'Surlap' : userDisplayName(user);
    final subtitle = user?.email ?? tr('나만의 일정과 시간표');
    final initial = name.trim().isEmpty ? 'S' : name.trim().characters.first;

    return Drawer(
      width: 240,
      elevation: 0,
      backgroundColor: sh.card,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Gap.md, Gap.lg, Gap.md, Gap.md),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(Gap.sm, Gap.xs, Gap.sm, 14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: sh.accent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        initial,
                        style: AppType.bodyLarge.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.bodyLarge.copyWith(
                              color: sh.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.labelMedium.copyWith(
                              color: sh.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, thickness: Borders.divider, color: sh.border),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _DrawerDestination(
                      icon: Icons.home_outlined,
                      selectedIcon: Icons.home_rounded,
                      label: tr('홈'),
                      selected: view.mode == ViewMode.home,
                      onTap: () => _go(context, ref, ViewMode.home),
                    ),
                    _DrawerDestination(
                      icon: Icons.calendar_month_outlined,
                      selectedIcon: Icons.calendar_month_rounded,
                      label: tr('캘린더'),
                      selected: const {
                        ViewMode.events,
                        ViewMode.year,
                        ViewMode.planner,
                        ViewMode.day,
                      }.contains(view.mode),
                      onTap: () => _go(context, ref, ViewMode.events),
                    ),
                    _DrawerDestination(
                      icon: Icons.view_timeline_outlined,
                      selectedIcon: Icons.view_timeline_rounded,
                      label: tr('시간표'),
                      selected: view.mode == ViewMode.timetable,
                      onTap: () => _go(context, ref, ViewMode.timetable),
                    ),
                    _DrawerDestination(
                      icon: Icons.share_outlined,
                      selectedIcon: Icons.share_rounded,
                      label: tr('공유 및 구독'),
                      selected: view.mode == ViewMode.themes,
                      onTap: () => _go(context, ref, ViewMode.themes),
                    ),
                    _DrawerDestination(
                      icon: Icons.person_outline_rounded,
                      selectedIcon: Icons.person_rounded,
                      label: tr('마이'),
                      selected:
                          view.mode == ViewMode.profile ||
                          view.mode == ViewMode.settings,
                      onTap: () => _go(context, ref, ViewMode.profile),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, thickness: Borders.divider, color: sh.border),
              Semantics(
                label: tr('다크 모드'),
                toggled: isDark,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(Radii.small),
                    onTap: () =>
                        ref.read(colorPresetProvider.notifier).setDark(!isDark),
                    child: SizedBox(
                      height: 52,
                      child: Row(
                        children: [
                          Icon(
                            Icons.dark_mode_outlined,
                            size: 20,
                            color: sh.inkSoft,
                          ),
                          const SizedBox(width: Gap.md),
                          Expanded(
                            child: Text(
                              tr('다크 모드'),
                              style: AppType.bodyLarge.copyWith(color: sh.ink),
                            ),
                          ),
                          ExcludeSemantics(
                            child: IgnorePointer(
                              child: Switch.adaptive(
                                value: isDark,
                                activeThumbColor: sh.accent,
                                onChanged: (_) {},
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _go(BuildContext context, WidgetRef ref, ViewMode mode) {
    Navigator.of(context).pop();
    ref.read(viewProvider.notifier).setMode(mode);
  }
}

class _DrawerDestination extends StatelessWidget {
  const _DrawerDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Semantics(
        selected: selected,
        button: true,
        label: label,
        child: Material(
          color: selected
              ? sh.accent.withValues(alpha: sh.dark ? 0.18 : 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: kMinTouch),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Gap.md),
                child: Row(
                  children: [
                    Icon(
                      selected ? selectedIcon : icon,
                      size: 20,
                      color: selected ? sh.accent : sh.inkSoft,
                    ),
                    const SizedBox(width: Gap.md),
                    Text(
                      label,
                      style: AppType.bodyLarge.copyWith(
                        color: selected ? sh.accent : sh.ink,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
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
