// NEIS 교육정보 개방포털 API
import 'dart:convert';
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

  const NeisSchool({
    required this.name, required this.code,
    required this.officeCode, required this.kind,
    required this.grade, required this.classNm,
  });

  Map<String, dynamic> toJson() => {
    'name': name, 'code': code, 'officeCode': officeCode,
    'kind': kind, 'grade': grade, 'classNm': classNm,
  };

  factory NeisSchool.fromJson(Map<String, dynamic> j) => NeisSchool(
    name: j['name'] as String,
    code: j['code'] as String,
    officeCode: j['officeCode'] as String? ?? '',
    kind: j['kind'] as String? ?? '',
    grade: j['grade'] as int? ?? 1,
    classNm: j['classNm'] as int? ?? 1,
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

// 학교 검색
Future<List<Map<String, dynamic>>> searchSchools(String query) async {
  final uri = Uri.parse(
      '$_base/schoolInfo?KEY=$_neisKey&Type=json&pSize=10&SCHUL_NM=${Uri.encodeComponent(query)}');
  final res = await http.get(uri);
  if (res.statusCode != 200) { return []; }
  try {
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final rows = j['schoolInfo']?[1]['row'] as List? ?? [];
    return rows.cast<Map<String, dynamic>>();
  } catch (_) { return []; }
}

// 시간표 조회
Future<Map<int, String>?> fetchTimetable(
    NeisSchool school, String date) async {
  if (school.officeCode.isEmpty) { return null; }
  final apiName = _timetableApiName(school.kind);
  if (apiName == null) { return null; }

  final uri = Uri.parse(
      '$_base/$apiName?KEY=$_neisKey&Type=json&pSize=100'
      '&ATPT_OFCDC_SC_CODE=${school.officeCode}'
      '&SD_SCHUL_CODE=${school.code}'
      '&TI_FROM_YMD=$date&TI_TO_YMD=$date'
      '&GRADE=${school.grade}&CLASS_NM=${school.classNm}');

  final res = await http.get(uri);
  if (res.statusCode != 200) { return null; }
  try {
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final rows = j[apiName]?[1]['row'] as List? ?? [];
    final result = <int, String>{};
    for (final row in rows.cast<Map<String, dynamic>>()) {
      final period = int.tryParse(row['PERIO']?.toString() ?? '') ?? 0;
      final subject = row['ITRT_CNTNT']?.toString() ?? '';
      if (period > 0 && subject.isNotEmpty) { result[period] = subject; }
    }
    return result;
  } catch (_) { return null; }
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
  if (res.statusCode != 200) { return null; }
  try {
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final rows = j['mealServiceDietInfo']?[1]['row'] as List? ?? [];
    if (rows.isEmpty) { return null; }
    final raw = rows[0]['DDISH_NM']?.toString() ?? '';
    // <br/> 구분자를 개행으로, 칼로리 태그 제거
    return raw.replaceAll('<br/>', '\n').replaceAll(RegExp(r'\s*\(.*?\)'), '').trim();
  } catch (_) { return null; }
}

String? _timetableApiName(String kind) {
  if (kind.contains('고등')) { return 'hisTimetable'; }
  if (kind.contains('중학')) { return 'misTimetable'; }
  if (kind.contains('초등')) { return 'elsTimetable'; }
  return null;
}
