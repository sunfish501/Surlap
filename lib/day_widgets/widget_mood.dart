import 'package:flutter/material.dart';
import '../models/day_template.dart';
import '../core/theme/app_theme.dart';

class MoodWidget extends StatelessWidget {
  final DayField field;
  final dynamic value;
  final SurlapColors sh;
  final bool compact;
  final ValueChanged<dynamic>? onChanged;
  const MoodWidget({super.key, required this.field, required this.value,
      required this.sh, required this.compact, this.onChanged});

  static const _levels5 = ['😞','🙁','😐','🙂','😊'];
  static const _levels3 = ['😞','😐','😊'];

  @override
  Widget build(BuildContext context) {
    final sh = this.sh;
    final levels = (field.levels == 3) ? _levels3 : _levels5;
    final sel = (value is int) ? value as int
               : (value is num) ? (value as num).toInt()
               : int.tryParse(value?.toString() ?? '') ?? -1;

    if (compact) {
      if (sel < 0 || sel >= levels.length) { return Text('—', style: TextStyle(fontSize: 10, color: sh.inkFaint)); }
      return Text(levels[sel], style: const TextStyle(fontSize: 14));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(field.label, style: TextStyle(fontSize: 11, color: sh.inkSoft, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Row(mainAxisSize: MainAxisSize.min,
          children: List.generate(levels.length, (i) => GestureDetector(
            onTap: () => onChanged?.call(i == sel ? -1 : i),
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 150),
                scale: i == sel ? 1.3 : 1.0,
                child: Text(levels[i],
                    style: TextStyle(fontSize: 26,
                        color: i == sel ? null : const Color(0xFFCCCCCC))),
              ),
            ),
          ))),
    ]);
  }
}
