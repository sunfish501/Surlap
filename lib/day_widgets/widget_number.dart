import 'package:flutter/material.dart';
import '../models/day_template.dart';
import '../core/theme/app_theme.dart';

class NumberWidget extends StatefulWidget {
  final DayField field;
  final dynamic value;
  final SurlapColors sh;
  final bool compact;
  final ValueChanged<dynamic>? onChanged;
  const NumberWidget({super.key, required this.field, required this.value,
      required this.sh, required this.compact, this.onChanged});
  @override State<NumberWidget> createState() => _NumberWidgetState();
}

class _NumberWidgetState extends State<NumberWidget> {
  bool _editing = false;
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value?.toString() ?? '');
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final sh = widget.sh;
    final unit = widget.field.unit ?? '';
    if (widget.compact) {
      final v = widget.value;
      return Text(v != null ? '$v${unit.isNotEmpty ? ' $unit' : ''}' : '—',
          style: TextStyle(fontSize: 10, color: sh.ink));
    }
    if (_editing) {
      return Row(children: [
        Expanded(child: TextField(controller: _ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: InputDecoration(suffixText: unit,
                suffixStyle: TextStyle(color: sh.inkSoft, fontSize: 13)),
            onSubmitted: (v) { widget.onChanged?.call(v); setState(() => _editing = false); },
            onEditingComplete: () { widget.onChanged?.call(_ctrl.text); setState(() => _editing = false); })),
      ]);
    }
    return GestureDetector(
      onTap: () => setState(() => _editing = true),
      child: _ValueDisplay(
        text: widget.value != null
            ? '${widget.value}${unit.isNotEmpty ? ' $unit' : ''}'
            : '—',
        label: widget.field.label, sh: sh),
    );
  }
}

class _ValueDisplay extends StatelessWidget {
  final String text, label;
  final SurlapColors sh;
  const _ValueDisplay({required this.text, required this.label, required this.sh});
  @override Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(fontSize: 11, color: sh.inkSoft, fontWeight: FontWeight.w600)),
      const SizedBox(height: 3),
      Text(text, style: TextStyle(fontSize: 14, color: sh.ink)),
    ],
  );
}
