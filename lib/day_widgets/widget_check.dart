import 'package:flutter/material.dart';
import '../models/day_template.dart';
import '../core/theme/app_theme.dart';

class CheckWidget extends StatelessWidget {
  final DayField field;
  final dynamic value;
  final SurlapColors sh;
  final bool compact;
  final ValueChanged<dynamic>? onChanged;
  const CheckWidget({super.key, required this.field, required this.value,
      required this.sh, required this.compact, this.onChanged});

  Map<String, bool> get _state {
    if (value is Map) { return (value as Map).map((k, v) => MapEntry(k.toString(), v == true)); }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    final sh = this.sh;
    final opts = field.options ?? [];
    final state = _state;
    if (compact) {
      final done = opts.where((o) => state[o] == true).length;
      return Text('$done/${opts.length}',
          style: TextStyle(fontSize: 10, color: sh.ink));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(field.label, style: TextStyle(fontSize: 11, color: sh.inkSoft, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Wrap(spacing: 8, runSpacing: 4, children: opts.map((opt) {
        final checked = state[opt] == true;
        return GestureDetector(
          onTap: () {
            final next = Map<String, bool>.from(state);
            next[opt] = !checked;
            onChanged?.call(next);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: checked ? sh.accentBg : sh.card2,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: checked ? sh.accent : sh.border),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(checked ? Icons.check_rounded : Icons.circle_outlined,
                  size: 13, color: checked ? sh.accent : sh.inkFaint),
              const SizedBox(width: 4),
              Text(opt, style: TextStyle(fontSize: 12,
                  color: checked ? sh.accentInk : sh.ink,
                  fontWeight: checked ? FontWeight.w600 : FontWeight.w400)),
            ]),
          ),
        );
      }).toList()),
    ]);
  }
}
