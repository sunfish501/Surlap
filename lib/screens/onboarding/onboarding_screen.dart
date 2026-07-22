import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../i18n/strings.dart';
import '../../models/user_type.dart';
import '../../providers/user_type_provider.dart';
import '../../widgets/surlap_logo.dart';

/// 첫 실행(또는 온보딩 미시청) 시 1회 표시되는 전체화면 온보딩.
/// PageView 3장(소개) + 1장(유형 선택) + 점 인디케이터 + 다음/시작하기 버튼.
/// 유형 선택은 로그인 없이 진행되며, 선택값은 기기에 로컬 저장된다.
/// 보라→블루 그라데이션(스플래시 톤)에 Surlap 로고.
class OnboardingScreen extends ConsumerStatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _Slide {
  final IconData icon;
  final String headline;
  final String sub;
  const _Slide({required this.icon, required this.headline, required this.sub});
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pc = PageController();
  int _page = 0;
  UserType? _selectedType;

  static const _slides = [
    _Slide(
      icon: Icons.school_outlined,
      headline: '학교 시간표·급식,\n자동으로 채워져요',
      sub: '학년·반만 알려주면 시간표와 급식이 매일 들어와요. (NEIS 연동)',
    ),
    _Slide(
      icon: Icons.calendar_month_outlined,
      headline: '일정·할 일·기록을\n앱 하나로',
      sub: '달력, 할 일, 하루 기록까지 — 여러 앱을 오갈 필요 없어요.',
    ),
    _Slide(
      icon: Icons.auto_awesome_outlined,
      headline: '오늘 필요한 정보만\n한눈에 보여드려요',
      sub: '일정과 할 일, 다음 수업을 놓치지 않도록 홈에서 바로 정리해요.',
    ),
  ];

  // 마지막 페이지 = 유형 선택 페이지.
  int get _pageCount => _slides.length + 1;
  bool get _isPicker => _page == _slides.length;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _next() {
    if (_isPicker) {
      final type = _selectedType;
      if (type == null) return;
      ref.read(userTypeProvider.notifier).set(type);
      widget.onDone();
    } else {
      _pc.nextPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 유형 선택 페이지에선 선택 전까진 버튼 비활성.
    final canProceed = !_isPicker || _selectedType != null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF5A2DF4),
        body: ColoredBox(
          color: const Color(0xFF5A2DF4),
          child: Stack(
            children: [
              // 배경 깊이감(스플래시와 통일)
              Positioned(
                top: -120,
                right: -90,
                child: _SoftCircle(
                  size: 320,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
              Positioned(
                bottom: -150,
                left: -110,
                child: _SoftCircle(
                  size: 360,
                  color: const Color(0xFF9B6BFF).withValues(alpha: 0.30),
                ),
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
                          const SurlapLogo(
                            size: 26,
                            mono: true,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Surlap',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.025 * 18,
                              color: Colors.white,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ── 슬라이드 + 유형 선택 ──
                    Expanded(
                      child: PageView.builder(
                        controller: _pc,
                        onPageChanged: (i) => setState(() => _page = i),
                        itemCount: _pageCount,
                        itemBuilder: (_, i) {
                          if (i < _slides.length) {
                            return _SlideView(slide: _slides[i]);
                          }
                          return _TypePickerView(
                            selected: _selectedType,
                            onSelect: (t) => setState(() => _selectedType = t),
                          );
                        },
                      ),
                    ),
                    // ── 점 인디케이터 ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pageCount, (i) {
                        final active = i == _page;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: active ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(
                              alpha: active ? 1.0 : 0.4,
                            ),
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
                          onPressed: canProceed ? _next : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF5A2DF4),
                            disabledBackgroundColor: Colors.white.withValues(
                              alpha: 0.45,
                            ),
                            disabledForegroundColor: const Color(
                              0xFF5A2DF4,
                            ).withValues(alpha: 0.5),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: Text(
                            _isPicker ? tr('시작하기') : tr('다음'),
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
          Container(
            width: 152,
            height: 152,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
            ),
            child: Icon(slide.icon, size: 68, color: Colors.white),
          ),
          const SizedBox(height: 40),
          Text(
            tr(slide.headline),
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
            tr(slide.sub),
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

// ─── 유형 선택 페이지 ────────────────────────────────────────────
class _TypePickerView extends StatelessWidget {
  final UserType? selected;
  final ValueChanged<UserType> onSelect;
  const _TypePickerView({required this.selected, required this.onSelect});

  // 노출 순서: 학생(초·중·고·대) → 일반.
  static const _order = [
    UserType.elementary,
    UserType.middle,
    UserType.high,
    UserType.university,
    UserType.general,
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('어떤 분이세요?'),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tr('유형에 맞춰 화면을 채워드려요. 나중에 설정에서 바꿀 수 있어요.'),
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 8),
              itemCount: _order.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final t = _order[i];
                return _TypeCard(
                  type: t,
                  selected: selected == t,
                  onTap: () => onSelect(t),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final UserType type;
  final bool selected;
  final VoidCallback onTap;
  const _TypeCard({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.22),
          ),
        ),
        child: Row(
          children: [
            Text(type.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(type.label),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: selected ? const Color(0xFF5A2DF4) : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    type.tagline,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: selected
                          ? const Color(0xFF5A2DF4).withValues(alpha: 0.65)
                          : Colors.white.withValues(alpha: 0.66),
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF5A2DF4),
                size: 22,
              ),
          ],
        ),
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
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
