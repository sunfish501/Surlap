import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import 'study_common.dart';

/// 반복 루틴 한 건.
class RoutineItem {
  final String title;
  final bool done;
  final int streak; // 연속 달성 일수
  const RoutineItem({required this.title, this.done = false, this.streak = 0});
}

/// 루틴 체크 — 반복 루틴을 체크하고 streak 표시.
class StudyRoutineCheckCard extends StatelessWidget {
  final List<RoutineItem> routines;
  final ValueChanged<int>? onToggle;
  final VoidCallback? onAdd;

  const StudyRoutineCheckCard({
    super.key,
    required this.routines,
    this.onToggle,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    final doneCount = routines.where((r) => r.done).length;

    return PremiumStudyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StudySectionHeader(
            title: '루틴 체크',
            subtitle: '오늘 $doneCount / ${routines.length} 달성',
            trailing: GestureDetector(
              onTap: onAdd,
              child: Icon(Icons.add_circle_outline_rounded,
                  size: 22, color: sh.accent),
            ),
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < routines.length; i++)
            _RoutineRow(
              item: routines[i],
              sh: sh,
              onTap: () {
                HapticFeedback.selectionClick();
                onToggle?.call(i);
              },
            ),
        ],
      ),
    );
  }
}

class _RoutineRow extends StatelessWidget {
  final RoutineItem item;
  final SpaceHourColors sh;
  final VoidCallback onTap;
  const _RoutineRow(
      {required this.item, required this.sh, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final done = item.done;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: done ? sh.accentBg.withValues(alpha: 0.6) : sh.ink.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: done ? sh.accent : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: done ? sh.accent : sh.ink.withValues(alpha: 0.22),
                  width: 1.5,
                ),
              ),
              child: done
                  ? const Icon(Icons.check_rounded,
                      size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(item.title,
                  style: AppType.body.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: done ? sh.accentInk : sh.ink)),
            ),
            if (item.streak > 0) ...[
              Icon(Icons.local_fire_department_rounded,
                  size: 15, color: const Color(0xFFE7913F)),
              const SizedBox(width: 2),
              Text('${item.streak}일',
                  style: AppType.label.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: sh.inkSoft)),
            ],
          ],
        ),
      ),
    );
  }
}
