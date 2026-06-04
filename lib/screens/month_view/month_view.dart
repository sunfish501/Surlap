import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/date_utils.dart' as du;
import '../../models/event_item.dart';
import '../../models/todo_item.dart';
import '../../providers/view_provider.dart';
import '../../providers/events_provider.dart';
import '../../providers/themes_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/filter_provider.dart';
import '../../providers/extras_provider.dart';
import '../../providers/day_widget_provider.dart';
import '../../providers/birthdays_provider.dart';
import '../../providers/todos_provider.dart';
import '../../providers/academic_schedule_provider.dart';
import '../../modals/day_action_sheet.dart';
import 'month_grid.dart';

class MonthView extends ConsumerWidget {
  const MonthView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(viewProvider);
    final events = ref.watch(eventsProvider);
    final themes = ref.watch(themesProvider);
    final settings = ref.watch(settingsProvider);
    final hiddenThemes = ref.watch(filterProvider);
    final starred = ref.watch(starredProvider);
    final circles = ref.watch(circlesProvider);
    final memos = ref.watch(memosProvider);
    final widgetValues = ref.watch(widgetValuesProvider);
    final dayTemplates = ref.watch(dayTemplatesProvider);
    final birthdays = ref.watch(birthdaysProvider);
    final todos = ref.watch(todosProvider);
    final sh = context.sh;

    // 날짜별 할 일 묶음 (날짜 지정된 것만 캘린더에 표시).
    final todosByDate = <String, List<TodoItem>>{};
    for (final t in todos) {
      final k = t.dateKey;
      if (k == null) continue;
      todosByDate.putIfAbsent(k, () => []).add(t);
    }

    final filteredEvents = Map.fromEntries(
      events.entries.map((e) => MapEntry(
        e.key,
        e.value.where((item) {
          if (hiddenThemes.isEmpty) return true;
          final ids = item.themeIds;
          if (ids.isEmpty) return !hiddenThemes.contains('__none__');
          return ids.every((id) => !hiddenThemes.contains(id));
        }).toList(),
      )),
    );

    // Merge birthday events
    final mergedEvents = Map<String, List<EventItem>>.from(filteredEvents);
    for (final b in birthdays) {
      if (b.month < 1 || b.month > 12 || b.day < 1 || b.day > 31) continue;
      final bKey = '${view.viewYear}-${b.month.toString().padLeft(2, '0')}-${b.day.toString().padLeft(2, '0')}';
      mergedEvents[bKey] = [...(mergedEvents[bKey] ?? []), EventItem(t: '🎂 ${b.name}')];
    }
    // Merge NEIS 학사일정 (academic — 읽기 전용 표시, 별도 카테고리로 필터 가능)
    if (!hiddenThemes.contains(academicThemeId)) {
      ref.watch(academicScheduleProvider).forEach((dateKey, names) {
        mergedEvents[dateKey] = [
          ...(mergedEvents[dateKey] ?? []),
          for (final n in names)
            EventItem(t: n, th: academicThemeId, academic: true),
        ];
      });
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(Gap.md, Gap.xs, Gap.md, 0),
      decoration: BoxDecoration(
        color: sh.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: sh.ink.withValues(alpha: 0.04)),
        // 캘린더 카드를 살짝 띄우는 부드러운 그림자(따뜻한 톤).
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: sh.dark ? 0.30 : 0.06),
            blurRadius: 22,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: MonthGrid(
        year: view.viewYear,
        month: view.viewMonth,
        weekStartDow: settings.weekStartDow,
        events: mergedEvents,
        todosByDate: todosByDate,
        themes: themes,
        sh: sh,
        showPast: settings.showPast,
        starred: starred,
        circles: circles,
        memos: memos,
        dayTemplates: dayTemplates,
        widgetValues: widgetValues,
        // 월간: 날짜 탭 → 추가/액션 시트(일정·할일·위젯·자세히 보기).
        onDayTap: (date) => _handleDayTap(context, ref, date),
        // 길게 누르면 동일 시트.
        onDayLongPress: (date) => _handleDayTap(context, ref, date),
        // 더블탭 → 동그라미 토글.
        onDayDoubleTap: (date) =>
            ref.read(circlesProvider.notifier).toggle(du.toDateKey(date)),
        onMemoTap: (memoKey, current) =>
            _editMemo(context, ref, memoKey, current),
        heroCells: true,
      ),
    );
  }

  void _handleDayTap(
      BuildContext context, WidgetRef ref, DateTime date) {
    showDayActionSheet(context, du.toDateKey(date), date);
  }

  void _editMemo(
      BuildContext context, WidgetRef ref, String memoKey, String current) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (dctx) {
        final sh = context.sh;
        return AlertDialog(
          backgroundColor: sh.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.card)),
          title: Text('메모',
              style: AppType.body.copyWith(fontWeight: FontWeight.w700, color: sh.ink)),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            maxLines: 5,
            minLines: 2,
            decoration: InputDecoration(
              hintText: '이 달의 메모를 입력하세요...',
              hintStyle: TextStyle(color: sh.inkFaint),
            ),
          ),
          actions: [
            if (current.isNotEmpty)
              TextButton(
                onPressed: () {
                  ref.read(memosProvider.notifier).set(memoKey, '');
                  Navigator.pop(dctx);
                },
                style: TextButton.styleFrom(foregroundColor: sh.danger),
                child: const Text('삭제'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dctx),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                ref
                    .read(memosProvider.notifier)
                    .set(memoKey, ctrl.text.trim());
                Navigator.pop(dctx);
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
  }
}
