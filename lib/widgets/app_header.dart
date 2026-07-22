import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/design_tokens.dart';
import '../providers/view_provider.dart';
import 'view_segment_control.dart';

/// 캘린더 계열 화면에서만 보이는 단일 뷰 전환 행.
/// 날짜 제목과 검색은 전역 [SurlapAppBar]가 담당한다.
class AppHeader extends ConsumerWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(viewProvider).mode;
    final calendarMode = const {
      ViewMode.events,
      ViewMode.year,
      ViewMode.planner,
      ViewMode.day,
    }.contains(mode);
    if (!calendarMode) return const SizedBox.shrink();

    return const Padding(
      padding: EdgeInsets.fromLTRB(Gap.lg, Gap.xs, Gap.lg, Gap.sm),
      child: ViewSegmentControl(),
    );
  }
}
