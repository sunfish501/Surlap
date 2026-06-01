import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../providers/view_provider.dart';
import '../providers/color_preset_provider.dart';
import '../supabase/auth_service.dart';
import '../modals/profile_modal.dart';
import '../modals/login_modal.dart';
import '../modals/theme_manager_modal.dart';
import '../modals/day_template_manager_modal.dart';

/// 원본 하단 바 재현.
/// 레이아웃: [일정테마][일일기록] | [년][월][주][일] | [시간표] | [프로필]
/// 스타일: 플로팅 pill, backdrop blur, 26px 라운드, 하단 고정.
class SpaceHourBottomNav extends ConsumerWidget {
  const SpaceHourBottomNav({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view    = ref.watch(viewProvider);
    final notifier = ref.read(viewProvider.notifier);
    final preset  = ref.watch(colorPresetProvider);
    final user    = ref.watch(authProvider);
    final sh      = context.sh;

    final accent = preset.accent;
    final border = preset.hairline;

    bool isView(ViewMode m) => view.mode == m;

    return Positioned(
      left: 0, right: 0, bottom: 16,
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: sh.dark
                      ? Colors.black.withValues(alpha: 0.72)
                      : Colors.white.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.06), width: 0.5),
                  boxShadow: const [
                    BoxShadow(color: Color(0x24000000), blurRadius: 28, offset: Offset(0,8)),
                    BoxShadow(color: Color(0x0D000000), blurRadius: 6,  offset: Offset(0,2)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ─── 일정 테마 ───
                    _BnTab(
                      icon: _paletteIcon,
                      label: '일정 테마',
                      active: false,
                      accent: accent,
                      onTap: () => showThemeManagerModal(context),
                    ),
                    // ─── 일일기록 ───
                    _BnTab(
                      icon: _layoutIcon,
                      label: '일일기록',
                      active: false,
                      accent: accent,
                      onTap: () => showDayTemplateManagerModal(context),
                    ),
                    // ─── divider ───
                    _Divider(color: border),

                    // ─── 뷰 그룹 (년·월·주·일) ───
                    Container(
                      decoration: BoxDecoration(
                        color: Color.fromARGB(
                          (accent.a * 0.07).round(),
                          (accent.r * 255).round(),
                          (accent.g * 255).round(),
                          (accent.b * 255).round(),
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ViewTab(icon: _yearIcon,    label: '년', active: isView(ViewMode.year),
                              accent: accent, onTap: () => notifier.setMode(ViewMode.year)),
                          _ViewTab(icon: _calIcon,     label: '월', active: isView(ViewMode.events),
                              accent: accent, onTap: () => notifier.setMode(ViewMode.events)),
                          _ViewTab(icon: _plannerIcon, label: '주', active: isView(ViewMode.planner),
                              accent: accent, onTap: () => notifier.setMode(ViewMode.planner)),
                          _ViewTab(icon: _dayIcon,     label: '일', active: isView(ViewMode.day),
                              accent: accent, onTap: () {
                                final n = DateTime.now();
                                final key = '${n.year}-'
                                    '${n.month.toString().padLeft(2,'0')}-'
                                    '${n.day.toString().padLeft(2,'0')}';
                                notifier.setDayView(key);
                              }),
                        ],
                      ),
                    ),

                    // ─── divider ───
                    _Divider(color: border),

                    // ─── 시간표 ───
                    _BnTab(
                      icon: _gridIcon,
                      label: '시간표',
                      active: isView(ViewMode.timetable),
                      accent: accent,
                      onTap: () => notifier.setMode(ViewMode.timetable),
                    ),

                    // ─── divider ───
                    _Divider(color: border),

                    // ─── 프로필 (로그인 상태에 따라 아바타 표시) ───
                    _BnTab(
                      icon: _ProfileIcon(user: user, accent: accent),
                      label: '프로필',
                      active: false,
                      accent: accent,
                      onTap: () {
                        if (user == null) {
                          showLoginModal(context);
                        } else {
                          showProfileModal(context);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── 일반 탭 (아이콘+라벨) ──────────────────────────────────
class _BnTab extends StatelessWidget {
  final Widget icon;
  final String label;
  final bool active;
  final Color accent;
  final VoidCallback onTap;

  const _BnTab({
    required this.icon, required this.label,
    required this.active, required this.accent, required this.onTap,
  });

  static const _inactive = Color(0xFF82828A);

  @override
  Widget build(BuildContext context) {
    final color = active ? accent : _inactive;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        constraints: const BoxConstraints(minWidth: 52),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? accent.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconTheme(
              data: IconThemeData(color: color, size: 22),
              child: icon,
            ),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: color, height: 1)),
          ],
        ),
      ),
    );
  }
}

// ─── 뷰 그룹 전용 탭 (더 좁고 작은 폰트) ─────────────────
class _ViewTab extends StatelessWidget {
  final Widget icon;
  final String label;
  final bool active;
  final Color accent;
  final VoidCallback onTap;

