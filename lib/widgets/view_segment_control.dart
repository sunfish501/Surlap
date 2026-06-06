import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';
import '../providers/view_provider.dart';

/// 통합 뷰 전환 세그먼트(연·월·주·일).
/// 월/연(AppHeader)·주(planner)·일(day) 헤더가 공유. 탭 1번으로 즉시 전환.
class ViewSegmentControl extends ConsumerWidget {
  const ViewSegmentControl({super.key});

  static String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sh = context.sh;
    final mode = ref.watch(viewProvider).mode;
    final n = ref.read(viewProvider.notifier);

    final items = <(String, ViewMode, VoidCallback)>[
      ('연', ViewMode.year, () => n.setMode(ViewMode.year)),
      ('월', ViewMode.events, () => n.setMode(ViewMode.events)),
      ('주', ViewMode.planner, () => n.setWeekView(_todayKey())),
      ('일', ViewMode.day, () => n.setDayView(_todayKey())),
    ];

    return Container(
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: sh.card2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: sh.ink.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          for (final (label, m, onTap) in items)
            Expanded(
              child: GestureDetector(
                onTap: onTap,
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.center,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: mode == m ? sh.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    label,
                    style: AppType.label.copyWith(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: mode == m
                          ? Colors.white
                          : sh.ink.withValues(alpha: 0.55),
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
