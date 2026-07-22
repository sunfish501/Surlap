import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/date_utils.dart' as du;
import '../../providers/academic_schedule_provider.dart';
import '../../providers/birthdays_provider.dart';
import '../../providers/events_provider.dart';
import '../../providers/shared_theme_events_provider.dart';
import '../../providers/sports_provider.dart';
import '../../providers/todos_provider.dart';
import '../../providers/view_provider.dart';

class YearView extends ConsumerWidget {
  const YearView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sh = context.sh;
    final year = ref.watch(viewProvider).viewYear;
    final eventKeys = <String>{
      for (final entry in ref.watch(eventsProvider).entries)
        if (entry.value.isNotEmpty) entry.key,
      for (final entry in ref.watch(academicScheduleProvider).entries)
        if (entry.value.isNotEmpty) entry.key,
      for (final entry in ref.watch(sportsEventsByDateProvider).entries)
        if (entry.value.isNotEmpty) entry.key,
      for (final entry in ref.watch(sharedThemeEventsByDateProvider).entries)
        if (entry.value.isNotEmpty) entry.key,
      for (final todo in ref.watch(todosProvider))
        if (todo.dateKey != null) todo.dateKey!,
    };
    final birthdays = ref.watch(birthdaysProvider);
    for (final birthday in birthdays) {
      eventKeys.add(
        '$year-${birthday.month.toString().padLeft(2, '0')}-'
        '${birthday.day.toString().padLeft(2, '0')}',
      );
    }

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < -180) ref.read(viewProvider.notifier).nextYear();
        if (velocity > 180) ref.read(viewProvider.notifier).prevYear();
      },
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.xs, Gap.lg, 76),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.9,
          crossAxisSpacing: Gap.sm,
          mainAxisSpacing: Gap.md,
        ),
        itemCount: 12,
        itemBuilder: (context, index) {
          final month = index + 1;
          return _MiniMonth(
            year: year,
            month: month,
            eventKeys: eventKeys,
            sh: sh,
            onTap: () {
              final notifier = ref.read(viewProvider.notifier);
              notifier.setYearMonth(year, month);
              notifier.setMode(ViewMode.events);
            },
          );
        },
      ),
    );
  }
}

class _MiniMonth extends StatelessWidget {
  const _MiniMonth({
    required this.year,
    required this.month,
    required this.eventKeys,
    required this.sh,
    required this.onTap,
  });

  final int year;
  final int month;
  final Set<String> eventKeys;
  final SurlapColors sh;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentMonth = now.year == year && now.month == month;
    final first = DateTime(year, month, 1);
    final days = DateUtils.getDaysInMonth(year, month);
    final leading = first.weekday % 7;

    return Semantics(
      button: true,
      label: '$year년 $month월',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.small),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 3),
                child: Text(
                  '$month월',
                  style: AppType.bodySmall.copyWith(
                    color: currentMonth ? sh.accent : sh.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cellHeight = constraints.maxHeight / 6;
                    return GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisExtent: cellHeight,
                      ),
                      itemCount: leading + days,
                      itemBuilder: (_, index) {
                        if (index < leading) return const SizedBox.shrink();
                        final day = index - leading + 1;
                        final date = DateTime(year, month, day);
                        final key = du.toDateKey(date);
                        return _MiniDay(
                          day: day,
                          weekday: date.weekday,
                          today: DateUtils.isSameDay(date, now),
                          hasEvent: eventKeys.contains(key),
                          sh: sh,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniDay extends StatelessWidget {
  const _MiniDay({
    required this.day,
    required this.weekday,
    required this.today,
    required this.hasEvent,
    required this.sh,
  });

  final int day;
  final int weekday;
  final bool today;
  final bool hasEvent;
  final SurlapColors sh;

  @override
  Widget build(BuildContext context) {
    final textColor = today
        ? Theme.of(context).colorScheme.onPrimary
        : weekday == DateTime.sunday
        ? sh.sun
        : weekday == DateTime.saturday
        ? sh.sat
        : sh.ink;
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 16,
          height: 16,
          alignment: Alignment.center,
          decoration: today
              ? BoxDecoration(color: sh.accent, shape: BoxShape.circle)
              : null,
          child: Text(
            '$day',
            style: TextStyle(
              color: textColor,
              fontSize: 8,
              height: 1,
              fontWeight: today ? FontWeight.w700 : FontWeight.w400,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        if (hasEvent && !today)
          Positioned(
            bottom: 0,
            child: Container(
              width: 3,
              height: 3,
              decoration: BoxDecoration(
                color: sh.accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}
