import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';

/// 확대/축소 컨트롤 — [−] [슬라이더 + %] [+]. 스케줄표·주간·일간 공용.
class ZoomControl extends StatelessWidget {
  final double value; // 0..1 (슬라이더 위치)
  final int percent; // 표시용 배율 %
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final ValueChanged<double> onChanged;
  final SpaceHourColors sh;
  const ZoomControl({
    super.key,
    required this.value,
    required this.percent,
    required this.onMinus,
    required this.onPlus,
    required this.onChanged,
    required this.sh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: sh.card2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: sh.ink.withValues(alpha: 0.07)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _tap(Icons.remove_rounded, onMinus),
          SizedBox(
            width: 52,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: SliderComponentShape.noOverlay,
                activeTrackColor: sh.accent,
                inactiveTrackColor: sh.ink.withValues(alpha: 0.12),
                thumbColor: sh.accent,
              ),
              child: Slider(
                value: value.clamp(0.0, 1.0),
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 32,
            child: Text('$percent%',
                textAlign: TextAlign.center,
                style: AppType.caption.copyWith(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: sh.inkSoft)),
          ),
          _tap(Icons.add_rounded, onPlus),
        ],
      ),
    );
  }

  Widget _tap(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 32,
        height: 34,
        child: Icon(icon, size: 20, color: sh.inkSoft),
      ),
    );
  }
}

/// 확대/축소(+/−) 원형 버튼 — 스케줄표·주간 뷰 공용.
class ZoomButton extends StatelessWidget {
  final IconData icon;
  final SpaceHourColors sh;
  final VoidCallback onTap;
  const ZoomButton(
      {super.key, required this.icon, required this.sh, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: sh.card2,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: sh.ink.withValues(alpha: 0.07)),
        ),
        child: Icon(icon, size: 20, color: sh.inkSoft),
      ),
    );
  }
}
