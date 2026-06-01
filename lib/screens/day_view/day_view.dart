import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart' as du;
import '../../providers/events_provider.dart';
import '../../providers/view_provider.dart';
import '../../models/event_item.dart';

class DayView extends ConsumerWidget {
  final String dateKey;
  const DayView({super.key, required this.dateKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sh = context.sh;
    final events = ref.watch(eventsProvider);
    final items = events[dateKey] ?? [];
    final date = du.fromDateKey(dateKey);

    final allDay = items.where((e) => !e.hasTime && !e.isTimetable).toList();
    final timed = items.where((e) => e.hasTime && !e.isTimetable).toList()
      ..sort((a, b) => (a.tm ?? '').compareTo(b.tm ?? ''));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 날짜 헤더
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => ref.read(viewProvider.notifier).setMode(ViewMode.events),
                child: Icon(Icons.arrow_back_ios_rounded, size: 16, color: sh.inkSoft),
              ),
              const SizedBox(width: 8),
              Text(
                '${date.month}월 ${date.day}일 (${_dowName(date.weekday)})',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: sh.ink),
              ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text('이날 일정이 없어요',
                      style: TextStyle(color: sh.inkFaint, fontSize: 14)),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  children: [
                    if (allDay.isNotEmpty) ...[
                      _SectionLabel('종일', sh),
                      ...allDay.map((e) => _EventTile(item: e, sh: sh)),
                    ],
                    if (timed.isNotEmpty) ...[
                      _SectionLabel('시간별', sh),
                      ...timed.map((e) => _EventTile(item: e, sh: sh)),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  String _dowName(int w) =>
      ['월', '화', '수', '목', '금', '토', '일'][w - 1];
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final SpaceHourColors sh;
  const _SectionLabel(this.text, this.sh);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 4),
    child: Text(text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
            color: sh.inkSoft, letterSpacing: 0.4)),
  );
}

class _EventTile extends StatelessWidget {
  final EventItem item;
  final SpaceHourColors sh;
  const _EventTile({required this.item, required this.sh});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: sh.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: sh.border, width: 0.5),
      ),
      child: Row(
        children: [
          if (item.tm != null) ...[
            Text(item.tm!,
                style: TextStyle(fontSize: 11, color: sh.inkSoft,
                    fontWeight: FontWeight.w500)),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(item.t,
                style: TextStyle(fontSize: 14, color: sh.ink)),
          ),
        ],
      ),
    );
  }
}
