import 'package:flutter/material.dart';
import '../models/day_template.dart';
import '../core/theme/app_theme.dart';

class RatingWidget extends StatelessWidget {
  final DayField field;
  final dynamic value;
  final SurlapColors sh;
  final bool compact;
  final ValueChanged<dynamic>? onChanged;
  const RatingWidget({super.key, required this.field, required this.value,
      required this.sh, required this.compact, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final max = field.max ?? 5;
    final cur = value is int ? value as int : (value is String ? int.tryParse(value) ?? 0 : 0);
    final sh = this.sh;

    if (compact) {
      return Text(List.generate(max, (i) => i < cur ? '★' : '☆').join(),
          style: TextStyle(fontSize: 10, color: sh.accent, letterSpacing: 1));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(field.label, style: TextStyle(fontSize: 11, color: sh.inkSoft, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Row(mainAxisSize: MainAxisSize.min,
          children: List.generate(max, (i) => GestureDetector(
            onTap: () => onChanged?.call(i + 1 == cur ? 0 : i + 1),
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(i < cur ? '★' : '☆',
                  style: TextStyle(fontSize: 22, color: i < cur ? sh.accent : sh.inkFaint)),
            ),
          ))),
    ]);
  }
}
