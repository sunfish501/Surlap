import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import 'study_common.dart';

/// 순공시간 입력 — 오늘 집중 공부한 시간을 빠르게 기록.
class StudyTimeInputCard extends StatelessWidget {
  final Duration studyTime;
  final ValueChanged<Duration>? onChanged;
  final VoidCallback? onManualInput;
  final Duration goal; // 목표(progress ring 용)

  const StudyTimeInputCard({
    super.key,
    required this.studyTime,
    this.onChanged,
    this.onManualInput,
    this.goal = const Duration(hours: 6),
  });

  void _bump(int minutes) {
    if (onChanged == null) return;
    HapticFeedback.selectionClick();
    final next = studyTime + Duration(minutes: minutes);
    onChanged!(next.isNegative ? Duration.zero : next);
  }

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    final progress = goal.inMinutes == 0
        ? 0.0
        : studyTime.inMinutes / goal.inMinutes;

    return PremiumStudyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: StudySectionHeader(
                  title: '순공시간',
                  subtitle: '오늘 집중해서 공부한 시간을 기록해요',
                ),
              ),
              StudyProgressRing(
                progress: progress,
                size: 56,
                stroke: 6,
                color: sh.accent,
                trackColor: sh.accent.withValues(alpha: 0.12),
                center: Icon(Icons.schedule_rounded,
                    size: 20, color: sh.accent),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 큰 숫자 (가장 강조)
          Text(
            formatStudyDuration(studyTime),
            style: AppType.number.copyWith(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: sh.ink,
            ),
          ),
          const SizedBox(height: 14),
          // 빠른 버튼
          Row(
            children: [
              StudyPillButton(label: '-10분', onTap: () => _bump(-10)),
              const SizedBox(width: 8),
              StudyPillButton(label: '+10분', onTap: () => _bump(10)),
              const SizedBox(width: 8),
              StudyPillButton(
                  label: '+30분', filled: true, onTap: () => _bump(30)),
              const Spacer(),
              StudyPillButton(
                label: '직접 입력',
                icon: Icons.edit_outlined,
                onTap: onManualInput,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
