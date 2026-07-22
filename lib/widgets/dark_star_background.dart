import 'package:flutter/material.dart';

/// 다크 모드 전용 별 배경입니다. 콘텐츠 아래에 놓이며 입력을 가로채지 않습니다.
class DarkStarBackground extends StatefulWidget {
  final Widget child;

  const DarkStarBackground({super.key, required this.child});

  @override
  State<DarkStarBackground> createState() => _DarkStarBackgroundState();
}

class _DarkStarBackgroundState extends State<DarkStarBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4600),
    value: 0.3,
  );
  bool? _reduceMotion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final media = MediaQuery.maybeOf(context);
    final reduceMotion =
        (media?.disableAnimations ?? false) ||
        (media?.accessibleNavigation ?? false);
    if (_reduceMotion == reduceMotion) return;
    _reduceMotion = reduceMotion;
    if (reduceMotion) {
      _controller
        ..stop()
        ..value = 0.3;
    } else {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          child: ExcludeSemantics(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) => CustomPaint(
                  key: const ValueKey('app_dark_star_field'),
                  painter: _StarPainter(_controller.value),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _StarPainter extends CustomPainter {
  final double phase;

  const _StarPainter(this.phase);

  static const _stars = <(double, double, double, double)>[
    (0.05, 0.08, 1.0, 0.30),
    (0.17, 0.18, 1.4, 0.42),
    (0.31, 0.06, 0.8, 0.34),
    (0.46, 0.23, 1.1, 0.38),
    (0.61, 0.10, 0.9, 0.32),
    (0.77, 0.20, 1.3, 0.43),
    (0.92, 0.07, 0.8, 0.31),
    (0.09, 0.36, 0.9, 0.34),
    (0.25, 0.45, 1.2, 0.40),
    (0.40, 0.34, 0.8, 0.30),
    (0.56, 0.49, 1.4, 0.44),
    (0.71, 0.37, 0.9, 0.33),
    (0.88, 0.52, 1.1, 0.39),
    (0.04, 0.66, 1.2, 0.41),
    (0.20, 0.78, 0.8, 0.31),
    (0.36, 0.63, 1.0, 0.36),
    (0.52, 0.82, 1.3, 0.43),
    (0.67, 0.69, 0.8, 0.30),
    (0.82, 0.88, 1.1, 0.39),
    (0.96, 0.72, 0.9, 0.34),
    (0.12, 0.94, 0.8, 0.31),
    (0.43, 0.96, 1.0, 0.36),
    (0.74, 0.97, 0.8, 0.31),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || !size.isFinite) return;
    for (var index = 0; index < _stars.length; index++) {
      final (x, y, radius, baseOpacity) = _stars[index];
      final wave = index.isEven ? phase : 1 - phase;
      final opacity = baseOpacity + wave * 0.22;
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: opacity)
        ..maskFilter = radius > 1.1
            ? const MaskFilter.blur(BlurStyle.normal, 1.2)
            : null;
      canvas.drawCircle(Offset(size.width * x, size.height * y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_StarPainter oldDelegate) => oldDelegate.phase != phase;
}
