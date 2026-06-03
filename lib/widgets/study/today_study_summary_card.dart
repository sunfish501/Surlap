import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import 'study_common.dart';

/// 오늘 공부 요약 — 순공/과목/회독/목표를 한눈에 (iOS Health 스타일).
class TodayStudySummaryCard extends StatelessWidget {
  final Duration studyTime;
  final int subjectCount;
  final String reviewLabel;
  final double goalProgress; // 0.0 ~ 1.0

  const TodayStudySummaryCard({
    super.key,
    required this.studyTime,
    required this.subjectCount,
    required this.reviewLabel,
    required this.goalProgress,
  });

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    final pct = (goalProgress.clamp(0.0, 1.0) * 100).round();

    return PremiumStudyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('오늘 공부',
                        style: AppType.label.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: sh.inkSoft)),
                    const SizedBox(height: 6),
                    Text(
                      formatStudyDuration(studyTime),
                      style: AppType.number.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: sh.ink),
                    ),
                    Text('순공시간',
                        style: AppType.label.copyWith(
                            fontSize: 12, color: sh.inkFaint)),
                  ],
                ),
              ),
              StudyProgressRing(
                progress: goalProgress,
                size: 76,
                stroke: 8,
                color: sh.accent,
                trackColor: sh.accent.withValues(alpha: 0.12),
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$pct%',
                        style: AppType.number.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: sh.accent)),
                    Text('목표',
                        style: AppType.label.copyWith(
                            fontSize: 9, color: sh.inkSoft)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: sh.ink.withValues(alpha: 0.05)),
          const SizedBox(height: 14),
          // metric badges
          Row(
            children: [
              Expanded(
                child: StudyMetricBadge(
                    label: '순공', value: formatShortDuration(studyTime)),
              ),
              Expanded(
                child: StudyMetricBadge(
                    label: '과목', value: '$subjectCount개'),
              ),
              Expanded(
                child: StudyMetricBadge(label: '회독', value: reviewLabel),
              ),
              Expanded(
                child: StudyMetricBadge(
                    label: '목표',
                    value: '$pct%',
                    valueColor: sh.accent),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
