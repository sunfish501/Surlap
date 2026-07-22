import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../i18n/strings.dart';
import '../../providers/recurring_provider.dart';
import '../../widgets/app_toast.dart';

const _weekdayNames = ['월', '화', '수', '목', '금'];

Future<void> showQuickTimetableEditor(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _QuickTimetableEditor(),
  );
}

/// Excel/Sheets에서 복사한 행(교시) × 열(월~금) 표를 파싱한다.
Map<(int, int), String> parseTimetableGrid(String raw, {int maxPeriods = 8}) {
  final lines = raw
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .split('\n')
      .where((line) => line.trim().isNotEmpty)
      .map((line) => line.split('\t').map((cell) => cell.trim()).toList())
      .toList();
  if (lines.isEmpty) return {};

  bool weekdayHeader(List<String> row) {
    final matches = row
        .map((cell) => cell.replaceAll('요일', '').trim())
        .where(_weekdayNames.contains)
        .length;
    return matches >= 2;
  }

  if (weekdayHeader(lines.first)) lines.removeAt(0);
  final result = <(int, int), String>{};
  for (
    var rowIndex = 0;
    rowIndex < lines.length && rowIndex < maxPeriods;
    rowIndex++
  ) {
    final row = lines[rowIndex];
    final hasPeriodColumn =
        row.length >= 6 ||
        (row.isNotEmpty &&
            (row.first.contains('교시') || int.tryParse(row.first) != null));
    final startColumn = hasPeriodColumn ? 1 : 0;
    for (var day = 0; day < 5; day++) {
      final sourceIndex = startColumn + day;
      result[(day, rowIndex + 1)] = sourceIndex < row.length
          ? row[sourceIndex]
          : '';
    }
  }
  return result;
}

class _QuickTimetableEditor extends ConsumerStatefulWidget {
  const _QuickTimetableEditor();

  @override
  ConsumerState<_QuickTimetableEditor> createState() =>
      _QuickTimetableEditorState();
}

class _QuickTimetableEditorState extends ConsumerState<_QuickTimetableEditor> {
  static const _periodCount = 8;
  final Map<(int, int), TextEditingController> _controllers = {};
  final List<FocusNode> _focusNodes = List.generate(
    _periodCount,
    (_) => FocusNode(),
  );
  late int _selectedDay;
  int _activePeriod = 1;

