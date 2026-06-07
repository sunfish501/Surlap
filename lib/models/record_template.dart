import 'dart:convert';
import 'template_range.dart';

// ─── 일반화된 기록 템플릿 ───────────────────────────────────────────────
// 구조: 이모지 + 이름 + 대표 숫자 항목 1개 + (선택) 태그/메모.
// 종류만 다르고 틀은 동일. 필드 타입은 숫자/태그/메모 3가지로만 제한.
//
// daily_log 는 widgetValues[date][templateId] 에 아래 고정 키로 저장:
const String kRecPrimary = 'primary'; // 대표 숫자(num)
const String kRecTags = 'tags'; // 태그 칩(List<String>)
const String kRecMemo = 'memo'; // 한 줄 메모(String)

class RecordTemplate {
  final String id;
  final String name;
  final String emoji;
  final String primaryLabel; // 예: "순공시간"
  final String primaryUnit; // 예: "h", "p", "분"
  final bool hasTags;
  final String tagsLabel; // 예: "과목", "책 제목"
  final bool hasMemo;
  final bool isPreset;

  const RecordTemplate({
    required this.id,
    required this.name,
    required this.emoji,
    required this.primaryLabel,
    required this.primaryUnit,
    this.hasTags = false,
    this.tagsLabel = '태그',
    this.hasMemo = false,
    this.isPreset = false,
  });

  RecordTemplate copyWith({
    String? id,
    String? name,
    String? emoji,
    String? primaryLabel,
    String? primaryUnit,
    bool? hasTags,
    String? tagsLabel,
    bool? hasMemo,
    bool? isPreset,
  }) =>
      RecordTemplate(
        id: id ?? this.id,
        name: name ?? this.name,
        emoji: emoji ?? this.emoji,
        primaryLabel: primaryLabel ?? this.primaryLabel,
        primaryUnit: primaryUnit ?? this.primaryUnit,
        hasTags: hasTags ?? this.hasTags,
        tagsLabel: tagsLabel ?? this.tagsLabel,
        hasMemo: hasMemo ?? this.hasMemo,
        isPreset: isPreset ?? this.isPreset,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'primaryLabel': primaryLabel,
        'primaryUnit': primaryUnit,
        'hasTags': hasTags,
        'tagsLabel': tagsLabel,
        'hasMemo': hasMemo,
        'isPreset': isPreset,
      };

  factory RecordTemplate.fromJson(Map<String, dynamic> j) => RecordTemplate(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        emoji: (j['emoji'] ?? '📌').toString(),
        primaryLabel: (j['primaryLabel'] ?? '값').toString(),
        primaryUnit: (j['primaryUnit'] ?? '').toString(),
        hasTags: j['hasTags'] == true,
        tagsLabel: (j['tagsLabel'] ?? '태그').toString(),
        hasMemo: j['hasMemo'] == true,
        isPreset: j['isPreset'] == true,
      );

  static List<RecordTemplate> listFromJson(String raw) {
    try {
      return (jsonDecode(raw) as List)
          .whereType<Map<String, dynamic>>()
          .map(RecordTemplate.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static String listToJson(List<RecordTemplate> t) =>
      jsonEncode(t.map((e) => e.toJson()).toList());
}

// ─── 기본 프리셋(코드 상수) ─────────────────────────────────────────────
// study-tracker id는 기존 공부 데이터와 호환 위해 유지.
const RecordTemplate kPresetStudy = RecordTemplate(
  id: 'study-tracker',
  name: '공부 트래커',
  emoji: 'menu_book',
  primaryLabel: '순공시간',
  primaryUnit: 'h',
  hasTags: true,
  tagsLabel: '과목',
  hasMemo: true,
  isPreset: true,
);
const RecordTemplate kPresetReading = RecordTemplate(
  id: 'reading-tracker',
  name: '집중 독서',
  emoji: 'auto_stories',
  primaryLabel: '읽은 페이지',
  primaryUnit: 'p',
  hasTags: true,
  tagsLabel: '책 제목',
  hasMemo: true,
  isPreset: true,
);
const RecordTemplate kPresetExercise = RecordTemplate(
  id: 'exercise-tracker',
  name: '운동',
  emoji: 'directions_run',
  primaryLabel: '운동 시간',
  primaryUnit: '분',
  hasTags: false,
  hasMemo: true,
  isPreset: true,
);

const List<RecordTemplate> kPresetTemplates = [
  kPresetStudy,
  kPresetReading,
  kPresetExercise,
];

// ─── 셀 표시용 뱃지 ─────────────────────────────────────────────────────
class RecordBadge {
  final String emoji;
  final String? primaryText; // null = 기록 없음 → 흐리게
  const RecordBadge({required this.emoji, this.primaryText});
  bool get hasData => primaryText != null;
}

/// 숫자 깔끔 표기: 4.0 → "4", 4.5 → "4.5".
String fmtMetric(num v) {
  final d = v.toDouble();
  if (d == d.roundToDouble()) return d.toInt().toString();
  return d.toStringAsFixed(1);
}

/// 그 날짜에 적용된 기록 템플릿들의 셀 뱃지(이모지+대표지표) 계산.
/// dayValues = widgetValues[dateKey] (= { templateId: { fieldId: value } }).
List<RecordBadge> recordBadgesForDate(
  String dateKey,
  List<TemplateRange> ranges,
  Map<String, Map<String, dynamic>>? dayValues,
  Map<String, RecordTemplate> byId,
) {
  final out = <RecordBadge>[];
  final seen = <String>{};
  for (final r in ranges) {
    if (seen.contains(r.templateId)) continue;
    if (!r.covers(dateKey)) continue;
    seen.add(r.templateId);
    final tpl = byId[r.templateId];
    if (tpl == null) continue;
    final raw = dayValues?[r.templateId]?[kRecPrimary];
    String? text;
    if (raw is num) {
      text = fmtMetric(raw);
    } else if (raw != null && raw.toString().isNotEmpty) {
      text = raw.toString();
    }
    out.add(RecordBadge(emoji: tpl.emoji, primaryText: text));
  }
  return out;
}
