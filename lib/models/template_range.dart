import 'dart:convert';

/// 기록 템플릿 적용 기간.
/// 데이터 분리: 템플릿 정의(RecordTemplate) / 적용 기간(여기) / 일자 기록(widgetValues).
class TemplateRange {
  final String id;
  final String templateId;
  final String start; // 'YYYY-MM-DD'
  final String end; // 'YYYY-MM-DD' (포함)

  const TemplateRange({
    required this.id,
    required this.templateId,
    required this.start,
    required this.end,
  });

  bool covers(String dateKey) =>
      dateKey.compareTo(start) >= 0 && dateKey.compareTo(end) <= 0;

  TemplateRange copyWith({String? start, String? end}) => TemplateRange(
        id: id,
        templateId: templateId,
        start: start ?? this.start,
        end: end ?? this.end,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'templateId': templateId,
        'start': start,
        'end': end,
      };

  factory TemplateRange.fromJson(Map<String, dynamic> j) => TemplateRange(
        id: (j['id'] ?? '').toString(),
        templateId: (j['templateId'] ?? '').toString(),
        start: (j['start'] ?? '').toString(),
        end: (j['end'] ?? '').toString(),
      );

  static List<TemplateRange> listFromJson(String raw) {
    try {
      return (jsonDecode(raw) as List)
          .whereType<Map<String, dynamic>>()
          .map(TemplateRange.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static String listToJson(List<TemplateRange> r) =>
      jsonEncode(r.map((e) => e.toJson()).toList());
}
