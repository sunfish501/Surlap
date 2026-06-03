import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import 'study_common.dart';

/// 과목별 공부 기록 한 건.
class StudySubjectEntry {
  final String subject;
  final Duration duration;
  final Color color;
  final bool active;
  const StudySubjectEntry({
    required this.subject,
    this.duration = Duration.zero,
    this.color = const Color(0xFF5A2DF4),
    this.active = true,
  });
}

/// 오늘 공부한 과목 — chip 형태로 보여주고 빠르게 추가.
class TodaySubjectStudyCard extends StatelessWidget {
  final List<StudySubjectEntry> subjects;
  final ValueChanged<StudySubjectEntry>? onSubjectTap;
  final VoidCallback? onAddSubject;

  const TodaySubjectStudyCard({
    super.key,
    required this.subjects,
    this.onSubjectTap,
    this.onAddSubject,
  });

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    return PremiumStudyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StudySectionHeader(
            title: '오늘 공부한 과목',
            subtitle: '과목을 눌러 시간을 기록해요',
            trailing: GestureDetector(
              onTap: onAddSubject,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: sh.accentBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 15, color: sh.accentInk),
                    const SizedBox(width: 2),
                    Text('과목',
                        style: AppType.label.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: sh.accentInk)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (subjects.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text('아직 기록한 과목이 없어요',
                  style: AppType.body.copyWith(color: sh.inkFaint)),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in subjects)
                  _SubjectChip(
                    entry: s,
                    sh: sh,
                    onTap: () => onSubjectTap?.call(s),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SubjectChip extends StatelessWidget {
  final StudySubjectEntry entry;
  final SpaceHourColors sh;
  final VoidCallback onTap;
  const _SubjectChip(
      {required this.entry, required this.sh, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = entry.active;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: active
              ? entry.color.withValues(alpha: 0.12)
              : sh.ink.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active
                ? entry.color.withValues(alpha: 0.28)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(color: entry.color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 7),
            Text(entry.subject,
                style: AppType.label.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: active ? entry.color : sh.ink.withValues(alpha: 0.5))),
            if (entry.duration > Duration.zero) ...[
              const SizedBox(width: 6),
              Text(formatShortDuration(entry.duration),
                  style: AppType.label.copyWith(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: sh.inkSoft)),
            ],
          ],
        ),
      ),
    );
  }
}
