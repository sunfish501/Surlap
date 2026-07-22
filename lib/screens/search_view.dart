import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';
import '../core/utils/date_utils.dart' as du;
import '../models/event_item.dart';
import '../models/todo_item.dart';
import '../providers/events_provider.dart';
import '../providers/recurring_provider.dart';
import '../providers/sports_provider.dart';
import '../providers/todos_provider.dart';
import '../providers/view_provider.dart';

enum SearchHitType { event, todo, timetable, sport }

class SearchHit {
  const SearchHit({
    required this.type,
    required this.title,
    this.dateKey = '',
    this.time = '',
    this.detail = '',
    this.priority = 0,
  });

  final SearchHitType type;
  final String title;
  final String dateKey;
  final String time;
  final String detail;
  final int priority;
}

/// 레거시 호출부는 전체 화면 검색으로 연결한다.
Future<void> showSearchSheet(BuildContext context) async {
  final container = ProviderScope.containerOf(context, listen: false);
  container.read(viewProvider.notifier).openSearch();
}

class SearchView extends ConsumerStatefulWidget {
  const SearchView({super.key});

  @override
  ConsumerState<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends ConsumerState<SearchView> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  SearchHitType? _filter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    final query = _controller.text.trim();
    final allHits = _hits(query);
    final hits = _filter == null
        ? allHits
        : allHits.where((hit) => hit.type == _filter).toList();

    return SafeArea(
      child: Column(
        children: [
          SizedBox(
            height: 60,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gap.md),
              child: Row(
                children: [
                  IconButton(
                    tooltip: '뒤로',
                    constraints: const BoxConstraints.tightFor(
                      width: kMinTouch,
                      height: kMinTouch,
                    ),
                    onPressed: () =>
                        ref.read(viewProvider.notifier).closeSearch(),
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: sh.inkSoft,
                    ),
                  ),
                  const SizedBox(width: Gap.xs),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      textInputAction: TextInputAction.search,
                      onChanged: (_) => setState(() {}),
                      style: AppType.bodyLarge.copyWith(color: sh.ink),
                      decoration: InputDecoration(
                        hintText: '일정, 과제, 시간표 검색',
                        hintStyle: AppType.bodyLarge.copyWith(
                          color: sh.inkSoft,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: sh.inkSoft,
                        ),
                        suffixIcon: query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: '검색어 지우기',
                                onPressed: () => setState(_controller.clear),
                                icon: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: sh.inkSoft,
                                ),
                              ),
                        filled: true,
                        fillColor: sh.card,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 11,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: sh.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: sh.accent, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _filters(sh, allHits),
          Expanded(
            child: query.isEmpty
                ? _SearchSuggestions(onSelect: _setQuery)
                : hits.isEmpty
                ? const _SearchEmpty()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      Gap.lg,
                      Gap.md,
                      Gap.lg,
                      Gap.xl,
                    ),
                    itemCount: hits.length,
                    separatorBuilder: (_, _) => const SizedBox(height: Gap.sm),
                    itemBuilder: (_, index) => _SearchResultCard(
                      hit: hits[index],
                      query: query,
                      onTap: () => _open(hits[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filters(SurlapColors sh, List<SearchHit> hits) {
    int count(SearchHitType type) =>
        hits.where((hit) => hit.type == type).length;
    final items = <(String, SearchHitType?, int)>[
      ('전체', null, hits.length),
      ('일정', SearchHitType.event, count(SearchHitType.event)),
      ('과제', SearchHitType.todo, count(SearchHitType.todo)),
      ('시간표', SearchHitType.timetable, count(SearchHitType.timetable)),
      ('스포츠', SearchHitType.sport, count(SearchHitType.sport)),
    ];
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: Gap.lg,
          vertical: Gap.xs,
        ),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: Gap.sm),
        itemBuilder: (_, index) {
          final (label, type, count) = items[index];
          final selected = _filter == type;
          return ChoiceChip(
            selected: selected,
            label: Text(
              _controller.text.trim().isEmpty ? label : '$label $count',
            ),
            onSelected: (_) => setState(() => _filter = type),
            showCheckmark: false,
            side: BorderSide(color: selected ? Colors.transparent : sh.border),
            selectedColor: sh.accent.withValues(alpha: sh.dark ? 0.2 : 0.12),
            backgroundColor: sh.card2,
            labelStyle: AppType.labelMedium.copyWith(
              color: selected ? sh.accent : sh.inkSoft,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.small),
            ),
          );
        },
      ),
    );
  }

  List<SearchHit> _hits(String query) {
    final q = query.toLowerCase();
    if (q.isEmpty) return const [];
    final result = <SearchHit>[];
    final events = ref.watch(eventsProvider);
    for (final entry in events.entries) {
      for (final EventItem event in entry.value) {
        if (event.isTimetable || !event.t.toLowerCase().contains(q)) continue;
        result.add(
          SearchHit(
            type: event.sport ? SearchHitType.sport : SearchHitType.event,
            title: event.t,
            dateKey: entry.key,
            time: event.tm ?? '',
            detail: event.sport ? '스포츠' : '일정',
          ),
        );
      }
    }
    for (final entry in ref.watch(sportsEventsByDateProvider).entries) {
      for (final event in entry.value) {
        if (!event.t.toLowerCase().contains(q)) continue;
        result.add(
          SearchHit(
            type: SearchHitType.sport,
            title: event.t,
            dateKey: entry.key,
            time: event.tm ?? '',
            detail: '스포츠',
          ),
        );
      }
    }
    for (final TodoItem todo in ref.watch(todosProvider)) {
      if (!todo.title.toLowerCase().contains(q)) continue;
      result.add(
        SearchHit(
          type: SearchHitType.todo,
          title: todo.title,
          dateKey: todo.dateKey ?? '',
          priority: todo.priority,
          detail: '과제',
        ),
      );
    }
    final recurring = ref.watch(recurringProvider);
    recurring.forEach((weekday, entries) {
      entries.forEach((hour, title) {
        if (!title.toLowerCase().contains(q)) return;
        result.add(
          SearchHit(
            type: SearchHitType.timetable,
            title: title,
            time: '${hour.toString().padLeft(2, '0')}:00',
            detail: '${_weekday(weekday)}요일 · 시간표',
          ),
        );
      });
    });
    result.sort((a, b) => b.dateKey.compareTo(a.dateKey));
    return result;
  }

  void _setQuery(String query) {
    _controller.text = query;
    _controller.selection = TextSelection.collapsed(offset: query.length);
    setState(() {});
  }

  void _open(SearchHit hit) {
    final notifier = ref.read(viewProvider.notifier);
    if (hit.type == SearchHitType.timetable) {
      notifier.setMode(ViewMode.timetable);
    } else if (hit.dateKey.isNotEmpty) {
      notifier.setDayView(hit.dateKey);
    }
  }

  String _weekday(int index) =>
      const ['월', '화', '수', '목', '금', '토', '일'][index.clamp(0, 6)];
}

class _SearchSuggestions extends StatelessWidget {
  const _SearchSuggestions({required this.onSelect});
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    const words = ['기말고사', '학원', '수행평가', '체육대회', '급식'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, Gap.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '추천 검색어',
            style: AppType.bodySmall.copyWith(
              color: sh.inkSoft,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: Gap.sm),
          Wrap(
            spacing: Gap.sm,
            runSpacing: Gap.sm,
            children: [
              for (final word in words)
                ActionChip(
                  label: Text(word),
                  onPressed: () => onSelect(word),
                  side: BorderSide(color: sh.border),
                  backgroundColor: sh.card2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.small),
                  ),
                ),
            ],
          ),
          const Expanded(child: _SearchEmpty(initial: true)),
        ],
      ),
    );
  }
}

