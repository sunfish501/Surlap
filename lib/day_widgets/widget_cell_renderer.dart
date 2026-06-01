import 'package:flutter/material.dart';
import '../models/day_template.dart';
import '../core/theme/app_theme.dart';
import 'widget_number.dart';
import 'widget_line.dart';
import 'widget_memo.dart';
import 'widget_check.dart';
import 'widget_rating.dart';
import 'widget_tags.dart';
import 'widget_progress.dart';
import 'widget_counter.dart';
import 'widget_mood.dart';
import 'widget_slider.dart';
import 'widget_timerange.dart';

/// 달력 셀 안에 위젯을 표시하는 compact 렌더러.
/// 각 타입별 위젯 파일은 셀용(compact) + 편집용(edit) 두 모드를 가짐.
class WidgetCellRenderer extends StatelessWidget {
  final DayField field;
  final dynamic value;
  final SpaceHourColors sh;
  final bool compact;
  final ValueChanged<dynamic>? onChanged;

  const WidgetCellRenderer({
    super.key,
    required this.field,
    required this.value,
    required this.sh,
    this.compact = true,
    this.onChanged,
  });

  bool get _hasValue {
    if (value == null || value == '') { return false; }
    if (value is List && (value as List).isEmpty) { return false; }
    if (value is Map && (value as Map).isEmpty) { return false; }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasValue && compact) { return const SizedBox.shrink(); }
    switch (field.type) {
      case DayFieldType.number:
        return NumberWidget(field: field, value: value, sh: sh,
            compact: compact, onChanged: onChanged);
      case DayFieldType.line:
        return LineWidget(field: field, value: value, sh: sh,
            compact: compact, onChanged: onChanged);
      case DayFieldType.memo:
        return MemoWidget(field: field, value: value, sh: sh,
            compact: compact, onChanged: onChanged);
      case DayFieldType.check:
        return CheckWidget(field: field, value: value, sh: sh,
            compact: compact, onChanged: onChanged);
      case DayFieldType.rating:
        return RatingWidget(field: field, value: value, sh: sh,
            compact: compact, onChanged: onChanged);
      case DayFieldType.tags:
        return TagsWidget(field: field, value: value, sh: sh,
            compact: compact, onChanged: onChanged);
      case DayFieldType.progress:
        return ProgressWidget(field: field, value: value, sh: sh,
            compact: compact, onChanged: onChanged);
      case DayFieldType.counter:
        return CounterWidget(field: field, value: value, sh: sh,
            compact: compact, onChanged: onChanged);
      case DayFieldType.mood:
        return MoodWidget(field: field, value: value, sh: sh,
            compact: compact, onChanged: onChanged);
      case DayFieldType.slider:
        return SliderWidget(field: field, value: value, sh: sh,
            compact: compact, onChanged: onChanged);
      case DayFieldType.timerange:
        return TimerangeWidget(field: field, value: value, sh: sh,
            compact: compact, onChanged: onChanged);
    }
  }
}