  const _ViewTab({
    required this.icon, required this.label,
    required this.active, required this.accent, required this.onTap,
  });

  static const _inactive = Color(0xFF82828A);

  @override
  Widget build(BuildContext context) {
    final color = active ? accent : _inactive;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        constraints: const BoxConstraints(minWidth: 40),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        decoration: BoxDecoration(
          color: active ? Colors.white.withValues(alpha: 0.9) : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: active
              ? [const BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0,1))]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconTheme(data: IconThemeData(color: color, size: 20), child: icon),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    fontSize: 10.5, fontWeight: FontWeight.w600, color: color, height: 1)),
          ],
        ),
      ),
    );
  }
}

// ─── 구분선 ──────────────────────────────────────────────
class _Divider extends StatelessWidget {
  final Color color;
  const _Divider({required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: 1, height: 28,
    margin: const EdgeInsets.symmetric(horizontal: 2),
    color: color,
  );
}

// ─── 프로필 아이콘 (비로그인: 사람 아이콘, 로그인: 이니셜 원) ───
class _ProfileIcon extends StatelessWidget {
  final dynamic user;
  final Color accent;
  const _ProfileIcon({required this.user, required this.accent});

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Icon(Icons.person_outline_rounded, size: 22);
    }
    final name = userDisplayName(user);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 22, height: 22,
      decoration: BoxDecoration(
        color: accent,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(initial, style: const TextStyle(
          fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700)),
    );
  }
}

// ─── SVG 아이콘 (원본 SVG paths 재현) ──────────────────────
const _sw = 2.0; // stroke width

Widget get _paletteIcon => const _SvgIcon(paths: [
  // 원본 ICON.palette: 팔레트 모양
  _SvgPath(d: 'M3 11.5 11.5 3H18a3 3 0 0 1 3 3v6.5L12.5 21a2 2 0 0 1-2.8 0l-6.7-6.7a2 2 0 0 1 0-2.8Z'),
  _SvgCircle(cx: 15.5, cy: 8.5, r: 1.5, fill: true),
]);

Widget get _layoutIcon => const _SvgIcon(paths: [
  // 원본 ICON.layout: 4개의 사각형
  _SvgRect(x: 3, y: 3, w: 7, h: 7, rx: 1),
  _SvgRect(x: 14, y: 3, w: 7, h: 7, rx: 1),
  _SvgRect(x: 14, y: 14, w: 7, h: 7, rx: 1),
  _SvgRect(x: 3, y: 14, w: 7, h: 7, rx: 1),
]);

Widget get _yearIcon => const _SvgIcon(paths: [
  // 원본 ICON.yearView: 달력 + 가로선 3개 + 세로선 3개
  _SvgRect(x: 3, y: 4, w: 18, h: 17, rx: 2.5),
  _SvgLine(x1: 3, y1: 10, x2: 21, y2: 10),
  _SvgLine(x1: 8, y1: 2, x2: 8, y2: 6),
  _SvgLine(x1: 16, y1: 2, x2: 16, y2: 6),
  _SvgLine(x1: 3, y1: 15, x2: 21, y2: 15),
  _SvgLine(x1: 8, y1: 10, x2: 8, y2: 21),
  _SvgLine(x1: 13, y1: 10, x2: 13, y2: 21),
  _SvgLine(x1: 18, y1: 10, x2: 18, y2: 21),
]);

Widget get _calIcon => const _SvgIcon(paths: [
  // 원본 ICON.calendar: 달력 + 점 5개
  _SvgRect(x: 3, y: 4, w: 18, h: 17, rx: 2.5),
  _SvgLine(x1: 3, y1: 10, x2: 21, y2: 10),
  _SvgLine(x1: 8, y1: 2, x2: 8, y2: 6),
  _SvgLine(x1: 16, y1: 2, x2: 16, y2: 6),
  _SvgCircle(cx: 7, cy: 14, r: 1.3, fill: true),
  _SvgCircle(cx: 12, cy: 14, r: 1.3, fill: true),
  _SvgCircle(cx: 17, cy: 14, r: 1.3, fill: true),
  _SvgCircle(cx: 7, cy: 19, r: 1.3, fill: true),
  _SvgCircle(cx: 12, cy: 19, r: 1.3, fill: true),
]);

Widget get _plannerIcon => const _SvgIcon(paths: [
  // 원본 ICON.planner2: 달력 + 가로선 2개
  _SvgRect(x: 3, y: 4, w: 18, h: 17, rx: 2.5),
  _SvgLine(x1: 3, y1: 10, x2: 21, y2: 10),
  _SvgLine(x1: 8, y1: 2, x2: 8, y2: 6),
  _SvgLine(x1: 16, y1: 2, x2: 16, y2: 6),
  _SvgLine(x1: 7, y1: 14, x2: 17, y2: 14),
  _SvgLine(x1: 7, y1: 18, x2: 14, y2: 18),
]);

