import 'package:flutter/material.dart';
import '../models/day_template.dart';
import '../core/theme/app_theme.dart';

class ProgressWidget extends StatefulWidget {
  final DayField field;
  final dynamic value;
  final SurlapColors sh;
  final bool compact;
  final ValueChanged<dynamic>? onChanged;
  const ProgressWidget({super.key, required this.field, required this.value,
      required this.sh, required this.compact, this.onChanged});
  @override State<ProgressWidget> createState() => _ProgressWidgetState();
}

class _ProgressWidgetState extends State<ProgressWidget> {
  bool _editing = false;
  late TextEditingController _ctrl;
  @override void initState() { super.initState(); _ctrl = TextEditingController(text: widget.value?.toString() ?? ''); }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final sh = widget.sh;
    final target = widget.field.target ?? 100;
    final unit = widget.field.unit ?? '';
    final cur = (widget.value is num) ? (widget.value as num).toDouble()
               : double.tryParse(widget.value?.toString() ?? '') ?? 0;
    final pct = target > 0 ? (cur / target).clamp(0.0, 1.0) : 0.0;

    if (widget.compact) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ClipRRect(borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
                value: pct.toDouble(), minHeight: 5,
                backgroundColor: sh.border,
                valueColor: AlwaysStoppedAnimation(sh.accent))),
        Text('$cur / $target$unit', style: TextStyle(fontSize: 9, color: sh.inkSoft)),
      ]);
    }
    if (_editing) {
      return Row(children: [
        Expanded(child: TextField(controller: _ctrl, autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(suffixText: '/ $target$unit',
                suffixStyle: TextStyle(color: sh.inkSoft)),
            onSubmitted: (v) { widget.onChanged?.call(v); setState(() => _editing = false); },
            onEditingComplete: () { widget.onChanged?.call(_ctrl.text); setState(() => _editing = false); })),
      ]);
    }
    return GestureDetector(
      onTap: () => setState(() => _editing = true),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(widget.field.label, style: TextStyle(fontSize: 11, color: sh.inkSoft, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('$cur / $target$unit', style: TextStyle(fontSize: 12, color: sh.inkSoft)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
                value: pct.toDouble(), minHeight: 8,
                backgroundColor: sh.border,
                valueColor: AlwaysStoppedAnimation(sh.accent))),
      ]),
    );
  }
}
