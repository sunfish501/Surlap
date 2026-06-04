import 'dart:convert';

/// 웹 item 구조 그대로 유지.
/// `{ t, tm?, te?, th?(string|List), tt?, _author?, _cid?, id?, created_at? }`
/// 또는 레거시 string.
class EventItem {
  final String t;          // 내용
  final String? tm;        // 시작 HH:MM
  final String? te;        // 종료 HH:MM
  final dynamic th;        // 테마 id (String 또는 List<String>)
  final bool tt;           // 시간표 여부
  final String? id;
  final String? cid;       // _cid
  final String? author;    // _author
  final String? createdAt;
  /// NEIS 학사일정 등 외부 표시 전용(읽기 전용) — 저장/편집 대상 아님(직렬화 제외).
  final bool academic;
  /// 생일(읽기 전용 표시) — 직렬화 제외.
  final bool birthday;

  const EventItem({
    required this.t,
    this.tm,
    this.te,
    this.th,
    this.tt = false,
    this.id,
    this.cid,
    this.author,
    this.createdAt,
    this.academic = false,
    this.birthday = false,
  });

  bool get isTimetable => tt;
  bool get hasTime => tm != null && tm!.isNotEmpty;

  List<String> get themeIds {
    if (th == null) return [];
    if (th is String) return [th as String];
    if (th is List) return (th as List).map((e) => e.toString()).toList();
    return [];
  }

  Map<String, dynamic> toJson() => {
    't': t,
    if (tm != null) 'tm': tm,
    if (te != null) 'te': te,
    if (th != null) 'th': th,
    if (tt) 'tt': true,
    if (id != null) 'id': id,
    if (cid != null) '_cid': cid,
    if (author != null) '_author': author,
    if (createdAt != null) 'created_at': createdAt,
  };

  factory EventItem.fromJson(Map<String, dynamic> j) => EventItem(
    t: (j['t'] ?? '').toString(),
    tm: j['tm'] as String?,
    te: j['te'] as String?,
    th: j['th'],
    tt: j['tt'] == true,
    id: j['id'] as String?,
    cid: j['_cid'] as String?,
    author: j['_author'] as String?,
    createdAt: j['created_at'] as String?,
  );

  /// 웹 호환: string 또는 object 파싱
  static EventItem fromRaw(dynamic raw) {
    if (raw is String) return EventItem(t: raw);
    if (raw is Map<String, dynamic>) return EventItem.fromJson(raw);
    return EventItem(t: raw.toString());
  }

  EventItem copyWith({
    String? t, String? tm, String? te, dynamic th, bool? tt,
    String? id, String? cid, String? author, String? createdAt,
    bool? academic, bool? birthday,
  }) => EventItem(
    t: t ?? this.t,
    tm: tm ?? this.tm,
    te: te ?? this.te,
    th: th ?? this.th,
    tt: tt ?? this.tt,
    id: id ?? this.id,
    cid: cid ?? this.cid,
    author: author ?? this.author,
    createdAt: createdAt ?? this.createdAt,
    academic: academic ?? this.academic,
    birthday: birthday ?? this.birthday,
  );
}

/// 전체 이벤트 맵 직렬화/역직렬화.
/// 형태: { "YYYY-MM-DD": [ item, ... ] }
Map<String, List<EventItem>> eventsFromJson(String raw) {
  try {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final result = <String, List<EventItem>>{};
    map.forEach((k, v) {
      if (k.startsWith('__')) return;
      if (v is List) {
        result[k] = v.map((e) => EventItem.fromRaw(e)).toList();
      }
    });
    return result;
  } catch (_) {
    return {};
  }
}

String eventsToJson(Map<String, List<EventItem>> events) {
  final map = <String, dynamic>{};
  events.forEach((k, v) {
    map[k] = v.map((e) => e.toJson()).toList();
  });
  return jsonEncode(map);
}
