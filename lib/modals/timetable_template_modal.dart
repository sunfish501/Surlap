import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/storage_keys.dart';
import '../storage/local_store.dart';

Future<void> showTimetableTemplateModal(BuildContext context) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const TimetableTemplateModal(),
    );

class TtBlock {
  final String id;
  final String title;
  final int day; // 0=월…6=일
  final String tm;
  final String? te;

  const TtBlock({
    required this.id, required this.title,
    required this.day, required this.tm, this.te,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'day': day, 'tm': tm,
    if (te != null) 'te': te,
  };

  factory TtBlock.fromJson(Map<String, dynamic> j) => TtBlock(
    id: j['id'] as String,
    title: j['title'] as String,
    day: j['day'] as int? ?? 0,
    tm: j['tm'] as String,
    te: j['te'] as String?,
  );
}

List<TtBlock> _loadBlocks() {
  final raw = LocalStore.instance.getString(StorageKeys.timetableTemplate);
  if (raw == null) { return []; }
  try {
    return (jsonDecode(raw) as List)
        .whereType<Map<String, dynamic>>()
        .map(TtBlock.fromJson)
        .toList();
  } catch (_) { return []; }
}

Future<void> _saveBlocks(List<TtBlock> blocks) async {
  await LocalStore.instance.setString(
      StorageKeys.timetableTemplate,
      jsonEncode(blocks.map((b) => b.toJson()).toList()));
}

const _dowNames = ['월요일','화요일','수요일','목요일','금요일','토요일','일요일'];

class TimetableTemplateModal extends StatefulWidget {
  const TimetableTemplateModal({super.key});
  @override State<TimetableTemplateModal> createState() => _TimetableTemplateModalState();
}

class _TimetableTemplateModalState extends State<TimetableTemplateModal> {
  late List<TtBlock> _blocks;

  @override
  void initState() { super.initState(); _blocks = _loadBlocks(); }

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    // 요일별로 그룹
    final byDay = <int, List<TtBlock>>{};
    for (final b in _blocks) { (byDay[b.day] ??= []).add(b); }
    for (final v in byDay.values) { v.sort((a, b) => a.tm.compareTo(b.tm)); }

    return FractionallySizedBox(
      heightFactor: 0.88,
      child: Container(
        color: sh.card,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 10),
              child: Row(children: [
                Text('📅 반복 시간표 설정',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: sh.ink)),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: sh.inkSoft, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ]),
            ),
            Divider(color: sh.border, height: 1),
            Expanded(
              child: _blocks.isEmpty
                  ? Center(child: Text('+ 수업 추가 버튼으로 시작하세요',
                      style: TextStyle(color: sh.inkFaint, fontSize: 13)))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        for (int d = 0; d < 7; d++)
                          if (byDay.containsKey(d)) ...[
                            Padding(
                              padding: const EdgeInsets.only(top: 12, bottom: 4),
                              child: Text(_dowNames[d],
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                                      color: sh.inkSoft, letterSpacing: 0.4)),
                            ),
                            ...byDay[d]!.map((b) => _BlockTile(
                              block: b, sh: sh,
                              onEdit: () => _editBlock(b),
                              onDelete: () => setState(() {
                                _blocks.remove(b);
                                _saveBlocks(_blocks);
                              }),
                            )),
                          ],
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: FilledButton.icon(
                onPressed: () => _editBlock(null),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('+ 수업 추가'),
                style: FilledButton.styleFrom(
                  backgroundColor: sh.accent,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editBlock(TtBlock? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _BlockEditor(
        block: existing,
        sh: context.sh,
        onSave: (b) {
          setState(() {
            if (existing != null) {
              final idx = _blocks.indexWhere((x) => x.id == existing.id);
              if (idx >= 0) { _blocks[idx] = b; } else { _blocks.add(b); }
            } else {
              _blocks.add(b);
            }
            _saveBlocks(_blocks);
          });
        },
      ),
    );
  }
}

class _BlockTile extends StatelessWidget {
  final TtBlock block;
  final SpaceHourColors sh;
  final VoidCallback onEdit, onDelete;
  const _BlockTile({required this.block, required this.sh,
      required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: sh.card2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: sh.border),
      ),
      child: Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(block.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: sh.ink)),
            Text(block.tm + (block.te != null ? ' ~ ${block.te}' : ''),
                style: TextStyle(fontSize: 12, color: sh.inkSoft)),
          ],
        )),
        IconButton(icon: Icon(Icons.edit_outlined, size: 16, color: sh.inkSoft), onPressed: onEdit),
        IconButton(icon: Icon(Icons.delete_outline_rounded, size: 16, color: sh.danger), onPressed: onDelete),
      ]),
    );
  }
}

class _BlockEditor extends StatefulWidget {
  final TtBlock? block;
  final SpaceHourColors sh;
  final void Function(TtBlock) onSave;
  const _BlockEditor({this.block, required this.sh, required this.onSave});
  @override State<_BlockEditor> createState() => _BlockEditorState();
}

class _BlockEditorState extends State<_BlockEditor> {
  late TextEditingController _titleCtrl;
  late int _day;
  String? _tm, _te;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.block?.title ?? '');
    _day = widget.block?.day ?? 0;
    _tm = widget.block?.tm;
    _te = widget.block?.te;
  }
  @override void dispose() { _titleCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final sh = widget.sh;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        color: sh.card,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('수업 편집', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: sh.ink)),
            const SizedBox(height: 16),
            TextField(controller: _titleCtrl,
                decoration: InputDecoration(labelText: '수업명', hintText: '예) 수학',
                    hintStyle: TextStyle(color: sh.inkFaint)),
                textCapitalization: TextCapitalization.sentences),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _day,
              decoration: const InputDecoration(labelText: '요일'),
              items: List.generate(7, (i) => DropdownMenuItem(value: i, child: Text(_dowNames[i]))),
              onChanged: (v) { if (v != null) setState(() => _day = v); },
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _TimeField(
                label: '시작 시간', value: _tm, sh: sh,
                onPick: (t) => setState(() => _tm = t))),
              const SizedBox(width: 12),
              Expanded(child: _TimeField(
                label: '종료 시간 (선택)', value: _te, sh: sh,
                onPick: (t) => setState(() => _te = t))),
            ]),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: sh.accent,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty || _tm == null) { return; }
    widget.onSave(TtBlock(
      id: widget.block?.id ?? const Uuid().v4(),
      title: title, day: _day, tm: _tm!, te: _te,
    ));
    Navigator.pop(context);
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final String? value;
  final SpaceHourColors sh;
  final ValueChanged<String?> onPick;
  const _TimeField({required this.label, this.value, required this.sh, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final parts = value?.split(':');
        final init = parts != null
            ? TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]))
            : const TimeOfDay(hour: 9, minute: 0);
        final picked = await showTimePicker(context: context, initialTime: init);
        if (picked != null) {
          onPick('${picked.hour.toString().padLeft(2,'0')}:${picked.minute.toString().padLeft(2,'0')}');
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(value ?? '--:--',
            style: TextStyle(fontSize: 14,
                color: value != null ? sh.ink : sh.inkFaint)),
      ),
    );
  }
}
