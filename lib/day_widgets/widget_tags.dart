import 'package:flutter/material.dart';
import '../models/day_template.dart';
import '../core/theme/app_theme.dart';

class TagsWidget extends StatefulWidget {
  final DayField field;
  final dynamic value;
  final SurlapColors sh;
  final bool compact;
  final ValueChanged<dynamic>? onChanged;
  const TagsWidget({super.key, required this.field, required this.value,
      required this.sh, required this.compact, this.onChanged});
  @override State<TagsWidget> createState() => _TagsWidgetState();
}

class _TagsWidgetState extends State<TagsWidget> {
  bool _editing = false;
  late TextEditingController _ctrl;

  List<String> get _tags => value is List
      ? (value as List).map((e) => e.toString()).toList()
      : [];

  dynamic get value => widget.value;

  @override void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _tags.join(', '));
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final sh = widget.sh;
    if (widget.compact) {
      return Wrap(spacing: 3, children: _tags.take(3).map((t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(color: sh.accentBg, borderRadius: BorderRadius.circular(8)),
        child: Text(t, style: TextStyle(fontSize: 9, color: sh.accentInk)),
      )).toList());
    }
    if (_editing) {
      return TextField(controller: _ctrl, autofocus: true,
          decoration: InputDecoration(hintText: '쉼표 또는 공백으로 구분',
              hintStyle: TextStyle(color: sh.inkFaint)),
          onSubmitted: (v) { _commit(v); setState(() => _editing = false); },
          onEditingComplete: () { _commit(_ctrl.text); setState(() => _editing = false); });
    }
    return GestureDetector(
      onTap: () => setState(() => _editing = true),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.field.label, style: TextStyle(fontSize: 11, color: sh.inkSoft, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        _tags.isEmpty
            ? Text('태그 없음', style: TextStyle(fontSize: 13, color: sh.inkFaint))
            : Wrap(spacing: 6, runSpacing: 4, children: _tags.map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: sh.accentBg, borderRadius: BorderRadius.circular(20)),
                child: Text(t, style: TextStyle(fontSize: 12, color: sh.accentInk,
                    fontWeight: FontWeight.w500)),
              )).toList()),
      ]),
    );
  }

  void _commit(String v) {
    final parts = v.split(RegExp(r'[,\s]+')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    widget.onChanged?.call(parts);
  }
}
