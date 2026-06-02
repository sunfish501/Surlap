import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/date_utils.dart' as du;
import '../../models/event_item.dart';
import '../../models/calendar_theme.dart';
import '../../providers/events_provider.dart';
import '../../providers/themes_provider.dart';
import '../../providers/view_provider.dart';
import '../../supabase/neis_service.dart';
import '../../modals/add_edit_event_modal.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  String? _mealText;
  bool _mealLoaded = false;

  static const _dowKr = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  void initState() {
    super.initState();
    _loadMeal();
  }

  Future<void> _loadMeal() async {
    final school = NeisSchool.load();
    if (school == null) {
      setState(() => _mealLoaded = true);
      return;
    }
    final dateStr = du.toDateKey(DateTime.now()).replaceAll('-', '');
    try {
      final meal = await fetchLunch(school, dateStr);
      if (mounted) {
        setState(() {
          _mealText = meal?.split('\n').first;
          _mealLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _mealLoaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    final now = DateTime.now();
    final todayKey = du.toDateKey(now);
    final events = ref.watch(eventsProvider);
    final themes = ref.watch(themesProvider);
    final notifier = ref.read(viewProvider.notifier);

    final todayAll = (events[todayKey] ?? [])
        .where((e) => !e.isTimetable)
        .toList();

    // 다음 일정: 현재 시각 이후 시간 지정 이벤트
    final upcoming = todayAll.where((e) {
      if (!e.hasTime) return false;
      final parts = e.tm!.split(':');
      final h = int.tryParse(parts[0]) ?? 0;
      final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
      return h > now.hour || (h == now.hour && m > now.minute);
    }).toList()
      ..sort((a, b) => (a.tm ?? '').compareTo(b.tm ?? ''));

    // 이번 주 이벤트 (오늘 기준 7일)
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekKeys = List.generate(7, (i) {
      final d = monday.add(Duration(days: i));
      return du.toDateKey(d);
    });
    final weekEventCounts = {
      for (final k in weekKeys) k: (events[k] ?? []).where((e) => !e.isTimetable).length
    };

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _buildGreeting(sh, now),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, 80),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // 다음 일정 카드 (large)
              _NextEventCard(
                sh: sh,
                upcoming: upcoming,
                allToday: todayAll,
                themes: themes,
                onTap: () => notifier.setDayView(todayKey),
                onAdd: () => showAddEditEventModal(context, dateKey: todayKey),
              ),
              const SizedBox(height: Gap.sm),
              // 두 번째 행: 급식 + 오늘 통계
              Row(
                children: [
                  Expanded(
                    child: _MealCard(
                      sh: sh,
                      meal: _mealText,
                      loaded: _mealLoaded,
                    ),
                  ),
                  const SizedBox(width: Gap.sm),
                  Expanded(
                    child: _TodayStatsCard(
                      sh: sh,
                      count: todayAll.length,
                      onTap: () => notifier.setDayView(todayKey),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Gap.sm),
              // 이번 주 미니 스트립
              _WeekStripCard(
                sh: sh,
                monday: monday,
                weekKeys: weekKeys,
                eventCounts: weekEventCounts,
                today: todayKey,
                onDayTap: (key) {
                  ref.read(viewProvider.notifier).setYearMonth(
                    int.parse(key.split('-')[0]),
                    int.parse(key.split('-')[1]),
                  );
                  ref.read(viewProvider.notifier).setMode(ViewMode.events);
                },
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildGreeting(SpaceHourColors sh, DateTime now) {
    final dow = _dowKr[now.weekday - 1];
    final hour = now.hour;
    final greeting = hour < 6
        ? '늦게까지 수고했어요 🌙'
        : hour < 12
            ? '좋은 아침이에요 ☀️'
            : hour < 18
                ? '오후도 화이팅이에요 💪'
                : '오늘 하루도 수고했어요 🌆';

    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, Gap.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${now.month}월 ${now.day}일 $dow요일',
            style: AppType.title.copyWith(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: sh.ink,
                height: 1.2),
          ),
          const SizedBox(height: 4),
          Text(greeting,
              style: AppType.body.copyWith(color: sh.inkSoft)),
        ],
      ),
    );
  }
}

// ─── 다음 일정 카드 ──────────────────────────────────────────────
class _NextEventCard extends StatelessWidget {
  final SpaceHourColors sh;
  final List<EventItem> upcoming;
  final List<EventItem> allToday;
  final List<CalendarTheme> themes;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  const _NextEventCard({
    required this.sh,
    required this.upcoming,
    required this.allToday,
    required this.themes,
    required this.onTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final hasNext = upcoming.isNotEmpty;
    final next = hasNext ? upcoming.first : null;
    final themeColor = next != null ? _resolveColor(next) : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(Gap.lg),
        decoration: BoxDecoration(
          color: hasNext
              ? (themeColor ?? sh.accent).withValues(alpha: sh.dark ? 0.18 : 0.10)
              : sh.card,
          borderRadius: BorderRadius.circular(Radii.card),
          border: Border.all(
            color: hasNext
                ? (themeColor ?? sh.accent).withValues(alpha: 0.35)
                : sh.border,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: sh.dark ? 0.3 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: Gap.sm, vertical: 3),
                  decoration: BoxDecoration(
                    color: (themeColor ?? sh.accent).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '다음 일정',
                    style: AppType.label.copyWith(
                        color: themeColor ?? sh.accentInk,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const Spacer(),
                if (allToday.length > 1)
                  Text('오늘 총 ${allToday.length}개',
                      style: AppType.label.copyWith(color: sh.inkSoft)),
              ],
            ),
            const SizedBox(height: Gap.sm),
            if (hasNext) ...[
              Text(
                next!.t,
                style: AppType.section.copyWith(
                    fontWeight: FontWeight.w700, color: sh.ink),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (next.tm != null) ...[
                const SizedBox(height: 4),
                Text(
                  '⏰ ${next.tm}${next.te != null ? ' ~ ${next.te}' : ''}',
                  style: AppType.body.copyWith(color: sh.inkSoft),
                ),
              ],
            ] else ...[
              Text(
                allToday.isEmpty ? '오늘 일정이 없어요' : '남은 일정이 없어요',
                style: AppType.section.copyWith(color: sh.inkFaint),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: onAdd,
                child: Text(
                  '+ 일정 추가하기',
                  style: AppType.body.copyWith(
                      color: sh.accent, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color? _resolveColor(EventItem e) {
    final ids = e.themeIds;
    if (ids.isEmpty) return null;
    try {
      return themes.firstWhere((t) => ids.contains(t.id)).colorValue;
    } catch (_) {
      return null;
    }
  }
}

// ─── 급식 카드 ───────────────────────────────────────────────────
class _MealCard extends StatelessWidget {
  final SpaceHourColors sh;
  final String? meal;
  final bool loaded;

  const _MealCard({required this.sh, required this.meal, required this.loaded});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Gap.md),
      constraints: const BoxConstraints(minHeight: 100),
      decoration: BoxDecoration(
        color: sh.card,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: sh.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: sh.dark ? 0.25 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('🍱', style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            Text('오늘 급식',
                style: AppType.label.copyWith(
                    fontWeight: FontWeight.w700, color: sh.inkSoft)),
          ]),
          const SizedBox(height: Gap.sm),
          if (!loaded)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (meal != null)
            Text(meal!,
                style: AppType.body.copyWith(
                    fontWeight: FontWeight.w600, color: sh.ink),
                maxLines: 2,
                overflow: TextOverflow.ellipsis)
          else
            Text(
              NeisSchool.load() == null ? 'NEIS 미연결' : '정보 없음',
              style: AppType.body.copyWith(color: sh.inkFaint),
            ),
        ],
      ),
    );
  }
}

// ─── 오늘 통계 카드 ──────────────────────────────────────────────
class _TodayStatsCard extends StatelessWidget {
  final SpaceHourColors sh;
  final int count;
  final VoidCallback onTap;

  const _TodayStatsCard(
      {required this.sh, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(Gap.md),
        constraints: const BoxConstraints(minHeight: 100),
        decoration: BoxDecoration(
          color: sh.card,
          borderRadius: BorderRadius.circular(Radii.card),
          border: Border.all(color: sh.border, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: sh.dark ? 0.25 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('📋', style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              Text('오늘 일정',
                  style: AppType.label.copyWith(
                      fontWeight: FontWeight.w700, color: sh.inkSoft)),
            ]),
            const SizedBox(height: Gap.sm),
            Text(
              '$count',
              style: AppType.title.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: count > 0 ? sh.accent : sh.inkFaint,
                  height: 1),
            ),
            Text('개',
                style: AppType.body.copyWith(color: sh.inkSoft)),
          ],
        ),
      ),
    );
  }
}

// ─── 이번 주 미니 스트립 ─────────────────────────────────────────
class _WeekStripCard extends StatelessWidget {
  final SpaceHourColors sh;
  final DateTime monday;
  final List<String> weekKeys;
  final Map<String, int> eventCounts;
  final String today;
  final void Function(String) onDayTap;

  static const _dowKr = ['월', '화', '수', '목', '금', '토', '일'];

  const _WeekStripCard({
    required this.sh,
    required this.monday,
    required this.weekKeys,
    required this.eventCounts,
    required this.today,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(
        color: sh.card,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: sh.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: sh.dark ? 0.25 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('이번 주',
              style: AppType.label.copyWith(
                  fontWeight: FontWeight.w700, color: sh.inkSoft)),
          const SizedBox(height: Gap.sm),
          Row(
            children: List.generate(7, (i) {
              final d = monday.add(Duration(days: i));
              final key = weekKeys[i];
              final isToday = key == today;
              final count = eventCounts[key] ?? 0;
              final isSat = d.weekday == DateTime.saturday;
              final isSun = d.weekday == DateTime.sunday;

              final dayColor = isToday
                  ? sh.accentInk
                  : isSun
                      ? sh.danger
                      : isSat
                          ? sh.sat
                          : sh.inkSoft;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onDayTap(key),
                  child: Column(
                    children: [
                      Text(_dowKr[i],
                          style: AppType.label.copyWith(color: dayColor)),
                      const SizedBox(height: 4),
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: isToday
                            ? BoxDecoration(
                                color: sh.accent, shape: BoxShape.circle)
                            : null,
                        child: Text(
                          '${d.day}',
                          style: AppType.caption.copyWith(
                            fontWeight: isToday
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isToday
                                ? (sh.dark ? sh.ink : Colors.white)
                                : sh.ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (count > 0)
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isToday ? sh.accentInk : sh.accent,
                            shape: BoxShape.circle,
                          ),
                        )
                      else
                        const SizedBox(height: 5),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
