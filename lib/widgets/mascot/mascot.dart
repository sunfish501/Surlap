import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';

/// HourSpace 마스코트(우주 백호) 표정.
enum MascotExpression { neutral, happy, cheering, sleepy, thinking }

/// 마스코트 브랜드 팔레트.
abstract final class MascotColors {
  static const primary = Color(0xFF8B7FF5);
  static const lightPurple = Color(0xFFA99FF8);
  static const mint = Color(0xFF5DCAA5);
  static const coral = Color(0xFFF05995);
  static const orange = Color(0xFFFFB85C);
  static const cream = Color(0xFFFFF7ED);
  static const deepPurple = Color(0xFF3E2D6B);
}

/// 표정별 개별 PNG가 있으면 그것을, 없으면 브랜드 플레이스홀더를 보여준다.
/// 나중에 `assets/mascot/mascot_<expression>.png` 를 넣으면 자동으로 교체됨.
class MascotView extends StatelessWidget {
  final MascotExpression expression;
  final double size;
  final bool showStars;
  const MascotView({
    super.key,
    this.expression = MascotExpression.neutral,
    this.size = 120,
    this.showStars = false,
  });

  String get _asset => 'assets/mascot/mascot_${expression.name}.png';

  @override
  Widget build(BuildContext context) {
    final img = Image.asset(
      _asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      // 개별 표정 에셋이 아직 없으면 플레이스홀더로 폴백.
      errorBuilder: (_, _, _) =>
          _MascotPlaceholder(expression: expression, size: size),
    );
    if (!showStars) return img;
    return SizedBox(
      width: size * 1.2,
      height: size * 1.1,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          img,
          Positioned(
            top: 0,
            right: size * 0.08,
            child: Icon(Icons.star_rounded,
                size: size * 0.16, color: MascotColors.mint),
          ),
          Positioned(
            bottom: size * 0.06,
            left: size * 0.02,
            child: Icon(Icons.star_rounded,
                size: size * 0.12, color: MascotColors.orange),
          ),
        ],
      ),
    );
  }
}

/// 개별 마스코트 PNG가 없을 때의 임시 표현 — 브랜드 톤의 둥근 블롭 + 표정 아이콘.
class _MascotPlaceholder extends StatelessWidget {
  final MascotExpression expression;
  final double size;
  const _MascotPlaceholder({required this.expression, required this.size});

  IconData get _icon => switch (expression) {
        MascotExpression.neutral => Icons.sentiment_neutral_rounded,
        MascotExpression.happy => Icons.sentiment_satisfied_rounded,
        MascotExpression.cheering => Icons.celebration_rounded,
        MascotExpression.sleepy => Icons.bedtime_rounded,
        MascotExpression.thinking => Icons.psychology_alt_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF1ECFF), Color(0xFFE7DEFF)],
        ),
        border: Border.all(
            color: MascotColors.lightPurple.withValues(alpha: 0.5), width: 2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(_icon, size: size * 0.46, color: MascotColors.primary),
          // 꼬리 별 느낌의 작은 별
          Positioned(
            top: size * 0.12,
            right: size * 0.16,
            child: Icon(Icons.star_rounded,
                size: size * 0.16, color: MascotColors.lightPurple),
          ),
        ],
      ),
    );
  }
}

/// 빈 상태(데이터 없음) — 마스코트 + 제목 + 설명 + 선택 액션.
class MascotEmptyState extends StatelessWidget {
  final MascotExpression expression;
  final String title;
  final String? message;
  final double mascotSize;
  final String? actionText;
  final VoidCallback? onAction;
  final bool showStars;

  const MascotEmptyState({
    super.key,
    this.expression = MascotExpression.neutral,
    required this.title,
    this.message,
    this.mascotSize = 120,
    this.actionText,
    this.onAction,
    this.showStars = true,
  });

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MascotView(
                expression: expression, size: mascotSize, showStars: showStars),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppType.body.copyWith(
                  fontSize: 16, fontWeight: FontWeight.w800, color: sh.ink),
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppType.label
                    .copyWith(fontSize: 13, color: sh.inkSoft, height: 1.4),
              ),
            ],
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 18),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: sh.accent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 12),
                ),
                child: Text(actionText!,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 작은 마스코트 + 메시지 카드(홈의 응원/휴식 메시지 등).
class MascotMessageCard extends StatelessWidget {
  final MascotExpression expression;
  final String message;
  final Color? tint;
  const MascotMessageCard({
    super.key,
    required this.expression,
    required this.message,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    final c = tint ?? sh.accent;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.withValues(alpha: sh.dark ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          MascotView(expression: expression, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppType.body.copyWith(
                  fontWeight: FontWeight.w700, color: sh.ink, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
