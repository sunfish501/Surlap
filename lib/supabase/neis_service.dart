// NEIS 교육정보 개방포털 API
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/storage_keys.dart';
import '../storage/local_store.dart';

const _neisKey = '21e74fc6a71d49d38adda2f572fdde85';
const _base = 'https://open.neis.go.kr/hub';

class NeisSchool {
  final String name;
  final String code;      // SD_SCHUL_CODE
  final String officeCode;// ATPT_OFCDC_SC_CODE
  final String kind;      // 학교 종류 (고등학교 etc.)
  final int grade;
  final int classNm;
  /// 학교 홈페이지 주소 (NEIS HMPG_ADRES). 파비콘 로고 추출에 사용.
  final String homepage;
  /// 학교 슬로건/교훈 — 공식 API에 없어 사용자가 직접 입력.
  final String slogan;
  /// 로고 이미지 URL 직접 지정(override). 비어 있으면 [logoUrl]이 파비콘으로 대체.
  final String logoOverride;

  const NeisSchool({
    required this.name, required this.code,
    required this.officeCode, required this.kind,
    required this.grade, required this.classNm,
    this.homepage = '', this.slogan = '', this.logoOverride = '',
  });

  /// 실제로 표시할 로고 URL. 직접 지정한 값이 있으면 그것을,
  /// 없으면 홈페이지 도메인의 파비콘을 쓴다. 둘 다 없으면 null.
  String? get logoUrl {
    if (logoOverride.trim().isNotEmpty) return logoOverride.trim();
    return faviconUrlFor(homepage);
  }

  NeisSchool copyWith({
    String? name, String? code, String? officeCode, String? kind,
    int? grade, int? classNm, String? homepage, String? slogan,
    String? logoOverride,
  }) => NeisSchool(
    name: name ?? this.name,
    code: code ?? this.code,
    officeCode: officeCode ?? this.officeCode,
    kind: kind ?? this.kind,
    grade: grade ?? this.grade,
    classNm: classNm ?? this.classNm,
    homepage: homepage ?? this.homepage,
    slogan: slogan ?? this.slogan,
    logoOverride: logoOverride ?? this.logoOverride,
  );

  Map<String, dynamic> toJson() => {
    'name': name, 'code': code, 'officeCode': officeCode,
    'kind': kind, 'grade': grade, 'classNm': classNm,
    if (homepage.isNotEmpty) 'homepage': homepage,
    if (slogan.isNotEmpty) 'slogan': slogan,
    if (logoOverride.isNotEmpty) 'logoOverride': logoOverride,
  };

  factory NeisSchool.fromJson(Map<String, dynamic> j) => NeisSchool(
    name: j['name'] as String,
    code: j['code'] as String,
    officeCode: j['officeCode'] as String? ?? '',
    kind: j['kind'] as String? ?? '',
    grade: j['grade'] as int? ?? 1,
    classNm: j['classNm'] as int? ?? 1,
    homepage: j['homepage'] as String? ?? '',
    slogan: j['slogan'] as String? ?? '',
    logoOverride: j['logoOverride'] as String? ?? '',
  );

  static NeisSchool? load() {
    final raw = LocalStore.instance.getString(StorageKeys.neisSchool);
    if (raw == null) { return null; }
    try {
      return NeisSchool.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) { return null; }
  }

  Future<void> save() async {
    await LocalStore.instance.setString(StorageKeys.neisSchool, jsonEncode(toJson()));
  }
}

/// 학사일정 표시 필터 — 다른 학년만 언급한 항목은 숨긴다.
/// 학년 표기가 없으면(=전체 일정) 항상 표시. 내 학년이 포함되면 표시.
bool academicVisibleForGrade(String title, int? grade) {
  if (grade == null || grade <= 0) return true;
  final mentioned = RegExp(r'([1-6])\s*학년')
      .allMatches(title)
      .map((m) => int.parse(m.group(1)!))
      .toSet();
  return mentioned.isEmpty || mentioned.contains(grade);
}

