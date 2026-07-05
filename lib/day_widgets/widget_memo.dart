import 'package:flutter/material.dart';
import '../models/day_template.dart';
import '../core/theme/app_theme.dart';

class MemoWidget extends StatefulWidget {
  final DayField field;
  final dynamic value;
  final SurlapColors sh;
  final bool compact;
  final ValueChanged<dynamic>? onChanged;
  const MemoWidget({super.key, required this.field, required this.value,
      required this.sh, required this.compact, this.onChanged});
  @override State<MemoWidget> createState() => _MemoWidgetState();
}

class _MemoWidgetState extends State<MemoWidget> {
  bool _editing = false;
  late TextEditingController _ctrl;
  @override void initState() { super.initState(); _ctrl = TextEditingController(text: widget.value?.toString() ?? ''); }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final sh = widget.sh;
    final text = widget.value?.toString() ?? '';
    if (widget.compact) {
      return Text(text, style: TextStyle(fontSize: 10, color: sh.ink),
          maxLines: 2, overflow: TextOverflow.ellipsis);
    }
    if (_editing) {
      return TextField(controller: _ctrl, autofocus: true, maxLines: 5, minLines: 3,
          textCapitalization: TextCapitalization.sentences,
          keyboardType: TextInputType.multiline,
          onTapOutside: (_) { widget.onChanged?.call(_ctrl.text); setState(() => _editing = false); });
    }
    return GestureDetector(
      onTap: () => setState(() => _editing = true),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.field.label, style: TextStyle(fontSize: 11, color: sh.inkSoft, fontWeight: FontWeight.w600)),
        const SizedBox(height: 3),
        Text(text.isEmpty ? '비어있음' : text,
            style: TextStyle(fontSize: 13, color: text.isEmpty ? sh.inkFaint : sh.ink,
                height: 1.5)),
      ]),
    );
  }
}
