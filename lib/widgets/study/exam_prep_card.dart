import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import 'study_common.dart';

/// 수행평가 / 시험 항목 한 건.
class ExamItem {
  final String title;
  final int dday; // D-n (남은 일수)
  const ExamItem({required this.title, required this.dday});
}

/// 수행평가 / 시험 대비 — D-day 카드.
class ExamPrepCard extends StatelessWidget {
  final List<ExamItem> items;
  final ValueChanged<ExamItem>? onTap;
  final VoidCallback? onAdd;
  final String title;

  const ExamPrepCard({
    super.key,
    required this.items,
    this.onTap,
    this.onAdd,
    this.title = '수행평가 · 시험',
  });

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    final sorted = [...items]..sort((a, b) => a.dday.compareTo(b.dday));

    return PremiumStudyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StudySectionHeader(
            title: title,
            subtitle: '다가오는 평가를 미리 준비해요',
            trailing: GestureDetector(
              onTap: onAdd,
              child: Icon(Icons.add_circle_outline_rounded,
                  size: 22, color: sh.accent),
            ),
          ),
          const SizedBox(height: 12),
          for (final e in sorted)
            _ExamRow(item: e, sh: sh, onTap: () => onTap?.call(e)),
        ],
      ),
    );
  }
}

class _ExamRow extends StatelessWidget {
  final ExamItem item;
  final SpaceHourColors sh;
  final VoidCallback onTap;
  const _ExamRow({required this.item, required this.sh, required this.onTap});

  // 임박할수록 진한 강조색
  Color get _accent {
    if (item.dday <= 3) return const Color(0xFFE8554E); // 위급(빨강)
    if (item.dday <= 7) return const Color(0xFFE7913F); // 주의(주황)
    return sh.accent; // 여유(브랜드)
  }

  @override
  Widget build(BuildContext context) {
    final c = _accent;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            // 타임라인 점
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            ),
            Expanded(
              child: Text(item.title,
                  style: AppType.body.copyWith(
                      fontSize: 15, fontWeight: FontWeight.w600, color: sh.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            // D-day badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                item.dday <= 0 ? 'D-DAY' : 'D-${item.dday}',
                style: AppType.label.copyWith(
                    fontSize: 12, fontWeight: FontWeight.w800, color: c),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
