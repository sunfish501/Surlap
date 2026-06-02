import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';
import '../core/utils/date_utils.dart' as du;
import '../models/event_item.dart';
import '../models/calendar_theme.dart';
import '../providers/events_provider.dart';
import '../providers/themes_provider.dart';

/// 날짜·인덱스가 있으면 편집, 없으면 추가.
Future<void> showAddEditEventModal(
  BuildContext context, {
  required String dateKey,
  int? editIndex,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => AddEditEventModal(
      dateKey: dateKey,
      editIndex: editIndex,
    ),
  );
}

class AddEditEventModal extends ConsumerStatefulWidget {
  final String dateKey;
  final int? editIndex;

  const AddEditEventModal({
    super.key,
    required this.dateKey,
    this.editIndex,
  });

  @override
  ConsumerState<AddEditEventModal> createState() => _AddEditEventModalState();
}

class _AddEditEventModalState extends ConsumerState<AddEditEventModal> {
  final _textCtrl = TextEditingController();
  late String _dateKey;
  String? _startTime;
  String? _endTime;
  final Set<String> _selectedThemes = {};

  bool get isEdit => widget.editIndex != null;

  @override
  void initState() {
    super.initState();
    _dateKey = widget.dateKey;
    if (isEdit) {
      final item = ref.read(eventsProvider)[_dateKey]?[widget.editIndex!];
      if (item != null) {
        _textCtrl.text = item.t;
        _startTime = item.tm;
        _endTime = item.te;
        _selectedThemes.addAll(item.themeIds);
      }
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    // 구독 테마도 일정에 "적용"은 가능(읽기 전용은 테마 관리에서만 적용).
    final themes = ref.watch(themesProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        color: sh.card,
        padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.lg, Gap.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목
            Row(
              children: [
                Text(
                  isEdit ? '일정 편집' : '일정 추가',
                  style: AppType.title.copyWith(color: sh.ink),
                ),
                const Spacer(),
                if (isEdit)
                  TextButton(
                    onPressed: _delete,
                    style: TextButton.styleFrom(
                        foregroundColor: sh.danger,
                        padding: EdgeInsets.zero),
                    child: const Text('삭제', style: TextStyle(fontSize: 13)),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // 날짜
            _FieldRow(
              label: '날짜',
              sh: sh,
              child: GestureDetector(
                onTap: _pickDate,
                child: Text(
                  _dateKey,
                  style: AppType.body
                      .copyWith(color: sh.accent, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 일정 내용
            _FieldRow(
              label: '일정 내용',
              sh: sh,
              child: TextField(
                controller: _textCtrl,
                autofocus: true,
                style: AppType.body.copyWith(color: sh.ink),
                decoration: InputDecoration(
                  hintText: '어머니 생신',
                  hintStyle: TextStyle(color: sh.inkFaint),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _save(),
              ),
            ),
            const SizedBox(height: 12),

            // 시간
            _FieldRow(
              label: '시간 (선택)',
              sh: sh,
              child: Row(
                children: [
                  _TimeBtn(
                    value: _startTime,
                    hint: '--:--',
                    sh: sh,
                    onTap: () => _pickTime(isStart: true),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text('~', style: TextStyle(color: sh.inkSoft)),
                  ),
                  _TimeBtn(
                    value: _endTime,
                    hint: '--:--',
                    sh: sh,
                    onTap: () => _pickTime(isStart: false),
                  ),
                  if (_startTime != null)
                    TextButton(
                      onPressed: () =>
                          setState(() { _startTime = null; _endTime = null; }),
                      style: TextButton.styleFrom(
                          foregroundColor: sh.inkSoft,
                          padding: const EdgeInsets.only(left: 8)),
                      child: const Text('지움', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 테마 선택
            if (themes.isNotEmpty) ...[
              Text('테마 (여러 개 선택 가능)',
                  style: AppType.label.copyWith(color: sh.inkSoft)),
              const SizedBox(height: Gap.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: themes.map((t) {
                  final on = _selectedThemes.contains(t.id);
                  return _ThemeChip(
                    theme: t,
                    selected: on,
                    onTap: () => setState(() {
                      if (on) {
                        _selectedThemes.remove(t.id);
                      } else {
                        _selectedThemes.add(t.id);
                      }
                    }),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // 저장/취소
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: sh.inkSoft,
                        side: BorderSide(color: sh.border),
                        minimumSize: const Size.fromHeight(kMinTouch),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Radii.card))),
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: Gap.md),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: sh.accent,
                      minimumSize: const Size.fromHeight(kMinTouch),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Radii.card)),
                    ),
                    child: const Text('저장'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final initial = du.fromDateKey(_dateKey);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
              primary: context.sh.accent),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dateKey = du.toDateKey(picked));
  }

  Future<void> _pickTime({required bool isStart}) async {
    final cur = isStart ? _startTime : _endTime;
    TimeOfDay initial = TimeOfDay.now();
    if (cur != null) {
      final parts = cur.split(':');
      initial = TimeOfDay(
          hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
              primary: context.sh.accent),
        ),
        child: child!,
      ),
    );
    if (picked == null) { return; }
    final fmt =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() {
      if (isStart) { _startTime = fmt; } else { _endTime = fmt; }
    });
  }

  void _save() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    final eventsNotifier = ref.read(eventsProvider.notifier);
    final ids = _selectedThemes.toList();
    final thVal = ids.isEmpty
        ? null
        : ids.length == 1
            ? ids.first
            : ids;

    if (isEdit) {
      final old =
          ref.read(eventsProvider)[_dateKey]?[widget.editIndex!];
      final updated = (old ?? EventItem(t: text)).copyWith(
        t: text,
        tm: _startTime,
        te: _endTime,
        th: thVal,
      );
      eventsNotifier.updateEvent(_dateKey, widget.editIndex!, updated);
    } else {
      final item = EventItem(
        id: const Uuid().v4(),
        t: text,
        tm: _startTime,
        te: _endTime,
        th: thVal,
      );
      eventsNotifier.addEvent(_dateKey, item);
    }

    Navigator.pop(context);
  }

  void _delete() {
    if (!isEdit) return;
    ref.read(eventsProvider.notifier).deleteEvent(_dateKey, widget.editIndex!);
    Navigator.pop(context);
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final Widget child;
  final SpaceHourColors sh;
  const _FieldRow({required this.label, required this.child, required this.sh});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppType.label.copyWith(color: sh.inkSoft)),
        const SizedBox(height: Gap.xs),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.md),
          decoration: BoxDecoration(
            color: sh.card2,
            borderRadius: BorderRadius.circular(Radii.small),
            border: Border.all(color: sh.border),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _TimeBtn extends StatelessWidget {
  final String? value;
  final String hint;
  final VoidCallback onTap;
  final SpaceHourColors sh;
  const _TimeBtn(
      {required this.value, required this.hint,
       required this.onTap, required this.sh});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.sm),
        decoration: BoxDecoration(
          color: value != null ? sh.accentBg : sh.card,
          borderRadius: BorderRadius.circular(Radii.small),
          border: Border.all(
              color: value != null ? sh.accent : sh.border),
        ),
        child: Text(
          value ?? hint,
          style: AppType.body.copyWith(
              color: value != null ? sh.accentInk : sh.inkFaint,
              fontWeight: value != null ? FontWeight.w600 : FontWeight.w400),
        ),
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  final CalendarTheme theme;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeChip(
      {required this.theme, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = theme.colorValue;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? color : color.withValues(alpha: 0.4),
              width: selected ? 1.5 : 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                    color: color, shape: BoxShape.circle)),
            const SizedBox(width: Gap.xs),
            Text(theme.name,
                style: AppType.caption.copyWith(
                    color: selected ? color : color.withValues(alpha: 0.8),
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
