import 'package:flutter/material.dart';
import '../models/day_template.dart';
import '../core/theme/app_theme.dart';

class TimerangeWidget extends StatefulWidget {
  final DayField field;
  final dynamic value;
  final SpaceHourColors sh;
  final bool compact;
  final ValueChanged<dynamic>? onChanged;
  const TimerangeWidget({super.key, required this.field, required this.value,
      required this.sh, required this.compact, this.onChanged});
  @override State<TimerangeWidget> createState() => _TimerangeWidgetState();
}

class _TimerangeWidgetState extends State<TimerangeWidget> {
  String? _start, _end;

  @override
  void initState() {
    super.initState();
    if (widget.value is Map) {
      _start = (widget.value as Map)['start'] as String?;
      _end   = (widget.value as Map)['end']   as String?;
    }
  }

  String _duration() {
    if (_start == null || _end == null) { return ''; }
    try {
      final sp = _start!.split(':');
      final ep = _end!.split(':');
      int mins = (int.parse(ep[0]) * 60 + int.parse(ep[1])) -
                 (int.parse(sp[0]) * 60 + int.parse(sp[1]));
      if (mins < 0) { mins += 1440; }
      final h = mins ~/ 60, m = mins % 60;
      return '${h > 0 ? '$h시간 ' : ''}${m > 0 ? '$m분' : ''}';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    final sh = widget.sh;
    if (widget.compact) {
      return Text(
        '${_start ?? '--:--'} → ${_end ?? '--:--'}',
        style: TextStyle(fontSize: 10, color: sh.ink),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(widget.field.label, style: TextStyle(fontSize: 11, color: sh.inkSoft, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Row(children: [
        _TimeBtn(value: _start, hint: '시작', sh: sh,
            onTap: () => _pick(isStart: true)),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text('→', style: TextStyle(color: sh.inkSoft, fontSize: 16))),
        _TimeBtn(value: _end, hint: '종료', sh: sh,
            onTap: () => _pick(isStart: false)),
        if (_duration().isNotEmpty) ...[
          const SizedBox(width: 10),
          Text(_duration(), style: TextStyle(fontSize: 12, color: sh.inkSoft)),
        ],
      ]),
    ]);
  }

  Future<void> _pick({required bool isStart}) async {
    final cur = isStart ? _start : _end;
    TimeOfDay initial = TimeOfDay.now();
    if (cur != null) {
      final p = cur.split(':');
      initial = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
    }
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) { return; }
    final fmt = '${picked.hour.toString().padLeft(2,'0')}:${picked.minute.toString().padLeft(2,'0')}';
    setState(() {
      if (isStart) { _start = fmt; } else { _end = fmt; }
    });
    widget.onChanged?.call({'start': _start, 'end': _end});
  }
}

class _TimeBtn extends StatelessWidget {
  final String? value;
  final String hint;
  final SpaceHourColors sh;
  final VoidCallback onTap;
  const _TimeBtn({required this.value, required this.hint, required this.sh, required this.onTap});
  @override Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: value != null ? sh.accentBg : sh.card2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: value != null ? sh.accent : sh.border),
      ),
      child: Text(value ?? hint,
          style: TextStyle(fontSize: 13,
              color: value != null ? sh.accentInk : sh.inkFaint,
              fontWeight: value != null ? FontWeight.w600 : FontWeight.w400)),
    ),
  );
}
