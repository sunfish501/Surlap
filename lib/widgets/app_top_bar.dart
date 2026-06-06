import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';

// ─── 투명 상단 overlay 헤더 ──────────────────────────────────────
// Status bar 뒤쪽까지 자연스럽게 gradient가 깔리는 미니멀 상단 바.
// 뷰 전환은 헤더의 ViewSegmentControl(연·월·주·일)이 담당 — 여기엔 버튼 없음.
class AppOverlayTopBar extends ConsumerWidget {
  const AppOverlayTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPad = MediaQuery.of(context).padding.top;
    final sh = context.sh;

    final gradientColors = [
      sh.bg.withValues(alpha: 0.96),
      sh.bg.withValues(alpha: 0.82),
      sh.bg.withValues(alpha: 0.0),
    ];

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            // status bar 영역만 블러 — 빈 버튼 띠 없음.
            height: topPad,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: gradientColors,
                stops: const [0.0, 0.65, 1.0],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