/// 홈페이지 주소에서 도메인을 뽑아 파비콘 URL을 만든다.
/// Google 파비콘 서비스(sz=128)를 쓰면 대부분의 학교 사이트에서 안정적으로
/// 작은 로고를 얻을 수 있다. 주소가 비었거나 파싱 실패면 null.
String? faviconUrlFor(String homepage) {
  final raw = homepage.trim();
  if (raw.isEmpty) return null;
  // 스킴이 없으면 붙여서 파싱(예: 'www.school.kr').
  final withScheme = raw.startsWith('http') ? raw : 'https://$raw';
  final host = Uri.tryParse(withScheme)?.host ?? '';
  if (host.isEmpty) return null;
  return 'https://www.google.com/s2/favicons?domain=$host&sz=128';
}

// 학교 검색
Future<List<Map<String, dynamic>>> searchSchools(String query) async {
  final uri = Uri.parse(
      '$_base/schoolInfo?KEY=$_neisKey&Type=json&pSize=10&SCHUL_NM=${Uri.encodeComponent(query)}');
  debugPrint('[NEIS] 1) 학교 검색 → "$query"');
  final res = await http.get(uri);
  if (res.statusCode != 200) {
    debugPrint('[NEIS] 학교 검색 HTTP ${res.statusCode}');
    return [];
  }
  try {
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    if (j['RESULT'] != null) {
      debugPrint('[NEIS] 학교 검색 결과 없음: ${(j['RESULT'] as Map?)?['MESSAGE']}');
      return [];
    }
    final rows = j['schoolInfo']?[1]['row'] as List? ?? [];
    debugPrint('[NEIS] 학교 ${rows.length}건 검색됨');
    return rows.cast<Map<String, dynamic>>();
  } catch (e) {
    debugPrint('[NEIS] 학교 검색 파싱 오류: $e');
    return [];
  }
}

// 시간표 조회
Future<Map<int, String>?> fetchTimetable(
    NeisSchool school, String date) async {
  if (school.officeCode.isEmpty) {
    debugPrint('[NEIS] 시간표: 교육청코드(ATPT_OFCDC_SC_CODE) 없음 — 학교 재연결 필요');
    return null;
  }
  final apiName = _timetableApiName(school.kind);
  if (apiName == null) {
    debugPrint('[NEIS] 시간표: 지원하지 않는 학교 종류 "${school.kind}"');
    return null;
  }

  final uri = Uri.parse(
      '$_base/$apiName?KEY=$_neisKey&Type=json&pSize=100'
      '&ATPT_OFCDC_SC_CODE=${school.officeCode}'
      '&SD_SCHUL_CODE=${school.code}'
      '&TI_FROM_YMD=$date&TI_TO_YMD=$date'
      '&GRADE=${school.grade}&CLASS_NM=${school.classNm}');
  debugPrint('[NEIS] 2) 시간표 호출 $apiName $date '
      '(${school.grade}학년 ${school.classNm}반)');

  final res = await http.get(uri);
  if (res.statusCode != 200) {
    debugPrint('[NEIS] 시간표 HTTP ${res.statusCode}');
    return null;
  }
  try {
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    if (j['RESULT'] != null) {
      debugPrint('[NEIS] 시간표 데이터 없음 ($date): ${(j['RESULT'] as Map?)?['MESSAGE']}');
      return {};
    }
    final rows = j[apiName]?[1]['row'] as List? ?? [];
    final result = <int, String>{};
    for (final row in rows.cast<Map<String, dynamic>>()) {
      final period = int.tryParse(row['PERIO']?.toString() ?? '') ?? 0;
      final subject = row['ITRT_CNTNT']?.toString() ?? '';
      if (period > 0 && subject.isNotEmpty) { result[period] = subject; }
    }
    debugPrint('[NEIS] 시간표 $date → ${result.length}교시 수신 $result');
    return result;
  } catch (e) {
    debugPrint('[NEIS] 시간표 파싱 오류 ($date): $e');
    return null;
  }
}

