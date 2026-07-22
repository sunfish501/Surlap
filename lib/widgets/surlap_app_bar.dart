import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';
import '../core/utils/date_utils.dart' as du;
import '../i18n/dates.dart' as i18nd;
import '../i18n/strings.dart';
import '../providers/view_provider.dart';

class SurlapAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const SurlapAppBar({super.key, required this.onMenu, this.onSearch});

  final VoidCallback onMenu;
  final VoidCallback? onSearch;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sh = context.sh;
    final view = ref.watch(viewProvider);
    final searchable = const {
      ViewMode.home,
      ViewMode.events,
      ViewMode.year,
      ViewMode.planner,
      ViewMode.day,
      ViewMode.timetable,
    }.contains(view.mode);

    return Material(
      color: sh.bg,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: preferredSize.height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gap.md),
            child: Row(
              children: [
                _AppBarIconButton(
                  label: tr('메뉴 열기'),
                  icon: Icons.menu_rounded,
                  onTap: onMenu,
                ),
                const SizedBox(width: Gap.xs),
                Expanded(
                  child: Text(
                    _title(view),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.titleLarge.copyWith(
                      color: sh.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (searchable)
                  _AppBarIconButton(
                    label: tr('검색'),
                    icon: Icons.search_rounded,
                    onTap:
                        onSearch ??
                        () => ref.read(viewProvider.notifier).openSearch(),
                  ),
                if (view.mode == ViewMode.home)
                  _AppBarIconButton(
                    label: tr('알림 설정'),
                    icon: Icons.notifications_none_rounded,
                    onTap: () => ref
                        .read(viewProvider.notifier)
                        .setMode(ViewMode.profile),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _title(ViewState view) {
    final now = DateTime.now();
    switch (view.mode) {
      case ViewMode.home:
        return i18nd.fullDate(now);
      case ViewMode.events:
        return '${view.viewYear}${i18nd.yearWord} ${i18nd.monthName(view.viewMonth)}'
            .trim();
      case ViewMode.year:
        return '${view.viewYear}${i18nd.yearWord}';
      case ViewMode.planner:
        final d = _date(view.viewDay) ?? now;
        return '${d.month}월 ${(d.day - 1) ~/ 7 + 1}주';
      case ViewMode.day:
        return i18nd.fullDate(_date(view.viewDay) ?? now);
      case ViewMode.timetable:
        return tr('시간표');
      case ViewMode.themes:
        return tr('공유 및 구독');
      case ViewMode.profile:
      case ViewMode.settings:
        return tr('마이');
      case ViewMode.search:
        return tr('검색');
    }
  }

  DateTime? _date(String? key) {
    if (key == null || key.isEmpty) return null;
    try {
      return du.fromDateKey(key);
    } catch (_) {
      return null;
    }
  }
}

class _AppBarIconButton extends StatelessWidget {
  const _AppBarIconButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    return Semantics(
      button: true,
      label: label,
      child: IconButton(
        tooltip: label,
        constraints: const BoxConstraints.tightFor(
          width: kMinTouch,
          height: kMinTouch,
        ),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.standard,
        onPressed: onTap,
        icon: Icon(icon, size: 22, color: sh.ink),
      ),
    );
  }
}
