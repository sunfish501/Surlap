import 'package:flutter/material.dart';
import '../models/day_template.dart';
import '../core/theme/app_theme.dart';

class CounterWidget extends StatelessWidget {
  final DayField field;
  final dynamic value;
  final SpaceHourColors sh;
  final bool compact;
  final ValueChanged<dynamic>? onChanged;
  const CounterWidget({super.key, required this.field, required this.value,
      required this.sh, required this.compact, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final sh = this.sh;
    final n = (value is int) ? value as int
            : (value is num) ? (value as num).toInt()
            : int.tryParse(value?.toString() ?? '') ?? 0;
    final step = (field.step ?? 1).toInt();
    final unit = field.unit ?? '';

    if (compact) {
      return Text('$n${unit.isNotEmpty ? ' $unit' : ''}',
          style: TextStyle(fontSize: 10, color: sh.ink));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(field.label, style: TextStyle(fontSize: 11, color: sh.inkSoft, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Row(mainAxisSize: MainAxisSize.min, children: [
        _Btn('−', () => onChanged?.call(n - step), sh),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('$n${unit.isNotEmpty ? ' $unit' : ''}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: sh.ink)),
        ),
        _Btn('+', () => onChanged?.call(n + step), sh),
      ]),
    ]);
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final SpaceHourColors sh;
  const _Btn(this.label, this.onTap, this.sh);
  @override Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
          color: sh.accentBg, borderRadius: BorderRadius.circular(8)),
      alignment: Alignment.center,
      child: Text(label, style: TextStyle(fontSize: 18, color: sh.accentInk,
          fontWeight: FontWeight.w700)),
    ),
  );
}
