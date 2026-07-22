import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';
import '../i18n/strings.dart';
import '../providers/view_provider.dart';

/// 캘린더의 유일한 뷰 전환 컨트롤: 일 · 주 · 월 · 년.
class ViewSegmentControl extends ConsumerWidget {
  const ViewSegmentControl({super.key});

  static String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sh = context.sh;
    final view = ref.watch(viewProvider);
    final mode = view.mode;
    final n = ref.read(viewProvider.notifier);
    final anchor = view.viewDay ?? _todayKey();

    final items = <(String, ViewMode, VoidCallback)>[
      ('일', ViewMode.day, () => n.setDayView(anchor)),
      ('주', ViewMode.planner, () => n.setWeekView(anchor)),
      ('월', ViewMode.events, () => n.setMode(ViewMode.events)),
      ('년', ViewMode.year, () => n.setMode(ViewMode.year)),
    ];

    return Container(
      height: kMinTouch + 6,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: sh.card2,
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      child: Row(
        children: [
          for (final (label, itemMode, onTap) in items)
            Expanded(
              child: Semantics(
                button: true,
                selected: mode == itemMode,
                label: tr(label),
                child: Material(
                  color: mode == itemMode ? sh.card : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: mode == itemMode
                        ? BorderSide(color: sh.border, width: Borders.hairline)
                        : BorderSide.none,
                  ),
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(12),
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: Motion.fast,
                        curve: Motion.curve,
                        style: AppType.bodyMedium.copyWith(
                          color: mode == itemMode ? sh.accent : sh.inkSoft,
                          fontWeight: FontWeight.w700,
                        ),
                        child: Text(tr(label)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
