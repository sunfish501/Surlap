import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart' as du;
import '../../models/event_item.dart';
import '../../providers/view_provider.dart';
import '../../providers/events_provider.dart';
import '../../providers/themes_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/filter_provider.dart';
import '../../providers/extras_provider.dart';
import '../../providers/day_widget_provider.dart';
import '../../providers/birthdays_provider.dart';
import '../../modals/add_edit_event_modal.dart';
import '../../modals/day_widget_input_modal.dart';
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
    final sh = context.sh;

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

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: sh.border, width: 0.5)),
      ),
      child: MonthGrid(
        year: view.viewYear,
        month: view.viewMonth,
        weekStartDow: settings.weekStartDow,
        events: mergedEvents,
        themes: themes,
        sh: sh,
        showPast: settings.showPast,
        starred: starred,
        circles: circles,
        memos: memos,
        dayTemplates: dayTemplates,
        widgetValues: widgetValues,
        onDayTap: (date) => _handleDayTap(context, ref, date),
        onDayLongPress: (date) => _handleDayTap(context, ref, date),
        onMemoTap: (memoKey, current) =>
            _editMemo(context, ref, memoKey, current),
      ),
    );
  }

  void _handleDayTap(
      BuildContext context, WidgetRef ref, DateTime date) {
    final key = du.toDateKey(date);
    _showDayActionMenu(context, ref, key, date);
  }

  void _showDayActionMenu(
      BuildContext context, WidgetRef ref, String key, DateTime date) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _DayActionSheet(dateKey: key, date: date, ref: ref),
    );
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('메모',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: sh.ink)),
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

class _DayActionSheet extends StatelessWidget {
  final String dateKey;
  final DateTime date;
  final WidgetRef ref;

  const _DayActionSheet({
    required this.dateKey,
    required this.date,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    return Container(
      color: sh.card,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${date.month}월 ${date.day}일',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: sh.ink),
          ),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.add_rounded,
            label: '일정 추가',
            color: sh.accent,
            onTap: () {
              Navigator.pop(context);
              _openAddEvent(context, dateKey);
            },
          ),
          _ActionTile(
            icon: Icons.today_outlined,
            label: '이날 자세히 보기',
            color: sh.ink,
            onTap: () {
              Navigator.pop(context);
              ref.read(viewProvider.notifier).setDayView(dateKey);
            },
          ),
          _ActionTile(
            icon: Icons.bar_chart_rounded,
            label: '위젯 입력',
            color: sh.ink,
            onTap: () {
              Navigator.pop(context);
              showDayWidgetInputModal(context, dateKey);
            },
          ),
          Builder(builder: (ctx) {
            final starCount = ref.read(starredProvider)[dateKey] ?? 0;
            final starLabel = starCount == 0
                ? '별표 표시'
                : starCount < 3
                    ? '별표 추가 ($starCount/3)'
                    : '별표 해제';
            final starIcon = starCount >= 3
                ? Icons.star_rounded
                : Icons.star_border_rounded;
            return _ActionTile(
              icon: starIcon,
              label: starLabel,
              color: starCount > 0 ? const Color(0xFFF39C12) : sh.ink,
              onTap: () {
                Navigator.pop(context);
                ref.read(starredProvider.notifier).toggle(dateKey);
              },
            );
          }),
          Builder(builder: (ctx) {
            final hasCircle = ref.read(circlesProvider).contains(dateKey);
            return _ActionTile(
              icon: hasCircle
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              label: hasCircle ? '동그라미 해제' : '동그라미 표시',
              color: sh.ink,
              onTap: () {
                Navigator.pop(context);
                ref.read(circlesProvider.notifier).toggle(dateKey);
              },
            );
          }),
          ..._buildEventList(context, sh),
        ],
      ),
    );
  }

  List<Widget> _buildEventList(BuildContext context, SpaceHourColors sh) {
    final items = (ref.read(eventsProvider)[dateKey] ?? [])
        .where((e) => !e.isTimetable)
        .toList();
    if (items.isEmpty) return [];
    return [
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text('이 날의 일정 (${items.length})',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: sh.inkSoft,
                letterSpacing: 0.4)),
      ),
      ...items.asMap().entries.map((e) => ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: Icon(Icons.circle, size: 8, color: sh.accent),
            title: Text(e.value.t,
                style: TextStyle(fontSize: 13, color: sh.ink),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            trailing: Icon(Icons.edit_outlined, size: 16, color: sh.inkFaint),
            onTap: () {
              Navigator.pop(context);
              showAddEditEventModal(context,
                  dateKey: dateKey, editIndex: e.key);
            },
          )),
    ];
  }

  void _openAddEvent(BuildContext context, String dateKey) {
    showAddEditEventModal(context, dateKey: dateKey);
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color, size: 20),
      title: Text(label, style: TextStyle(fontSize: 14, color: color)),
      onTap: onTap,
    );
  }
}
