import 'dart:convert';

/// 위젯 필드 타입 11종 (원본 그대로)
enum DayFieldType {
  number, line, memo, check, rating, tags,
  progress, counter, mood, slider, timerange,
}

extension DayFieldTypeExt on DayFieldType {
  String get key => name; // 'number', 'line', ...
  static DayFieldType fromKey(String k) =>
      DayFieldType.values.firstWhere((e) => e.name == k,
          orElse: () => DayFieldType.line);
}

class DayField {
  final String id;
  final DayFieldType type;
  final String label;
  final Map<String, dynamic> design;
  // type-specific extras
  final String? unit;       // number, progress, counter, slider
  final int? max;           // rating
  final int? levels;        // mood (3 or 5)
  final List<String>? options; // check
  final double? target;     // progress
  final double? step;       // counter
  final double? sliderMin;  // slider
  final double? sliderMax;  // slider

  const DayField({
    required this.id,
    required this.type,
    required this.label,
    this.design = const {},
    this.unit,
    this.max,
    this.levels,
    this.options,
    this.target,
    this.step,
    this.sliderMin,
    this.sliderMax,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.key,
    'label': label,
    'design': design,
    if (unit != null) 'unit': unit,
    if (max != null) 'max': max,
    if (levels != null) 'levels': levels,
    if (options != null) 'options': options,
    if (target != null) 'target': target,
    if (step != null) 'step': step,
    if (sliderMin != null) 'min': sliderMin,
    if (sliderMax != null) 'max': sliderMax,
  };

  factory DayField.fromJson(Map<String, dynamic> j) => DayField(
    id: (j['id'] ?? '').toString(),
    type: DayFieldTypeExt.fromKey((j['type'] ?? 'line').toString()),
    label: (j['label'] ?? '').toString(),
    design: (j['design'] as Map?)?.cast<String, dynamic>() ?? {},
    unit: j['unit'] as String?,
    max: j['max'] is int ? j['max'] as int : null,
    levels: j['levels'] is int ? j['levels'] as int : null,
    options: (j['options'] as List?)?.map((e) => e.toString()).toList(),
    target: (j['target'] as num?)?.toDouble(),
    step: (j['step'] as num?)?.toDouble(),
    sliderMin: (j['min'] as num?)?.toDouble(),
    sliderMax: (j['max'] as num?)?.toDouble(),
  );
}

class DayTemplateScope {
  final String mode; // 'all' | 'weekdays' | 'range' | 'days'
  final List<int>? weekdays;
  final String? start;
  final String? end;
  final List<String>? days;

  const DayTemplateScope({
    this.mode = 'all',
    this.weekdays,
    this.start,
    this.end,
    this.days,
  });

  Map<String, dynamic> toJson() => {
    'mode': mode,
    if (weekdays != null) 'weekdays': weekdays,
    if (start != null) 'start': start,
    if (end != null) 'end': end,
    if (days != null) 'days': days,
  };

  factory DayTemplateScope.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const DayTemplateScope();
    return DayTemplateScope(
      mode: (j['mode'] ?? 'all').toString(),
      weekdays: (j['weekdays'] as List?)?.map((e) => e as int).toList(),
      start: j['start'] as String?,
      end: j['end'] as String?,
      days: (j['days'] as List?)?.map((e) => e.toString()).toList(),
    );
  }

  bool appliesTo(String dateKey) {
    // 명시적으로 추가된 날짜(days)는 모드와 무관하게 항상 적용 —
    // 특정 날짜에 위젯을 "추가"하면 이 목록에 들어간다.
    if (days != null && days!.contains(dateKey)) return true;
    if (mode == 'all') return true;
    if (mode == 'weekdays') {
      final parts = dateKey.split('-');
      final dt = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      return weekdays?.contains(dt.weekday % 7) ?? false;
    }
    if (mode == 'range') {
      if (start == null || end == null) return false;
      return dateKey.compareTo(start!) >= 0 && dateKey.compareTo(end!) <= 0;
    }
    if (mode == 'days') return days?.contains(dateKey) ?? false;
    return false;
  }

  /// 특정 날짜를 적용 목록에 추가한 새 scope. 기존 모드/규칙은 보존한다.
  DayTemplateScope withDay(String dateKey) {
    if (days?.contains(dateKey) ?? false) return this;
    return DayTemplateScope(
      mode: mode,
      weekdays: weekdays,
      start: start,
      end: end,
      days: [...(days ?? const []), dateKey],
    );
  }
}

class DayTemplate {
  final String id;
  final String name;
  final List<DayField> fields;
  final DayTemplateScope scope;
  final bool enabled;
  /// 기록 템플릿(공부 트래커 등) 셀 표시용 대표 이모지. null이면 일반 위젯.
  final String? emoji;
  /// 셀에 숫자로 노출할 대표 지표 필드 id. null이면 대표 숫자 없음.
  final String? primaryFieldId;

  const DayTemplate({
    required this.id,
    required this.name,
    required this.fields,
    this.scope = const DayTemplateScope(),
    this.enabled = true,
    this.emoji,
    this.primaryFieldId,
  });

  DayTemplate copyWith({
    String? name,
    List<DayField>? fields,
    DayTemplateScope? scope,
    bool? enabled,
    String? emoji,
    String? primaryFieldId,
  }) =>
      DayTemplate(
        id: id,
        name: name ?? this.name,
        fields: fields ?? this.fields,
        scope: scope ?? this.scope,
        enabled: enabled ?? this.enabled,
        emoji: emoji ?? this.emoji,
        primaryFieldId: primaryFieldId ?? this.primaryFieldId,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'fields': fields.map((f) => f.toJson()).toList(),
    'scope': scope.toJson(),
    'enabled': enabled,
    if (emoji != null) 'emoji': emoji,
    if (primaryFieldId != null) 'primaryFieldId': primaryFieldId,
  };

  factory DayTemplate.fromJson(Map<String, dynamic> j) => DayTemplate(
    id: (j['id'] ?? '').toString(),
    name: (j['name'] ?? '').toString(),
    fields: (j['fields'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(DayField.fromJson)
        .toList(),
    scope: DayTemplateScope.fromJson(j['scope'] as Map<String, dynamic>?),
    enabled: j['enabled'] != false,
    emoji: j['emoji'] as String?,
    primaryFieldId: j['primaryFieldId'] as String?,
  );

  static List<DayTemplate> listFromJson(String raw) {
    try {
      final list = jsonDecode(raw) as List;
      return list.whereType<Map<String, dynamic>>().map(DayTemplate.fromJson).toList();
    } catch (_) {
      return [];
    }
  }

  static String listToJson(List<DayTemplate> tpls) =>
      jsonEncode(tpls.map((t) => t.toJson()).toList());
}
