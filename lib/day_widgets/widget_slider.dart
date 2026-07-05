import 'package:flutter/material.dart';
import '../models/day_template.dart';
import '../core/theme/app_theme.dart';

class SliderWidget extends StatefulWidget {
  final DayField field;
  final dynamic value;
  final SurlapColors sh;
  final bool compact;
  final ValueChanged<dynamic>? onChanged;
  const SliderWidget({super.key, required this.field, required this.value,
      required this.sh, required this.compact, this.onChanged});
  @override State<SliderWidget> createState() => _SliderWidgetState();
}

class _SliderWidgetState extends State<SliderWidget> {
  late double _cur;

  @override
  void initState() {
    super.initState();
    final min = widget.field.sliderMin ?? 0;
    _cur = (widget.value is num)
        ? (widget.value as num).toDouble()
        : double.tryParse(widget.value?.toString() ?? '') ?? min;
  }

  @override
  Widget build(BuildContext context) {
    final sh = widget.sh;
    final min = widget.field.sliderMin ?? 0;
    final max = widget.field.sliderMax ?? 100;
    final unit = widget.field.unit ?? '';
    final pct = max > min ? (_cur - min) / (max - min) : 0.0;

    if (widget.compact) {
      return Row(children: [
        Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: pct.clamp(0.0,1.0), minHeight: 5,
                backgroundColor: sh.border,
                valueColor: AlwaysStoppedAnimation(sh.accent)))),
        const SizedBox(width: 4),
        Text('${_cur.toInt()}$unit', style: TextStyle(fontSize: 9, color: sh.inkSoft)),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(widget.field.label, style: TextStyle(fontSize: 11, color: sh.inkSoft, fontWeight: FontWeight.w600)),
        const Spacer(),
        Text('${_cur.toInt()}$unit', style: TextStyle(fontSize: 13, color: sh.ink, fontWeight: FontWeight.w600)),
      ]),
      SliderTheme(
        data: SliderThemeData(
          activeTrackColor: sh.accent,
          thumbColor: sh.accent,
          inactiveTrackColor: sh.border,
          overlayColor: sh.accentBg,
        ),
        child: Slider(
          value: _cur.clamp(min, max),
          min: min, max: max,
          onChanged: (v) => setState(() => _cur = v),
          onChangeEnd: (v) => widget.onChanged?.call(v),
        ),
      ),
    ]);
  }
}
