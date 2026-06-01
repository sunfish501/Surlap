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

class ContinuousMonthView extends ConsumerStatefulWidget {
  const ContinuousMonthView({super.key});

  @override
  ConsumerState<ContinuousMonthView> createState() => _ContinuousMonthViewState();
}

class _ContinuousMonthViewState extends ConsumerState<ContinuousMonthView> {
  static const _kInitialPage = 1200;
  late final PageController _ctrl;
  late final int _baseYear;
  late final int _baseMonth;
  bool _programmaticScroll = false;

  @override
  void initState() {
    super.initState();
    final v = ref.read(viewProvider);
    _baseYear = v.viewYear;
    _baseMonth = v.viewMonth;
    _ctrl = PageController(initialPage: _kInitialPage);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // page index → (year, month)
  (int, int) _pageToYearMonth(int page) {
    final offset = page - _kInitialPage;
    final totalMonths = _baseYear * 12 + (_baseMonth - 1) + offset;
    return (totalMonths ~/ 12, totalMonths % 12 + 1);
  }

  // (year, month) → page index
  int _yearMonthToPage(int year, int month) {
    final offset = (year - _baseYear) * 12 + (month - _baseMonth);
    return _kInitialPage + offset;
  }

  @override
  Widget build(BuildContext context) {
    // Sync when nav controls change the month
    ref.listen<ViewState>(viewProvider, (prev, next) {
      if (prev == null) return;
      if (prev.viewYear == next.viewYear && prev.viewMonth == next.viewMonth) return;
      final targetPage = _yearMonthToPage(next.viewYear, next.viewMonth);
      final currentPage = _ctrl.hasClients ? (_ctrl.page?.round() ?? _kInitialPage) : _kInitialPage;
      if (currentPage == targetPage) return;
      _programmaticScroll = true;
      _ctrl.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOut,
      ).whenComplete(() => _programmaticScroll = false);
    });

    return PageView.builder(
      controller: _ctrl,
      onPageChanged: (page) {
        if (_programmaticScroll) return;
        final (y, m) = _pageToYearMonth(page);
        ref.read(viewProvider.notifier).setYearMonth(y, m);
      },
      itemBuilder: (context, page) {
        final (y, m) = _pageToYearMonth(page);
        return _MonthPage(year: y, month: m);
      },
    );
  }
}

class _MonthPage extends ConsumerWidget {
  final int year;
  final int month;

  const _MonthPage({required this.year, required this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      final bKey = '$year-${b.month.toString().padLeft(2, '0')}-${b.day.toString().padLeft(2, '0')}';
      mergedEvents[bKey] = [...(mergedEvents[bKey] ?? []), EventItem(t: '🎂 ${b.name}')];
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: sh.border, width: 0.5)),
      ),
      child: MonthGrid(
        year: year,
        month: month,
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
        onMemoTap: (memoKey, current) => _editMemo(context, ref, memoKey, current),
      ),
    );
  }

  void _handleDayTap(BuildContext context, WidgetRef ref, DateTime date) {
    final key = du.toDateKey(date);
    _showDayActionMenu(context, ref, key, date);
  }

  void _showDayActionMenu(BuildContext context, WidgetRef ref, String key, DateTime date) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _DayActionSheet(dateKey: key, date: date, ref: ref),
    );
  }

  void _editMemo(BuildContext context, WidgetRef ref, String memoKey, String current) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (dctx) {
        final sh = context.sh;
        return AlertDialog(
          backgroundColor: sh.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('메모',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: sh.ink)),
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
                ref.read(memosProvider.notifier).set(memoKey, ctrl.text.trim());
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
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: sh.ink),
          ),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.add_rounded,
            label: '일정 추가',
            color: sh.accent,
            onTap: () {
              Navigator.pop(context);
              showAddEditEventModal(context, dateKey: dateKey);
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
        ],
      ),
    );
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
