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
import '../../modals/neis_setup_modal.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  String? _mealText;
  bool _mealLoaded = false;
  bool _mealError = false; // fetch 실패(네트워크 등) — 미연결과 구분

  static const _dowKr = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  void initState() {
    super.initState();
    _loadMeal();
  }

  Future<void> _loadMeal() async {
    final school = NeisSchool.load();
    if (school == null) {
      setState(() {
        _mealLoaded = true;
        _mealError = false;
      });
      return;
    }
    setState(() {
      _mealLoaded = false;
      _mealError = false;
    });
    final dateStr = du.toDateKey(DateTime.now()).replaceAll('-', '');
    try {
      final meal = await fetchLunch(school, dateStr);
      if (mounted) {
        setState(() {
          _mealText = meal?.split('\n').first;
          _mealLoaded = true;
        });
      }
    } catch (e, st) {
      // 조용히 삼키지 말고 로그 남기고 UI로 부드럽게 안내.
      debugPrint('[Home] 급식 불러오기 실패: $e\n$st');
      if (mounted) {
        setState(() {
          _mealLoaded = true;
          _mealError = true;
        });
      }
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
          padding: const EdgeInsets.fromLTRB(Gap.xl, 0, Gap.xl, 110),
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
              const SizedBox(height: _cardGap),
              // 두 번째 행: 급식 + 오늘 통계
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _MealCard(
                        sh: sh,
                        meal: _mealText,
                        loaded: _mealLoaded,
                        error: _mealError,
                        onRetry: _loadMeal,
                      ),
                    ),
                    const SizedBox(width: _cardGap),
                    Expanded(
                      child: _TodayStatsCard(
                        sh: sh,
                        count: todayAll.length,
                        onTap: () => notifier.setDayView(todayKey),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: _cardGap),
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
      padding: const EdgeInsets.fromLTRB(Gap.xl, Gap.sm, Gap.xl, Gap.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 작은 오버라인 — 따뜻한 톤의 한 줄.
          Text(greeting,
              style: AppType.label.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                  color: sh.accent)),
          const SizedBox(height: 6),
          Text(
            '${now.month}월 ${now.day}일 $dow요일',
            style: AppType.title.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
                color: sh.ink,
                height: 1.15),
          ),
        ],
      ),
    );
  }
}

// ─── 홈 공통 스타일 (이 화면에서만 적용 — 전역 토큰은 유지) ──────────
const double _cardGap = 14;
const double _cardRadius = 22;

BoxDecoration _softCard(SpaceHourColors sh,
        {Color? color, double radius = _cardRadius, Color? border}) =>
    BoxDecoration(
      color: color ?? sh.card,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: border ?? sh.ink.withValues(alpha: 0.05)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: sh.dark ? 0.30 : 0.06),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
    );

/// 이모지를 둥근 틴트 배지 안에 넣어 정돈된 헤더 라벨을 만든다.
Widget _badgeLabel(SpaceHourColors sh, String emoji, String label, Color tint) =>
    Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(emoji, style: const TextStyle(fontSize: 15)),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: AppType.label.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: sh.inkSoft)),
      ],
    );

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

    final accent = themeColor ?? sh.accent;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: _softCard(
          sh,
          radius: 24,
          color: hasNext
              ? accent.withValues(alpha: sh.dark ? 0.18 : 0.09)
              : sh.card,
          border: hasNext
              ? accent.withValues(alpha: 0.28)
              : sh.ink.withValues(alpha: 0.05),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '다음 일정',
                    style: AppType.label.copyWith(
                        fontSize: 11.5,
                        color: themeColor ?? sh.accentInk,
                        fontWeight: FontWeight.w800),
                  ),
                ),
                const Spacer(),
                if (allToday.length > 1)
                  Text('오늘 총 ${allToday.length}개',
                      style: AppType.label.copyWith(
                          fontSize: 12, color: sh.inkSoft)),
              ],
            ),
            const SizedBox(height: 14),
            if (hasNext) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      next!.t,
                      style: AppType.title.copyWith(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: sh.ink),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      size: 22, color: accent.withValues(alpha: 0.7)),
                ],
              ),
              if (next.tm != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 15, color: accent),
                    const SizedBox(width: 5),
                    Text(
                      '${next.tm}${next.te != null ? ' ~ ${next.te}' : ''}',
                      style: AppType.body.copyWith(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: sh.inkSoft),
                    ),
                  ],
                ),
              ],
            ] else ...[
              Text(
                allToday.isEmpty ? '오늘 일정이 없어요' : '남은 일정이 없어요',
                style: AppType.title.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: sh.inkFaint),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: onAdd,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: sh.accent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded,
                          size: 16, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        '일정 추가하기',
                        style: AppType.label.copyWith(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
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
  final bool error;
  final VoidCallback onRetry;

  const _MealCard({
    required this.sh,
    required this.meal,
    required this.loaded,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(minHeight: 116),
      decoration: _softCard(sh, radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _badgeLabel(sh, '🍱', '오늘 급식', sh.accent.withValues(alpha: 0.10)),
          const SizedBox(height: 12),
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
          else if (NeisSchool.load() == null) ...[
            // NEIS 같은 기술 용어 대신 친근한 문구.
            Text('학교 미연결',
                style: AppType.body.copyWith(color: sh.inkFaint)),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => showNeisSetupModal(context),
              child: Text('학교 연결하기 →',
                  style: AppType.label.copyWith(
                      color: sh.accent, fontWeight: FontWeight.w600)),
            ),
          ] else if (error) ...[
            Text('급식 정보를 불러오지 못했어요',
                style: AppType.label.copyWith(color: sh.inkFaint, height: 1.3),
                maxLines: 2),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: onRetry,
              child: Text('다시 시도',
                  style: AppType.label.copyWith(
                      color: sh.accent, fontWeight: FontWeight.w700)),
            ),
          ] else
            Text('오늘 급식 정보가 없어요',
                style: AppType.body.copyWith(color: sh.inkFaint)),
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
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(minHeight: 116),
        decoration: _softCard(sh, radius: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _badgeLabel(sh, '📋', '오늘 일정', sh.accent.withValues(alpha: 0.10)),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$count',
                  style: AppType.title.copyWith(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      color: count > 0 ? sh.accent : sh.inkFaint,
                      height: 1),
                ),
                const SizedBox(width: 3),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text('개',
                      style: AppType.body.copyWith(
                          fontWeight: FontWeight.w600, color: sh.inkSoft)),
                ),
              ],
            ),
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
      padding: const EdgeInsets.all(16),
      decoration: _softCard(sh, radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _badgeLabel(sh, '🗓️', '이번 주', sh.accent.withValues(alpha: 0.10)),
          const SizedBox(height: 14),
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
