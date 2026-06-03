import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import 'study_common.dart';

/// 공부 목표 한 건.
class StudyGoal {
  final String title;
  final bool done;
  const StudyGoal({required this.title, this.done = false});

  StudyGoal copyWith({String? title, bool? done}) =>
      StudyGoal(title: title ?? this.title, done: done ?? this.done);
}

/// 오늘 공부 목표 — 체크리스트 + 달성률 progress bar.
class StudyGoalCard extends StatelessWidget {
  final List<StudyGoal> goals;
  final ValueChanged<int>? onToggle; // index 토글
  final VoidCallback? onAdd;

  const StudyGoalCard({
    super.key,
    required this.goals,
    this.onToggle,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    final doneCount = goals.where((g) => g.done).length;
    final ratio = goals.isEmpty ? 0.0 : doneCount / goals.length;

    return PremiumStudyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StudySectionHeader(
            title: '오늘 목표',
            subtitle: '$doneCount / ${goals.length} 완료',
            trailing: GestureDetector(
              onTap: onAdd,
              child: Icon(Icons.add_circle_outline_rounded,
                  size: 22, color: sh.accent),
            ),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < goals.length; i++)
            _GoalRow(
              goal: goals[i],
              sh: sh,
              onTap: () {
                HapticFeedback.selectionClick();
                onToggle?.call(i);
              },
            ),
          const SizedBox(height: 8),
          // 달성률 bar
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: sh.ink.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation(sh.accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  final StudyGoal goal;
  final SpaceHourColors sh;
  final VoidCallback onTap;
  const _GoalRow({required this.goal, required this.sh, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final done = goal.done;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
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
              child: Text(
                goal.title,
                style: AppType.body.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: done ? sh.inkFaint : sh.ink,
                  decoration:
                      done ? TextDecoration.lineThrough : TextDecoration.none,
                  decorationColor: sh.inkFaint,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