  @override
  void initState() {
    super.initState();
    final weekday = DateTime.now().weekday;
    _selectedDay = weekday >= DateTime.monday && weekday <= DateTime.friday
        ? weekday - 1
        : 0;
    final current = ref.read(recurringProvider);
    for (var day = 0; day < 5; day++) {
      for (var period = 1; period <= _periodCount; period++) {
        final hour = _hourForPeriod(period);
        _controllers[(day, period)] = TextEditingController(
          text: current[day]?[hour] ?? '',
        );
      }
    }
    for (var index = 0; index < _focusNodes.length; index++) {
      final period = index + 1;
      _focusNodes[index].addListener(() {
        if (_focusNodes[index].hasFocus && mounted) {
          setState(() => _activePeriod = period);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  static int _hourForPeriod(int period) =>
      period <= 4 ? 8 + period : 9 + period;

  List<String> get _recentSubjects {
    final seen = <String>{};
    final result = <String>[];
    for (final controller in _controllers.values) {
      final value = controller.text.trim();
      if (value.isNotEmpty && seen.add(value)) result.add(value);
    }
    return result.take(8).toList();
  }

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return FractionallySizedBox(
      heightFactor: 0.94,
      child: Material(
        color: sh.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            const SizedBox(height: Gap.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: sh.ink.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.sm, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('시간표 빠른 편집'),
                          style: AppType.titleLarge.copyWith(
                            fontWeight: FontWeight.w800,
                            color: sh.ink,
                          ),
                        ),
                        Text(
                          tr('요일을 고르고 과목만 차례대로 입력하세요.'),
                          style: AppType.bodySmall.copyWith(color: sh.inkSoft),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: tr('닫기'),
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: sh.inkSoft),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, 0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const ValueKey('timetable_excel_paste'),
                  onPressed: _showPasteDialog,
                  icon: const Icon(Icons.content_paste_rounded, size: 20),
                  label: Text(tr('Excel 표 붙여넣기')),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(kMinTouch),
                    side: BorderSide(color: sh.border),
                  ),
                ),
              ),
            ),
            const SizedBox(height: Gap.md),
            SizedBox(
              height: kMinTouch,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
                scrollDirection: Axis.horizontal,
                itemCount: _weekdayNames.length,
                separatorBuilder: (_, _) => const SizedBox(width: Gap.sm),
                itemBuilder: (context, day) => ChoiceChip(
                  key: ValueKey('timetable_day_$day'),
                  label: Text('${_weekdayNames[day]}요일'),
                  selected: day == _selectedDay,
                  onSelected: (_) => setState(() => _selectedDay = day),
                  showCheckmark: false,
                ),
              ),
            ),
            if (_recentSubjects.isNotEmpty) ...[
              const SizedBox(height: Gap.sm),
              SizedBox(
                height: 38,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
                  scrollDirection: Axis.horizontal,
                  itemCount: _recentSubjects.length,
                  separatorBuilder: (_, _) => const SizedBox(width: Gap.xs),
                  itemBuilder: (context, index) {
                    final subject = _recentSubjects[index];
                    return ActionChip(
                      label: Text(subject),
                      onPressed: () {
                        _controllers[(_selectedDay, _activePeriod)]!.text =
                            subject;
                        setState(() {});
                      },
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: Gap.sm),
            Expanded(
              child: ListView.separated(
                key: ValueKey('timetable_editor_day_$_selectedDay'),
                padding: EdgeInsets.fromLTRB(
                  Gap.lg,
                  Gap.xs,
                  Gap.lg,
                  Gap.lg + bottomInset,
                ),
                itemCount: _periodCount,
                separatorBuilder: (_, _) => const SizedBox(height: Gap.sm),
                itemBuilder: (context, index) {
                  final period = index + 1;
                  return TextField(
                    key: ValueKey('timetable_subject_${_selectedDay}_$period'),
                    controller: _controllers[(_selectedDay, period)],
                    focusNode: _focusNodes[index],
                    textInputAction: period == _periodCount
                        ? TextInputAction.done
                        : TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) {
                      if (period < _periodCount) {
                        _focusNodes[index + 1].requestFocus();
                      }
                    },
                    decoration: InputDecoration(
                      labelText: '$period교시',
                      hintText: tr('과목 또는 활동'),
                      prefixIcon: Icon(
                        Icons.menu_book_rounded,
                        size: 19,
                        color: sh.inkSoft,
                      ),
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Gap.lg,
                  Gap.sm,
                  Gap.lg,
                  Gap.md,
                ),
                child: Row(
                  children: [
                    OutlinedButton(
                      onPressed: _clearSelectedDay,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(96, kMinTouch),
                        foregroundColor: sh.inkSoft,
                      ),
                      child: Text(tr('이 요일 비우기')),
                    ),
                    const SizedBox(width: Gap.sm),
                    Expanded(
                      child: FilledButton.icon(
                        key: const ValueKey('timetable_save_all'),
                        onPressed: _save,
                        icon: const Icon(Icons.check_rounded, size: 20),
                        label: Text(tr('시간표 저장')),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(kMinTouch),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPasteDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final sh = context.sh;
        return AlertDialog(
          title: Text(tr('Excel 표 붙여넣기')),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('행은 1교시부터, 열은 월~금 순서로 복사해 붙여넣으세요.'),
                  style: AppType.bodySmall.copyWith(color: sh.inkSoft),
                ),
                const SizedBox(height: Gap.sm),
                TextField(
                  key: const ValueKey('timetable_paste_field'),
                  controller: controller,
                  autofocus: true,
                  minLines: 6,
                  maxLines: 10,
                  decoration: InputDecoration(
                    labelText: tr('복사한 시간표'),
                    hintText: '국어\t영어\t수학\t과학\t체육',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(tr('취소')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: Text(tr('적용')),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (result == null || result.trim().isEmpty) return;
    final cells = parseTimetableGrid(result, maxPeriods: _periodCount);
    if (cells.isEmpty) return;
    setState(() {
      for (final entry in cells.entries) {
        _controllers[entry.key]?.text = entry.value;
      }
    });
  }

  void _clearSelectedDay() {
    setState(() {
      for (var period = 1; period <= _periodCount; period++) {
        _controllers[(_selectedDay, period)]!.clear();
      }
    });
  }

  void _save() {
    final cells = <(int, int), String>{};
    for (var day = 0; day < 5; day++) {
      for (var period = 1; period <= _periodCount; period++) {
        cells[(day, _hourForPeriod(period))] =
            _controllers[(day, period)]!.text;
      }
    }
    ref.read(recurringProvider.notifier).setCells(cells);
    AppToast.success(context, tr('시간표를 저장했어요'));
    Navigator.pop(context);
  }
}
