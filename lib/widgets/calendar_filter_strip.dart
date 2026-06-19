import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';
import '../i18n/strings.dart';
import '../providers/themes_provider.dart';
import '../providers/filter_provider.dart';
import '../providers/birthdays_provider.dart';
import '../providers/academic_schedule_provider.dart';
import '../providers/sports_provider.dart';
import '../screens/settings_view.dart' show CategoryFilterChip;

/// 달력 위에 바로 보이는 카테고리 필터 — 예전엔 설정 안에만 있던 걸 밖으로 뺐다.
/// 가로 스크롤 칩으로 카테고리를 즉시 켜고 끈다.
class CalendarFilterStrip extends ConsumerWidget {
  const CalendarFilterStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sh = context.sh;
    final themes = ref.watch(themesProvider);
    final hidden = ref.watch(filterProvider);
    final birthdays = ref.watch(birthdaysProvider);
    final academic = ref.watch(academicScheduleProvider);
    final sportsSubs = ref.watch(sportsSubscriptionsProvider);

    // 표시할 카테고리(테마/생일/학사/스포츠)가 전혀 없으면 노출하지 않는다.
    if (themes.isEmpty &&
        birthdays.isEmpty &&
        academic.isEmpty &&
        sportsSubs.isEmpty) {
      return const SizedBox.shrink();
    }

    // 전체 토글이 다뤄야 할 모든 카테고리 id(테마·생일·학사·스포츠).
    final allIds = <String>[
      ...themes.map((t) => t.id),
      if (birthdays.isNotEmpty) birthdayThemeId,
      if (academic.isNotEmpty) academicThemeId,
      ...sportsSubs.where((s) => s.enabled).map((s) => s.id),
    ];

    final chips = <Widget>[
      CategoryFilterChip(
        label: tr('전체'),
        color: sh.inkSoft,
        selected: hidden.isEmpty,
        sh: sh,
        onTap: () {
          final f = ref.read(filterProvider.notifier);
          // 모두 보임 → 전부 숨김 / 일부라도 숨김 → 전부 보임.
          if (hidden.isEmpty) {
            f.setAll(allIds);
          } else {
            f.clear();
          }
        },
      ),
      ...themes.map((t) => CategoryFilterChip(
            label: tr(t.name),
            color: t.colorValue,
            selected: !hidden.contains(t.id),
            sh: sh,
            onTap: () => ref.read(filterProvider.notifier).toggle(t.id),
          )),
      if (birthdays.isNotEmpty)
        CategoryFilterChip(
          label: tr('생일'),
          color: sh.birthdayColor,
          selected: !hidden.contains(birthdayThemeId),
          sh: sh,
          onTap: () =>
              ref.read(filterProvider.notifier).toggle(birthdayThemeId),
        ),
      if (academic.isNotEmpty)
        CategoryFilterChip(
          label: tr('학사일정'),
          color: sh.academicColor,
          selected: !hidden.contains(academicThemeId),
          sh: sh,
          onTap: () =>
              ref.read(filterProvider.notifier).toggle(academicThemeId),
        ),
      // 스포츠 구독 — 구독별 칩(이모지+팀명, 고유색).
      ...sportsSubs.where((s) => s.enabled).map((s) => CategoryFilterChip(
            label: '${s.emoji} ${tr(s.teamName)}',
            color: Color(s.color),
            selected: !hidden.contains(s.id),
            sh: sh,
            onTap: () => ref.read(filterProvider.notifier).toggle(s.id),
          )),
    ];

    return SizedBox(
      height: 38,
      // 우측 끝을 페이드 → "잘림"이 아니라 "더 있어요"로 읽히게.
      child: ShaderMask(
        shaderCallback: (rect) => const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Colors.white, Colors.white, Colors.transparent],
          stops: [0.0, 0.92, 1.0],
        ).createShader(rect),
        blendMode: BlendMode.dstIn,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(Gap.xl, 2, Gap.xl, 2),
          itemCount: chips.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, i) => Center(child: chips[i]),
        ),
      ),
    );
  }
}