class _SearchEmpty extends StatelessWidget {
  const _SearchEmpty({this.initial = false});
  final bool initial;

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Gap.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_rounded, size: 40, color: sh.border),
            const SizedBox(height: Gap.sm),
            Text(
              initial ? '최근 검색 기록이 없어요' : '검색 결과가 없어요',
              textAlign: TextAlign.center,
              style: AppType.bodyLarge.copyWith(color: sh.inkSoft),
            ),
            Text(
              initial ? '일정, 과제, 시간표를 검색해보세요' : '다른 검색어를 입력해보세요',
              textAlign: TextAlign.center,
              style: AppType.bodySmall.copyWith(color: sh.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({
    required this.hit,
    required this.query,
    required this.onTap,
  });

  final SearchHit hit;
  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    final color = _typeColor(hit.type, sh);
    final date = hit.dateKey.isEmpty
        ? ''
        : () {
            final value = du.fromDateKey(hit.dateKey);
            return '${value.month}월 ${value.day}일';
          }();
    final detail = [
      date,
      hit.time,
      hit.detail,
    ].where((value) => value.isNotEmpty).join(' · ');
    return Material(
      color: sh.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: sh.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 3, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(Gap.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HighlightedText(text: hit.title, query: query),
                      if (detail.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          detail,
                          style: AppType.bodySmall.copyWith(color: sh.inkSoft),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _typeColor(SearchHitType type, SurlapColors sh) =>
      switch (type) {
        SearchHitType.event => const Color(0xFF1C7ED6),
        SearchHitType.todo => const Color(0xFFE8590C),
        SearchHitType.timetable => sh.accent,
        SearchHitType.sport => const Color(0xFF2F9E44),
      };
}

class _HighlightedText extends StatelessWidget {
  const _HighlightedText({required this.text, required this.query});
  final String text;
  final String query;

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    final lower = text.toLowerCase();
    final index = lower.indexOf(query.toLowerCase());
    final base = AppType.bodyLarge.copyWith(
      color: sh.ink,
      fontWeight: FontWeight.w600,
    );
    if (index < 0) return Text(text, style: base);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: text.substring(0, index), style: base),
          TextSpan(
            text: text.substring(index, index + query.length),
            style: base.copyWith(color: sh.accent),
          ),
          TextSpan(text: text.substring(index + query.length), style: base),
        ],
      ),
    );
  }
}
