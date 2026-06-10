import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';
import '../core/utils/date_utils.dart' as du;
import '../core/utils/event_parser.dart';
import '../i18n/strings.dart';
import '../models/event_item.dart';
import '../models/calendar_theme.dart';
import '../providers/events_provider.dart';
import '../providers/themes_provider.dart';
import '../widgets/mascot/mascot_feedback.dart';

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
    backgroundColor: Colors.transparent,
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
  ParsedEvent? _suggestion;
  String? _recurFreq; // null | 'W' | 'M' | 'Y'
  String? _recurUntil; // YYYY-MM-DD or null

  bool get isEdit => widget.editIndex != null;

  void _onTitleChanged(String raw) {
    if (isEdit) {
      setState(() => _suggestion = null);
      return;
    }
    final p = parseEventInput(raw);
    final hasDate = p.dateKey != null && p.dateKey != _dateKey;
    final hasTime = p.tm != null && p.tm != _startTime;
    final hasEnd = p.te != null && p.te != _endTime;
    final titleChanged = p.title.isNotEmpty && p.title != raw.trim();
    if (hasDate || hasTime || hasEnd || titleChanged) {
      setState(() => _suggestion = p);
    } else if (_suggestion != null) {
      setState(() => _suggestion = null);
    }
  }

  void _applySuggestion() {
    final s = _suggestion;
    if (s == null) return;
    setState(() {
      if (s.dateKey != null) _dateKey = s.dateKey!;
      if (s.tm != null) _startTime = s.tm;
      if (s.te != null) _endTime = s.te;
      _textCtrl.text = s.title;
      _textCtrl.selection =
          TextSelection.collapsed(offset: _textCtrl.text.length);
      _suggestion = null;
    });
  }

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
        final rr = item.rr;
        if (rr != null) {
          final f = rr['f']?.toString();
          if (f == 'W' || f == 'M' || f == 'Y') _recurFreq = f;
          _recurUntil = rr['u'] as String?;
        }
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
        decoration: BoxDecoration(
          color: sh.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, Gap.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 그랩 핸들
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: sh.ink.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // 제목
            Row(
              children: [
                Text(
                  isEdit ? tr('일정 편집') : tr('일정 추가'),
                  style: AppType.title.copyWith(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: sh.ink),
                ),
                const Spacer(),
                if (isEdit)
                  TextButton(
                    onPressed: _delete,
                    style: TextButton.styleFrom(
                        foregroundColor: sh.danger,
                        padding: EdgeInsets.zero),
                    child: Text(tr('삭제'), style: const TextStyle(fontSize: 13)),
                  ),
                // 항상 보이는 닫기(×) 버튼.
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: sh.inkSoft),
                  visualDensity: VisualDensity.compact,
                  tooltip: tr('닫기'),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 날짜
            _FieldRow(
              label: tr('날짜'),
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
              label: tr('일정 내용'),
              sh: sh,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _textCtrl,
                    autofocus: true,
                    style: AppType.body.copyWith(color: sh.ink),
                    decoration: InputDecoration(
                      hintText: tr('예: 내일 3시 회의'),
                      hintStyle: TextStyle(color: sh.inkFaint),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: _onTitleChanged,
                    onSubmitted: (_) => _save(),
                  ),
                  if (_suggestion != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _ParseSuggestionChip(
                        suggestion: _suggestion!,
                        sh: sh,
                        onApply: _applySuggestion,
                        onDismiss: () => setState(() => _suggestion = null),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 시간
            _FieldRow(
              label: tr('시간 (선택)'),
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
                      child: Text(tr('지움'), style: const TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 반복 — 없음/매주/매월/매년 + 종료일(선택)
            _FieldRow(
              label: tr('반복'),
              sh: sh,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _RecurChip(
                        label: tr('없음'),
                        selected: _recurFreq == null,
                        sh: sh,
                        onTap: () => setState(() {
                          _recurFreq = null;
                          _recurUntil = null;
                        }),
                      ),
                      _RecurChip(
                        label: tr('매주'),
                        selected: _recurFreq == 'W',
                        sh: sh,
                        onTap: () => setState(() => _recurFreq = 'W'),
                      ),
                      _RecurChip(
                        label: tr('매월'),
                        selected: _recurFreq == 'M',
                        sh: sh,
                        onTap: () => setState(() => _recurFreq = 'M'),
                      ),
                      _RecurChip(
                        label: tr('매년'),
                        selected: _recurFreq == 'Y',
                        sh: sh,
                        onTap: () => setState(() => _recurFreq = 'Y'),
                      ),
                    ],
                  ),
                  if (_recurFreq != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.event_busy_outlined,
                            size: 16, color: sh.inkSoft),
                        const SizedBox(width: 6),
                        Text(tr('종료일'),
                            style: AppType.label.copyWith(color: sh.inkSoft)),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _pickUntilDate,
                          child: Text(
                            _recurUntil ?? tr('무기한'),
                            style: AppType.body.copyWith(
                                color: _recurUntil != null
                                    ? sh.accent
                                    : sh.inkFaint,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (_recurUntil != null)
                          TextButton(
                            onPressed: () =>
                                setState(() => _recurUntil = null),
                            style: TextButton.styleFrom(
                                foregroundColor: sh.inkSoft,
                                padding: const EdgeInsets.only(left: 8)),
                            child: Text(tr('지움'),
                                style: const TextStyle(fontSize: 12)),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 캘린더(카테고리) 선택
            if (themes.isNotEmpty) ...[
              Text(tr('캘린더 (여러 개 선택 가능)'),
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
                        side: BorderSide(color: sh.ink.withValues(alpha: 0.12)),
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16))),
                    child: Text(tr('취소'),
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: Gap.md),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: sh.accent,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(isEdit ? tr('저장') : tr('추가'),
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800)),
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

  Future<void> _pickUntilDate() async {
    final initial =
        _recurUntil != null ? du.fromDateKey(_recurUntil!) : du.fromDateKey(_dateKey);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: du.fromDateKey(_dateKey),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
              primary: context.sh.accent),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _recurUntil = du.toDateKey(picked));
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
    if (text.isEmpty) {
      MascotToast.error(context, tr('제목을 입력해주세요'));
      return;
    }

    final eventsNotifier = ref.read(eventsProvider.notifier);
    final ids = _selectedThemes.toList();
    final thVal = ids.isEmpty
        ? null
        : ids.length == 1
            ? ids.first
            : ids;

    final rrMap = _recurFreq == null
        ? null
        : <String, dynamic>{
            'f': _recurFreq,
            if (_recurUntil != null) 'u': _recurUntil,
          };

    if (isEdit) {
      final old =
          ref.read(eventsProvider)[_dateKey]?[widget.editIndex!];
      final updated = (old ?? EventItem(t: text)).copyWith(
        t: text,
        tm: _startTime,
        te: _endTime,
        th: thVal,
        rr: rrMap,
      );
      eventsNotifier.updateEvent(_dateKey, widget.editIndex!, updated);
    } else {
      final item = EventItem(
        id: const Uuid().v4(),
        t: text,
        tm: _startTime,
        te: _endTime,
        th: thVal,
        rr: rrMap,
      );
      eventsNotifier.addEvent(_dateKey, item);
    }

    MascotToast.success(context, isEdit ? tr('일정을 수정했어요') : tr('일정을 추가했어요'));
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
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: sh.ink.withValues(alpha: 0.06)),
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
          color: value != null
              ? sh.accent.withValues(alpha: 0.12)
              : sh.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: value != null
                  ? sh.accent.withValues(alpha: 0.5)
                  : sh.ink.withValues(alpha: 0.10)),
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

class _RecurChip extends StatelessWidget {
  final String label;
  final bool selected;
  final SpaceHourColors sh;
  final VoidCallback onTap;
  const _RecurChip({
    required this.label,
    required this.selected,
    required this.sh,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? sh.accent.withValues(alpha: 0.15)
              : sh.ink.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: selected ? sh.accent : Colors.transparent),
        ),
        child: Text(label,
            style: AppType.label.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected ? sh.accentInk : sh.inkSoft)),
      ),
    );
  }
}

class _ParseSuggestionChip extends StatelessWidget {
  final ParsedEvent suggestion;
  final SpaceHourColors sh;
  final VoidCallback onApply;
  final VoidCallback onDismiss;
  const _ParseSuggestionChip({
    required this.suggestion,
    required this.sh,
    required this.onApply,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    if (suggestion.dateKey != null) parts.add('📅 ${suggestion.dateKey}');
    if (suggestion.tm != null) {
      final t = suggestion.te != null
          ? '${suggestion.tm}~${suggestion.te}'
          : suggestion.tm!;
      parts.add('🕒 $t');
    }
    if (suggestion.title.isNotEmpty) parts.add('"${suggestion.title}"');
    return GestureDetector(
      onTap: onApply,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: sh.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: sh.accent.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_rounded, size: 14, color: sh.accent),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '${parts.join(' · ')} — ${tr('적용')}',
                style: AppType.caption.copyWith(
                    color: sh.accentInk, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onDismiss,
              behavior: HitTestBehavior.opaque,
              child: Icon(Icons.close_rounded, size: 14, color: sh.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}
