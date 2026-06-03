import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import 'study_common.dart';

/// 회독 상태.
enum ReviewRound { first, second, third, fourth, completed }

extension ReviewRoundLabel on ReviewRound {
  String get label => switch (this) {
        ReviewRound.first => '1회독',
        ReviewRound.second => '2회독',
        ReviewRound.third => '3회독',
        ReviewRound.fourth => '4회독',
        ReviewRound.completed => '완료',
      };
}

/// 회독 상태 선택 — iOS segmented control 느낌.
class ReviewRoundSelector extends StatelessWidget {
  final ReviewRound selectedRound;
  final ValueChanged<ReviewRound>? onChanged;
  final bool boxed; // true면 카드로 감쌈

  const ReviewRoundSelector({
    super.key,
    required this.selectedRound,
    this.onChanged,
    this.boxed = true,
  });

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;

    final segment = Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: sh.ink.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (final r in ReviewRound.values)
            Expanded(
              child: _Segment(
                round: r,
                selected: r == selectedRound,
                sh: sh,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged?.call(r);
                },
              ),
            ),
        ],
      ),
    );

    if (!boxed) return segment;

    return PremiumStudyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StudySectionHeader(
            title: '회독 상태',
            subtitle: '과목·단원별 회독 진행을 표시해요',
          ),
          const SizedBox(height: 14),
          segment,
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final ReviewRound round;
  final bool selected;
  final SpaceHourColors sh;
  final VoidCallback onTap;
  const _Segment({
    required this.round,
    required this.selected,
    required this.sh,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final completed = round == ReviewRound.completed;
    final fg = selected ? Colors.white : sh.ink.withValues(alpha: 0.55);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? sh.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: sh.accent.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (completed && selected) ...[
              const Icon(Icons.check_rounded, size: 14, color: Colors.white),
              const SizedBox(width: 2),
            ],
            Text(round.label,
                style: AppType.label.copyWith(
                    fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
          ],
        ),
      ),
    );
  }
}
