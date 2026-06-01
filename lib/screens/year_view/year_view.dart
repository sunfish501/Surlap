import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/view_provider.dart';
import '../../core/utils/date_utils.dart' as du;
import '../../providers/events_provider.dart';

class YearView extends ConsumerWidget {
  const YearView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(viewProvider);
    final events = ref.watch(eventsProvider);
    final sh = context.sh;
    final year = view.viewYear;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 12,
      itemBuilder: (context, i) {
        final month = i + 1;
        return _MiniMonthCard(
          year: year,
          month: month,
          events: events,
          sh: sh,
          onTap: () {
            ref.read(viewProvider.notifier).setYearMonth(year, month);
            ref.read(viewProvider.notifier).setMode(ViewMode.events);
          },
        );
      },
    );
  }
}

class _MiniMonthCard extends StatelessWidget {
  final int year, month;
  final Map<String, List<dynamic>> events;
  final SpaceHourColors sh;
  final VoidCallback onTap;

  const _MiniMonthCard({
    required this.year, required this.month,
    required this.events, required this.sh, required this.onTap,
  });

  static const _dow = ['일','월','화','수','목','금','토'];
  static const _monthNames = [
    '1월','2월','3월','4월','5월','6월',
    '7월','8월','9월','10월','11월','12월',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth = year == now.year && month == now.month;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: sh.card,
          borderRadius: BorderRadius.circular(14),
          border: isCurrentMonth
              ? Border.all(color: sh.accent, width: 1.5)
              : Border.all(color: sh.border, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // 월 헤더
            Container(
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color: isCurrentMonth ? sh.accentBg : sh.card2,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
              ),
              child: Center(
                child: Text(
                  _monthNames[month - 1],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isCurrentMonth ? sh.accentInk : sh.inkSoft,
                  ),
                ),
              ),
            ),
            // 미니 캘린더 그리드
            Expanded(child: _buildGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    final first = DateTime(year, month, 1);
    // 일요일 시작
    final startOffset = first.weekday % 7;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final cells = startOffset + daysInMonth;
    final rows = (cells / 7).ceil();
    final now = DateTime.now();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Column(
        children: [
          // 요일 헤더
          Row(
            children: List.generate(7, (i) => Expanded(
              child: Center(
                child: Text(_dow[i],
                    style: TextStyle(fontSize: 7, color: sh.inkFaint)),
              ),
            )),
          ),
          Expanded(
            child: Column(
              children: List.generate(rows, (r) {
                return Expanded(
                  child: Row(
                    children: List.generate(7, (c) {
                      final idx = r * 7 + c;
                      final day = idx - startOffset + 1;
                      if (day < 1 || day > daysInMonth) {
                        return const Expanded(child: SizedBox());
                      }
                      final key = du.toDateKey(DateTime(year, month, day));
                      final hasEvent = (events[key] ?? []).isNotEmpty;
                      final isToday = year == now.year &&
                          month == now.month && day == now.day;
                      return Expanded(
                        child: Center(
                          child: Container(
                            width: 14, height: 14,
                            decoration: isToday ? BoxDecoration(
                              color: sh.accentBg,
                              shape: BoxShape.circle,
                            ) : null,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Text(
                                  '$day',
                                  style: TextStyle(
                                    fontSize: 7.5,
                                    color: isToday ? sh.accentInk : sh.ink,
                                    fontWeight: isToday
                                        ? FontWeight.w700 : FontWeight.w400,
                                  ),
                                ),
                                if (hasEvent)
                                  Positioned(
                                    bottom: 0,
                                    child: Container(
                                      width: 3, height: 3,
                                      decoration: BoxDecoration(
                                        color: sh.accent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
