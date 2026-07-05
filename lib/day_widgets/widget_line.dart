import 'package:flutter/material.dart';
import '../models/day_template.dart';
import '../core/theme/app_theme.dart';

class LineWidget extends StatefulWidget {
  final DayField field;
  final dynamic value;
  final SurlapColors sh;
  final bool compact;
  final ValueChanged<dynamic>? onChanged;
  const LineWidget({super.key, required this.field, required this.value,
      required this.sh, required this.compact, this.onChanged});
  @override State<LineWidget> createState() => _LineWidgetState();
}

class _LineWidgetState extends State<LineWidget> {
  bool _editing = false;
  late TextEditingController _ctrl;
  @override void initState() { super.initState(); _ctrl = TextEditingController(text: widget.value?.toString() ?? ''); }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final sh = widget.sh;
    if (widget.compact) {
      return Text(widget.value?.toString() ?? '',
          style: TextStyle(fontSize: 10, color: sh.ink),
          maxLines: 1, overflow: TextOverflow.ellipsis);
    }
    if (_editing) {
      return TextField(controller: _ctrl, autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (v) { widget.onChanged?.call(v); setState(() => _editing = false); },
          onEditingComplete: () { widget.onChanged?.call(_ctrl.text); setState(() => _editing = false); });
    }
    return GestureDetector(
      onTap: () => setState(() => _editing = true),
      child: _LabelValue(label: widget.field.label,
          value: widget.value?.toString() ?? '비어있음', sh: sh),
    );
  }
}

class _LabelValue extends StatelessWidget {
  final String label, value;
  final SurlapColors sh;
  const _LabelValue({required this.label, required this.value, required this.sh});
  @override Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(fontSize: 11, color: sh.inkSoft, fontWeight: FontWeight.w600)),
      const SizedBox(height: 3),
      Text(value, style: TextStyle(fontSize: 14, color: sh.ink)),
    ],
  );
}
