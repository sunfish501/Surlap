import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/date_utils.dart' as du;
import '../../providers/events_provider.dart';
import '../../providers/themes_provider.dart';
import '../../providers/view_provider.dart';
import '../../models/event_item.dart';
import '../../models/calendar_theme.dart';
import '../../modals/add_edit_event_modal.dart';

/// 일별 뷰 — 주간 뷰의 하루를 확대한 형태.
/// 왼쪽에 시간대(0~23시) 축을 두고, 시간 일정은 해당 시각에 블록으로 배치한다.
class DayView extends ConsumerStatefulWidget {
  final String dateKey;
  const DayView({super.key, required this.dateKey});

  @override
  ConsumerState<DayView> createState() => _DayViewState();
}

class _DayViewState extends ConsumerState<DayView> {
  static const _timeColW = 44.0;
  static const _rowH = 48.0;

  late final ScrollController _scroll;

  @override
  void initState() {
    super.initState();
    final date = du.fromDateKey(widget.dateKey);
    final now = DateTime.now();
    // 오늘이면 현재 시각 근처, 아니면 오전 7시쯤부터 보이게.
    final startHour = du.isSameDay(date, now)
        ? (now.hour - 1).clamp(0, 20)
        : 7;
    _scroll = ScrollController(initialScrollOffset: startHour * _rowH);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    final events = ref.watch(eventsProvider);
    final themes = ref.watch(themesProvider);
    final date = du.fromDateKey(widget.dateKey);
    final items = events[widget.dateKey] ?? [];
    final now = DateTime.now();
    final isToday = du.isSameDay(date, now);

    final allDay = items.where((e) => !e.hasTime && !e.isTimetable).toList();
    final timed = items.where((e) => e.hasTime && !e.isTimetable).toList()
      ..sort((a, b) => (a.tm ?? '').compareTo(b.tm ?? ''));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 날짜 헤더
        Padding(
          padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, Gap.xs),
          child: Row(
            children: [
              GestureDetector(
                onTap: () =>
                    ref.read(viewProvider.notifier).setMode(ViewMode.events),
                child: Icon(Icons.arrow_back_ios_rounded,
                    size: 16, color: sh.inkSoft),
              ),
              const SizedBox(width: Gap.sm),
              Text(
                '${date.month}월 ${date.day}일 (${_dowName(date.weekday)})',
                style: AppType.section.copyWith(fontWeight: FontWeight.w700, color: sh.ink),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () =>
                    showAddEditEventModal(context, dateKey: widget.dateKey),
                child: Icon(Icons.add_rounded, size: 22, color: sh.accent),
              ),
            ],
          ),
        ),
        // 종일 일정
        if (allDay.isNotEmpty) _AllDayBar(items: allDay, themes: themes, sh: sh),
        // 시간 축 + 하루 타임라인
        Expanded(
          child: LayoutBuilder(builder: (context, constraints) {
            final dayColW = constraints.maxWidth - _timeColW;
            return SingleChildScrollView(
              controller: _scroll,
              padding: const EdgeInsets.only(bottom: 80),
              child: SizedBox(
                height: _rowH * 24,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 시간 레이블 컬럼
                    SizedBox(
                      width: _timeColW,
                      child: Column(
                        children: List.generate(24, (h) {
                          return SizedBox(
                            height: _rowH,
                            child: Align(
                              alignment: Alignment.topRight,
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(right: 6, top: 2),
                                child: Text(
                                  h == 0 ? '' : '$h:00',
                                  style: TextStyle(
                                      fontSize: 10, color: sh.inkFaint),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    // 하루 컬럼
                    Expanded(
                      child: Stack(
                        children: [
                          // 시간 그리드 (탭하면 일정 추가)
                          GestureDetector(
                            onTapDown: (_) => showAddEditEventModal(context,
                                dateKey: widget.dateKey),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  left:
                                      BorderSide(color: sh.border, width: 0.5),
                                ),
                              ),
                              child: Column(
                                children: List.generate(
                                  24,
                                  (h) => Container(
                                    height: _rowH,
                                    decoration: BoxDecoration(
                                      border: Border(
                                        top: BorderSide(
                                            color: sh.border, width: 0.5),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // 시간 일정 블록
                          ..._eventBlocks(timed, dayColW, themes, sh, events),
                          // 현재 시각 선
                          if (isToday)
                            _NowLine(
                                hour: now.hour, minute: now.minute, rowH: _rowH, sh: sh),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  List<Widget> _eventBlocks(
    List<EventItem> timed,
    double colW,
    List<CalendarTheme> themes,
    SpaceHourColors sh,
    Map<String, List<EventItem>> events,
  ) {
    final blocks = <Widget>[];
    for (final e in timed) {
      final parts = e.tm!.split(':');
      final h = int.tryParse(parts[0]) ?? 0;
      final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      final top = h * _rowH + m * _rowH / 60;
      double height = _rowH;
      if (e.te != null && e.te!.contains(':')) {
        final ep = e.te!.split(':');
        final eh = int.tryParse(ep[0]) ?? h;
        final em = int.tryParse(ep[1]) ?? m;
        height = ((eh - h) * 60 + (em - m)) * _rowH / 60;
      }
      final thColor = e.themeIds.isNotEmpty
          ? themes
              .firstWhere(
                (t) => e.themeIds.contains(t.id),
                orElse: () =>
                    const CalendarTheme(id: '', name: '', color: '#6b8ec2'),
              )
              .colorValue
          : sh.accent;

      blocks.add(Positioned(
        top: top,
        left: 4,
        right: 6,
        height: height.clamp(20.0, double.infinity),
        child: GestureDetector(
          onTap: () {
            final idx = (events[widget.dateKey] ?? []).indexOf(e);
            showAddEditEventModal(context,
                dateKey: widget.dateKey, editIndex: idx);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: Gap.sm, vertical: Gap.xs),
            decoration: BoxDecoration(
              color: thColor.withValues(alpha: sh.dark ? 0.20 : 0.16),
              borderRadius: BorderRadius.circular(6),
              border: Border(left: BorderSide(color: thColor, width: 3)),
              boxShadow: sh.dark
                  ? [BoxShadow(
                      color: thColor.withValues(alpha: 0.22),
                      blurRadius: 10, spreadRadius: 0,
                      offset: const Offset(0, 1),
                    )]
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${e.tm} ',
                    style: TextStyle(
                        fontSize: 10,
                        color: sh.inkSoft,
                        fontWeight: FontWeight.w600)),
                Expanded(
                  child: Text(
                    e.t,
                    style: AppType.caption.copyWith(
                        fontWeight: FontWeight.w500, color: sh.ink),
                    maxLines: height > _rowH ? 3 : 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ));
    }
    return blocks;
  }

  String _dowName(int w) => ['월', '화', '수', '목', '금', '토', '일'][w - 1];
}

class _AllDayBar extends StatelessWidget {
  final List<EventItem> items;
  final List<CalendarTheme> themes;
  final SpaceHourColors sh;
  const _AllDayBar(
      {required this.items, required this.themes, required this.sh});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.xs),
      padding: const EdgeInsets.symmetric(horizontal: Gap.sm + 2, vertical: Gap.xs),
      decoration: BoxDecoration(
        color: sh.card2,
        borderRadius: BorderRadius.circular(Radii.small),
        border: Border.all(color: sh.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('종일',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: sh.inkSoft,
                  letterSpacing: 0.4)),
          const SizedBox(height: 2),
          ...items.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Text(e.t,
                    style: AppType.body.copyWith(color: sh.ink)),
              )),
        ],
      ),
    );
  }
}

class _NowLine extends StatelessWidget {
  final int hour, minute;
  final double rowH;
  final SpaceHourColors sh;
  const _NowLine(
      {required this.hour,
      required this.minute,
      required this.rowH,
      required this.sh});

  @override
  Widget build(BuildContext context) {
    final top = hour * rowH + minute * rowH / 60;
    return Positioned(
      top: top - 1,
      left: 0,
      right: 0,
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: sh.danger,
              shape: BoxShape.circle,
              boxShadow: sh.dark
                  ? [BoxShadow(
                      color: sh.danger.withValues(alpha: 0.5),
                      blurRadius: 6, spreadRadius: 1,
                    )]
                  : null,
            ),
          ),
          Expanded(
            child: Container(
              height: 1.5,
              decoration: BoxDecoration(
                color: sh.danger.withValues(alpha: 0.7),
                boxShadow: sh.dark
                    ? [BoxShadow(
                        color: sh.danger.withValues(alpha: 0.4),
                        blurRadius: 4, spreadRadius: 1,
                      )]
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
