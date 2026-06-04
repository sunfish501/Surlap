import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/mascot/mascot.dart';

/// 첫 실행(또는 온보딩 미시청) 시 1회 표시되는 전체화면 온보딩.
/// PageView 3장 + 점 인디케이터 + 다음/시작하기 버튼. 스와이프 지원.
/// 보라→블루 그라데이션(스플래시 톤)에 HourSpace 로고.
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _Slide {
  final MascotExpression expression;
  final String headline;
  final String sub;
  const _Slide(
      {required this.expression, required this.headline, required this.sub});
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pc = PageController();
  int _page = 0;

  static const _slides = [
    _Slide(
      expression: MascotExpression.happy,
      headline: '하루를 한눈에',
      sub: '흩어진 일정도 시간 위에 펼치면 단순해져요.',
    ),
    _Slide(
      expression: MascotExpression.neutral,
      headline: '시간이 보여요',
      sub: '월·주·일을 오가며 내 시간이 어디로 흐르는지 색으로 확인해요.',
    ),
    _Slide(
      expression: MascotExpression.cheering,
      headline: '이제 시작할 시간',
      sub: '몇 번의 탭이면 하루가 정리됩니다.',
    ),
  ];

  bool get _isLast => _page == _slides.length - 1;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLast) {
      widget.onDone();
    } else {
      _pc.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
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
        backgroundColor: const Color(0xFF5A2DF4),
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF5A2DF4), Color(0xFF7C4DFF)],
            ),
          ),
          child: Stack(
            children: [
              // 배경 깊이감(스플래시와 통일)
              Positioned(
                top: -120,
                right: -90,
                child: _SoftCircle(
                    size: 320, color: Colors.white.withValues(alpha: 0.10)),
              ),
              Positioned(
                bottom: -150,
                left: -110,
                child: _SoftCircle(
                    size: 360,
                    color: const Color(0xFF9B6BFF).withValues(alpha: 0.30)),
              ),
              SafeArea(
                child: Column(
                  children: [
                    // ── 상단 로고 ──
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('assets/images/logo.png',
                              height: 24, fit: BoxFit.contain),
                          const SizedBox(width: 8),
                          const Text(
                            'HourSpace',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ── 슬라이드 ──
                    Expanded(
                      child: PageView.builder(
                        controller: _pc,
                        onPageChanged: (i) => setState(() => _page = i),
                        itemCount: _slides.length,
                        itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
                      ),
                    ),
                    // ── 점 인디케이터 ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_slides.length, (i) {
                        final active = i == _page;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOutCubic,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: active ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white
                                .withValues(alpha: active ? 1.0 : 0.4),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    // ── 풀폭 pill 버튼 ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _next,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF5A2DF4),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999)),
                          ),
                          child: Text(
                            _isLast ? '시작하기' : '다음',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 한 장 슬라이드 ──────────────────────────────────────────────
class _SlideView extends StatelessWidget {
  final _Slide slide;
  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 마스코트
          MascotView(
              expression: slide.expression, size: 168, showStars: true),
          const SizedBox(height: 40),
          Text(
            slide.headline,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: Colors.white,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            slide.sub,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w500,
              height: 1.5,
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 흐릿한 배경 원 ──────────────────────────────────────────────
class _SoftCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _SoftCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0.0)],
        ),
      ),
    );
  }
}