// 급식 조회
Future<String?> fetchLunch(NeisSchool school, String date) async {
  if (school.officeCode.isEmpty) { return null; }
  final uri = Uri.parse(
      '$_base/mealServiceDietInfo?KEY=$_neisKey&Type=json&pSize=10'
      '&ATPT_OFCDC_SC_CODE=${school.officeCode}'
      '&SD_SCHUL_CODE=${school.code}'
      '&MLSV_FROM_YMD=$date&MLSV_TO_YMD=$date');
  final res = await http.get(uri);
  if (res.statusCode != 200) {
    debugPrint('[NEIS] 급식 HTTP ${res.statusCode}');
    return null;
  }
  try {
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    if (j['RESULT'] != null) {
      debugPrint('[NEIS] 급식 데이터 없음 ($date): ${(j['RESULT'] as Map?)?['MESSAGE']}');
      return null;
    }
    final rows = j['mealServiceDietInfo']?[1]['row'] as List? ?? [];
    if (rows.isEmpty) { return null; }
    final raw = rows[0]['DDISH_NM']?.toString() ?? '';
    // <br/> 구분자를 개행으로, 칼로리 태그 제거
    final lunch =
        raw.replaceAll('<br/>', '\n').replaceAll(RegExp(r'\s*\(.*?\)'), '').trim();
    debugPrint('[NEIS] 급식 $date → ${lunch.split('\n').length}개 메뉴');
    return lunch;
  } catch (e) {
    debugPrint('[NEIS] 급식 파싱 오류 ($date): $e');
    return null;
  }
}

// 학사일정 한 건.
class AcademicEvent {
  final String dateKey; // 'YYYY-MM-DD'
  final String name;    // EVENT_NM
  final String content; // EVENT_CNTNT
  const AcademicEvent({
    required this.dateKey,
    required this.name,
    required this.content,
  });
}

// 학사일정 조회 (SchoolSchedule) — 시간표/급식과 동일 패턴, 같은 NEIS 설정 재사용.
// from/to: 'YYYYMMDD'. 학교 미연결(officeCode 비어있음)이면 빈 결과.
Future<List<AcademicEvent>> fetchSchoolSchedule(
    NeisSchool school, String from, String to) async {
  if (school.officeCode.isEmpty) {
    debugPrint('[NEIS] 학사일정: 교육청코드 없음 — 학교 재연결 필요');
    return [];
  }
  final uri = Uri.parse(
      '$_base/SchoolSchedule?KEY=$_neisKey&Type=json&pSize=1000'
      '&ATPT_OFCDC_SC_CODE=${school.officeCode}'
      '&SD_SCHUL_CODE=${school.code}'
      '&AA_FROM_YMD=$from&AA_TO_YMD=$to');
  debugPrint('[NEIS] 학사일정 호출 $from~$to');

  final res = await http.get(uri);
  if (res.statusCode != 200) {
    debugPrint('[NEIS] 학사일정 HTTP ${res.statusCode}');
    return [];
  }
  try {
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    if (j['RESULT'] != null) {
      debugPrint('[NEIS] 학사일정 데이터 없음: ${(j['RESULT'] as Map?)?['MESSAGE']}');
      return [];
    }
    final rows = j['SchoolSchedule']?[1]['row'] as List? ?? [];
    final result = <AcademicEvent>[];
    for (final row in rows.cast<Map<String, dynamic>>()) {
      final ymd = (row['AA_YMD']?.toString() ?? '').trim(); // YYYYMMDD
      if (ymd.length != 8) continue;
      final name = (row['EVENT_NM']?.toString() ?? '').trim();
      final content = (row['EVENT_CNTNT']?.toString() ?? '').trim();
      final label = name.isNotEmpty ? name : content;
      if (label.isEmpty) continue;
      final dateKey =
          '${ymd.substring(0, 4)}-${ymd.substring(4, 6)}-${ymd.substring(6, 8)}';
      result.add(AcademicEvent(
          dateKey: dateKey, name: label, content: content));
    }
    debugPrint('[NEIS] 학사일정 ${result.length}건 수신');
    return result;
  } catch (e) {
    debugPrint('[NEIS] 학사일정 파싱 오류: $e');
    return [];
  }
}

String? _timetableApiName(String kind) {
  if (kind.contains('고등')) { return 'hisTimetable'; }
  if (kind.contains('중학')) { return 'misTimetable'; }
  if (kind.contains('초등')) { return 'elsTimetable'; }
  return null;
}
