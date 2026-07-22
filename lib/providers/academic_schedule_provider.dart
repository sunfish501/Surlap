import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/storage_keys.dart';
import '../storage/local_store.dart';
import '../supabase/neis_service.dart';

/// 학사일정 가상 카테고리(테마) id — 카테고리 필터에서 따로 켜고/끌 수 있게.
/// 실제 사용자 테마가 아니라 표시·필터 전용 sentinel.
const academicThemeId = '__academic__';

/// NEIS의 행정 용어를 학생이 바로 이해할 수 있는 일정 이름으로 바꾼다.
String friendlyAcademicScheduleName(String raw) {
  var name = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (name.isEmpty) return name;

  final semester = RegExp(r'([12])\s*학기').firstMatch(name)?.group(1);
  if (name.contains('1차 지필') || name.contains('중간 지필')) {
    return semester == null ? '중간고사' : '$semester학기 중간고사';
  }
  if (name.contains('2차 지필') || name.contains('기말 지필')) {
    return semester == null ? '기말고사' : '$semester학기 기말고사';
  }
  if (name.contains('전국연합학력평가')) {
    return name.replaceAll('전국연합학력평가', '전국연합 모의고사');
  }
  if (name.contains('대학수학능력시험')) {
    return name.replaceAll('대학수학능력시험', '수능');
  }

  const replacements = <String, String>{
    '여름방학식': '여름방학 시작',
    '여름휴가식': '여름방학 시작',
    '여름휴업': '여름방학',
    '겨울방학식': '겨울방학 시작',
    '겨울휴가식': '겨울방학 시작',
    '겨울휴업': '겨울방학',
    '학년말방학': '봄방학',
    '학년말휴업': '봄방학',
    '개학식': '개학',
    '종업식': '한 학년 마무리',
    '수료식': '이번 학년 수료',
    '학교교육과정설명회': '학교생활 설명회',
    '교육과정설명회': '학교생활 설명회',
  };
  for (final entry in replacements.entries) {
    if (name.contains(entry.key)) {
      name = name.replaceAll(entry.key, entry.value);
    }
  }

  if (RegExp(r'(재량|자율|임시|학교장).*휴업').hasMatch(name) ||
      name == '휴업일' ||
      name == '휴업') {
    return '학교 쉬는 날';
  }
  name = name.replaceAll(RegExp(r'\s*\((?:휴업일?|학교휴업)\)\s*'), ' · 학교 쉬는 날');
  return name.trim();
}

/// NEIS 학사일정 — 날짜키(YYYY-MM-DD) → 행사명 목록.
/// 작년~내년 범위를 1회 받아 로컬 캐시(연 단위). 학교 미연결이면 비어 있음.
class AcademicScheduleNotifier extends Notifier<Map<String, List<String>>> {
  bool _fetching = false;

  @override
  Map<String, List<String>> build() {
    final loaded = _loadLocal();
    if (loaded.isEmpty && NeisSchool.load() != null) {
      Future.microtask(_fetchIfNeeded);
    }
    return loaded;
  }

  int get _baseYear => DateTime.now().year;

  Map<String, List<String>> _loadLocal() {
    final raw = LocalStore.instance.getString(StorageKeys.neisAcademic);
    if (raw == null) return {};
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      if (j['baseYear'] != _baseYear) return {}; // 해가 바뀌면 재요청
      final data = (j['data'] as Map<String, dynamic>? ?? {});
      return data.map(
        (k, v) => MapEntry(
          k,
          (v as List)
              .map((e) => friendlyAcademicScheduleName(e.toString()))
              .where((name) => name.isNotEmpty)
              .toSet()
              .toList(),
        ),
      );
    } catch (_) {
      return {};
    }
  }

  void _saveLocal(Map<String, List<String>> data) {
    LocalStore.instance.setString(
      StorageKeys.neisAcademic,
      jsonEncode({'baseYear': _baseYear, 'data': data}),
    );
  }

  Future<void> _fetchIfNeeded() async {
    if (_fetching) return;
    final school = NeisSchool.load();
    if (school == null) return;
    if (state.isNotEmpty) return;
    _fetching = true;
    try {
      // 작년 1/1 ~ 내년 12/31 (학년도 전체 커버).
      final y = _baseYear;
      final events = await fetchSchoolSchedule(
        school,
        '${y - 1}0101',
        '${y + 1}1231',
      );
      final map = <String, List<String>>{};
      for (final e in events) {
        final friendlyName = friendlyAcademicScheduleName(e.name);
        if (friendlyName.isNotEmpty) {
          final names = map.putIfAbsent(e.dateKey, () => []);
          if (!names.contains(friendlyName)) names.add(friendlyName);
        }
      }
      if (map.isNotEmpty) {
        state = map;
        _saveLocal(map);
      }
    } catch (e) {
      debugPrint('[Academic] fetch error: $e');
    }
    _fetching = false;
  }

  /// 학교 재연결 등으로 강제 새로고침.
  Future<void> refresh() async {
    state = {};
    await _fetchIfNeeded();
  }
}

final academicScheduleProvider =
    NotifierProvider<AcademicScheduleNotifier, Map<String, List<String>>>(
      AcademicScheduleNotifier.new,
    );

/// 다가오는 가장 가까운 주요 학사일정. 키워드 매칭으로 중요 행사만.
class AcademicHighlight {
  final String dateKey;
  final String name;
  final int daysAway; // 0=오늘
  const AcademicHighlight(this.dateKey, this.name, this.daysAway);
}

final nextAcademicHighlightProvider = Provider<AcademicHighlight?>((ref) {
  final m = ref.watch(academicScheduleProvider);
  if (m.isEmpty) return null;
  const keywords = ['시험', '방학', '개학', '졸업', '입학', '수능', '체육대회', '축제'];
  final today = DateTime.now();
  final todayKey =
      '${today.year.toString().padLeft(4, '0')}-'
      '${today.month.toString().padLeft(2, '0')}-'
      '${today.day.toString().padLeft(2, '0')}';
  AcademicHighlight? best;
  m.forEach((dateKey, names) {
    if (dateKey.compareTo(todayKey) < 0) return;
    DateTime d;
    try {
      d = DateTime.parse(dateKey);
    } catch (_) {
      return;
    }
    final days = d
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
    for (final n in names) {
      if (keywords.any((k) => n.contains(k))) {
        if (best == null || days < best!.daysAway) {
          best = AcademicHighlight(dateKey, n, days);
        }
        break;
      }
    }
  });
  return best;
});
