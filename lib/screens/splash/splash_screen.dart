import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// HourSpace 인트로/스플래시 — 절제된 reveal + iOS풍 세그먼트 스피너.
///
///  1) 마스코트가 은은한 글로우와 함께 부드럽게 페이드·스케일 인
///  2) 워드마크 "HourSpace"가 넓은 자간 → 제자리로 좁혀지며 페이드(타입 reveal)
///  3) 하단 세그먼트 스피너(12막대 순차 페이드 회전)로 로딩감
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _loop;

  late final Animation<double> _markFade;
  late final Animation<double> _markScale;
  late final Animation<double> _markDrift;
  late final Animation<double> _wordFade;
  late final Animation<double> _wordSpacing;
  late final Animation<double> _wordDrift;
  late final Animation<double> _tagFade;
  late final Animation<double> _spinFade;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200));
    _loop = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3200))
      ..repeat(reverse: true);

    Animation<double> curved(double a, double b, Curve c) =>
        CurvedAnimation(parent: _intro, curve: Interval(a, b, curve: c));

    _markFade = curved(0.0, 0.42, Curves.easeOut);
    _markScale = Tween<double>(begin: 0.90, end: 1.0)
        .animate(curved(0.0, 0.55, Curves.easeOutCubic));
    _markDrift = Tween<double>(begin: 16, end: 0)
        .animate(curved(0.0, 0.55, Curves.easeOutCubic));
    _wordFade = curved(0.42, 0.74, Curves.easeOut);
    _wordSpacing = Tween<double>(begin: 9, end: 1.0)
        .animate(curved(0.42, 0.88, Curves.easeOutCubic));
    _wordDrift = Tween<double>(begin: 10, end: 0)
        .animate(curved(0.42, 0.80, Curves.easeOutCubic));
    _tagFade = curved(0.62, 0.9, Curves.easeOut);
    _spinFade = curved(0.7, 0.98, Curves.easeOut);

    _intro.forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF6B3DF9),
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.12),
              radius: 1.0,
              colors: [Color(0xFF7B4BFF), Color(0xFF5A2EE0)],
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_intro, _loop]),
                  builder: (context, _) {
                    final breathe = Curves.easeInOut.transform(_loop.value);
                    final glow = 0.16 + 0.10 * breathe;
                    final floatY = -breathe * 3;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Opacity(
                          opacity: _markFade.value,
                          child: Transform.translate(
                            offset: Offset(0, _markDrift.value + floatY),
                            child: Transform.scale(
                              scale: _markScale.value,
                              child: SizedBox(
                                width: 220,
                                height: 220,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 150 + 28 * breathe,
                                      height: 150 + 28 * breathe,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(colors: [
                                          Colors.white.withValues(alpha: glow),
                                          Colors.white.withValues(alpha: 0),
                                        ]),
                                      ),
                                    ),
                                    Image.asset(
                                        'assets/mascot/splash_icon.png',
                                        width: 184, fit: BoxFit.contain),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 26),
                        Opacity(
                          opacity: _wordFade.value,
                          child: Transform.translate(
                            offset: Offset(0, _wordDrift.value),
                            child: Text(
                              'Surlap',
                              style: TextStyle(
                                fontSize: 27,
                                fontWeight: FontWeight.w700,
                                letterSpacing: _wordSpacing.value,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Opacity(
                          opacity: _tagFade.value,
                          child: Text(
                            '나만의 일정 · 시간표 · 위젯',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                              color: Colors.white.withValues(alpha: 0.74),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              // 하단 세그먼트 스피너
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 66),
                  child: AnimatedBuilder(
                    animation: _intro,
                    builder: (_, child) =>
                        Opacity(opacity: _spinFade.value, child: child),
                    child: const _SegmentSpinner(size: 30, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// iOS풍 세그먼트 스피너 — 12개 라운드 막대가 순차 페이드되며 회전.
class _SegmentSpinner extends StatefulWidget {
  final double size;
  final Color color;
  const _SegmentSpinner({required this.size, this.color = Colors.white});

  @override
  State<_SegmentSpinner> createState() => _SegmentSpinnerState();
}

class _SegmentSpinnerState extends State<_SegmentSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(
          painter: _SegPainter(t: _c.value, color: widget.color),
        ),
      ),
    );
  }
}

class _SegPainter extends CustomPainter {
  final double t; // 0..1
  final Color color;
  static const _n = 12;
  _SegPainter({required this.t, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final rOuter = size.width / 2;
    final barW = size.width * 0.10;
    final rInner = rOuter * 0.52;
    final paint = Paint()
      ..strokeWidth = barW
      ..strokeCap = StrokeCap.round;

    // 12단계로 양자화하면 똑딱이는 느낌 — 부드럽게 연속 페이드.
    for (int i = 0; i < _n; i++) {
      final ang = (i / _n) * 2 * math.pi - math.pi / 2;
      // 회전하는 머리(t) 기준 뒤로 갈수록 흐려짐.
      var phase = (i / _n) - t;
      phase -= phase.floor(); // 0..1
      final op = (1.0 - phase).clamp(0.22, 1.0);
      paint.color = color.withValues(alpha: op);
      final dir = Offset(math.cos(ang), math.sin(ang));
      canvas.drawLine(
          c + dir * rInner, c + dir * (rOuter - barW / 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SegPainter old) =>
      old.t != t || old.color != color;
}
