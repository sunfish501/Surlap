import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/storage_keys.dart';
import '../storage/local_store.dart';
import '../supabase/neis_service.dart';

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
      return data.map((k, v) =>
          MapEntry(k, (v as List).map((e) => e.toString()).toList()));
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
      final events =
          await fetchSchoolSchedule(school, '${y - 1}0101', '${y + 1}1231');
      final map = <String, List<String>>{};
      for (final e in events) {
        map.putIfAbsent(e.dateKey, () => []).add(e.name);
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
        AcademicScheduleNotifier.new);
