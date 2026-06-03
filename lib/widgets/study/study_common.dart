import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';

/// 학생용 공부 위젯 공통 컴포넌트 — iOS 스타일 soft card / pill / badge.
/// 색은 모두 context.sh(테마 프리셋)에서 가져와 일관성 유지.

// ─── 프리미엄 카드 (white surface, large radius, soft shadow) ─────
class PremiumStudyCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  const PremiumStudyCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: sh.card,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: sh.ink.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, child: card);
  }
}

// ─── 섹션 헤더 (제목 + 부제 + trailing) ──────────────────────────
class StudySectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const StudySectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppType.section.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: sh.ink)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!,
                    style: AppType.label.copyWith(
                        fontSize: 12, height: 1.35, color: sh.inkSoft)),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

// ─── pill 버튼 (filled = 브랜드, else 연한 surface) ───────────────
class StudyPillButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool filled;
  final VoidCallback? onTap;
  const StudyPillButton({
    super.key,
    required this.label,
    this.icon,
    this.filled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    final fg = filled ? Colors.white : sh.ink.withValues(alpha: 0.75);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: filled ? sh.accent : sh.ink.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(999),
          boxShadow: filled
              ? [
                  BoxShadow(
                    color: sh.accent.withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: fg),
              const SizedBox(width: 5),
            ],
            Text(label,
                style: AppType.label.copyWith(
                    fontSize: 13, fontWeight: FontWeight.w700, color: fg)),
          ],
        ),
      ),
    );
  }
}

// ─── metric badge (label 위 / value 아래) ────────────────────────
class StudyMetricBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const StudyMetricBadge({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: AppType.label.copyWith(
                fontSize: 11, fontWeight: FontWeight.w600, color: sh.inkSoft)),
        const SizedBox(height: 3),
        Text(value,
            style: AppType.number.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: valueColor ?? sh.ink)),
      ],
    );
  }
}

// ─── 공통 유틸 ───────────────────────────────────────────────────
String formatStudyDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  if (h <= 0) return '$m분';
  if (m == 0) return '$h시간';
  return '$h시간 $m분';
}

String formatShortDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  if (h <= 0) return '${m}m';
  if (m == 0) return '${h}h';
  return '${h}h ${m}m';
}

// ─── 원형 progress ring ──────────────────────────────────────────
class StudyProgressRing extends StatelessWidget {
  final double progress; // 0.0 ~ 1.0
  final double size;
  final double stroke;
  final Color color;
  final Color trackColor;
  final Widget? center;
  const StudyProgressRing({
    super.key,
    required this.progress,
    this.size = 64,
    this.stroke = 7,
    required this.color,
    required this.trackColor,
    this.center,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress.clamp(0.0, 1.0),
          stroke: stroke,
          color: color,
          trackColor: trackColor,
        ),
        child: Center(child: center),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double stroke;
  final Color color;
  final Color trackColor;
  _RingPainter({
    required this.progress,
    required this.stroke,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);
    const start = -1.5707963267948966; // -90°
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      6.283185307179586 * progress,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.trackColor != trackColor;
}