Widget get _dayIcon => const _SvgIcon(paths: [
  // 원본 ICON.dayView: 달력 + 2줄 텍스트 느낌
  _SvgRect(x: 3, y: 4, w: 18, h: 17, rx: 2.5),
  _SvgLine(x1: 3, y1: 10, x2: 21, y2: 10),
  _SvgLine(x1: 8, y1: 2, x2: 8, y2: 6),
  _SvgLine(x1: 16, y1: 2, x2: 16, y2: 6),
  _SvgLine(x1: 7, y1: 14, x2: 17, y2: 14),
  _SvgLine(x1: 7, y1: 17.5, x2: 14, y2: 17.5),
]);

Widget get _gridIcon => const _SvgIcon(paths: [
  // 원본 ICON.grid: 2×2 그리드
  _SvgRect(x: 3, y: 3, w: 18, h: 18, rx: 2),
  _SvgLine(x1: 3, y1: 9, x2: 21, y2: 9),
  _SvgLine(x1: 3, y1: 15, x2: 21, y2: 15),
  _SvgLine(x1: 9, y1: 3, x2: 9, y2: 21),
  _SvgLine(x1: 15, y1: 3, x2: 15, y2: 21),
]);

// ─── 최소 SVG 렌더러 ──────────────────────────────────────
sealed class _SvgElement { const _SvgElement(); }
class _SvgPath   extends _SvgElement { final String d; const _SvgPath({required this.d}); }
class _SvgLine   extends _SvgElement {
  final double x1,y1,x2,y2; const _SvgLine({required this.x1,required this.y1,required this.x2,required this.y2}); }
class _SvgRect   extends _SvgElement {
  final double x,y,w,h,rx; const _SvgRect({required this.x,required this.y,required this.w,required this.h,this.rx=0}); }
class _SvgCircle extends _SvgElement {
  final double cx,cy,r; final bool fill; const _SvgCircle({required this.cx,required this.cy,required this.r,this.fill=false}); }

class _SvgIcon extends StatelessWidget {
  final List<_SvgElement> paths;
  const _SvgIcon({required this.paths});

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color ?? const Color(0xFF82828A);
    return CustomPaint(
      size: const Size(22, 22),
      painter: _SvgPainter(paths: paths, color: color),
    );
  }
}

class _SvgPainter extends CustomPainter {
  final List<_SvgElement> paths;
  final Color color;
  const _SvgPainter({required this.paths, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24; // 24px viewport → actual size
    final stroke = Paint()
      ..color = color
      ..strokeWidth = _sw * s
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color..style = PaintingStyle.fill;

    for (final el in paths) {
      if (el is _SvgLine) {
        canvas.drawLine(Offset(el.x1*s, el.y1*s), Offset(el.x2*s, el.y2*s), stroke);
      } else if (el is _SvgRect) {
        final rrect = RRect.fromRectAndRadius(
          Rect.fromLTWH(el.x*s, el.y*s, el.w*s, el.h*s),
          Radius.circular(el.rx*s),
        );
        canvas.drawRRect(rrect, stroke);
      } else if (el is _SvgCircle) {
        canvas.drawCircle(Offset(el.cx*s, el.cy*s), el.r*s, el.fill ? fill : stroke);
      } else if (el is _SvgPath) {
        // 팔레트 icon: 복잡한 path는 Flutter의 Path parser 없이 근사
        _drawPath(canvas, el.d, s, stroke, fill);
      }
    }
  }

  void _drawPath(Canvas canvas, String d, double s, Paint stroke, Paint fill) {
    // 팔레트 아이콘 전용 근사 드로잉
    // M3 11.5 11.5 3H18a3 = 육각형 느낌의 다이아몬드 배지
    final path = Path();
    path.moveTo(3*s,  11.5*s);
    path.lineTo(11.5*s, 3*s);
    path.lineTo(18*s,   3*s);
    // arc to 21,6
    path.arcToPoint(Offset(21*s, 6*s),
        radius: Radius.circular(3*s), clockwise: true);
    path.lineTo(21*s,  12.5*s);
    path.lineTo(12.5*s, 21*s);
    // arc for the 2 2 0 0 1-2.8 0 corner
    path.arcToPoint(Offset(9.7*s, 21*s),
        radius: Radius.circular(2*s), clockwise: false);
    path.lineTo(3*s, 14.2*s);
    // final arc
    path.arcToPoint(Offset(3*s, 11.5*s),
        radius: Radius.circular(2*s), clockwise: false);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(_SvgPainter old) => old.color != color;
}
