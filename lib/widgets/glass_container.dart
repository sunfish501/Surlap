import 'dart:ui';
import 'package:flutter/material.dart';

/// 재사용 가능한 glassmorphism 컨테이너.
/// 뒤 콘텐츠를 BackdropFilter로 blur 처리해 유리판처럼 비치게 한다.
/// 핵심 floating UI(하단 네비, 상단 overlay 등)에만 제한적으로 사용.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 28,
    this.padding = EdgeInsets.zero,
    this.blur = 18,
    this.tint = const Color(0x29FFFFFF),        // white @ 0.16
    this.borderColor = const Color(0x47FFFFFF), // white @ 0.28
    this.shadowColor = const Color(0x14000000), // black @ 0.08
    this.shadowBlur = 20,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double blur;
  final Color tint;
  final Color borderColor;
  final Color shadowColor;
  final double shadowBlur;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(borderRadius);
    return DecoratedBox(
      // 그림자는 ClipRRect 바깥에 그려야 잘리지 않는다.
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: shadowBlur,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: r,
              border: Border.all(color: borderColor, width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
