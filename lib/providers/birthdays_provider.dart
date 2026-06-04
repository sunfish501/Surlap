import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/storage_keys.dart';
import '../storage/local_store.dart';

/// 생일 가상 카테고리(테마) id — 카테고리 필터에서 따로 켜고/끌 수 있게.
const birthdayThemeId = '__birthday__';

class Birthday {
  final String id;
  final String name;
  final int month;
  final int day;
  final int? year; // 선택 — 알면 나이 표시에 사용

  const Birthday({
    required this.id,
    required this.name,
    required this.month,
    required this.day,
    this.year,
  });

  factory Birthday.create({
    required String name,
    required int month,
    required int day,
    int? year,
  }) =>
      Birthday(
          id: const Uuid().v4(),
          name: name,
          month: month,
          day: day,
          year: year);

  Birthday copyWith({String? name, int? month, int? day, int? year}) =>
      Birthday(
        id: id,
        name: name ?? this.name,
        month: month ?? this.month,
        day: day ?? this.day,
        year: year ?? this.year,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'month': month,
        'day': day,
        if (year != null) 'year': year,
      };

  factory Birthday.fromJson(Map<String, dynamic> j) => Birthday(
        id: (j['id'] as String?)?.isNotEmpty == true
            ? j['id'] as String
            : const Uuid().v4(),
        name: j['name'] as String? ?? '',
        month: (j['month'] as num?)?.toInt() ?? 1,
        day: (j['day'] as num?)?.toInt() ?? 1,
        year: (j['year'] as num?)?.toInt(),
      );

  /// 알림용 안정적 양수 id.
  int get notifyId => id.hashCode & 0x7fffffff;

  /// 다음(오늘 포함) 생일까지 남은 일수. 오늘이면 0.
  int daysUntilNext([DateTime? from]) {
    final now = from ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var next = DateTime(now.year, month, _clampDay(now.year));
    if (next.isBefore(today)) {
      next = DateTime(now.year + 1, month, _clampDay(now.year + 1));
    }
    return next.difference(today).inDays;
  }

  /// 윤년 등으로 2/29가 없는 해 보정.
  int _clampDay(int y) {
    final last = DateTime(y, month + 1, 0).day;
    return day > last ? last : day;
  }
}

class BirthdaysNotifier extends Notifier<List<Birthday>> {
  @override
  List<Birthday> build() {
    final raw = LocalStore.instance.getString(StorageKeys.birthdays);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .whereType<Map<String, dynamic>>()
          .map(Birthday.fromJson)
          .toList()
        ..sort(_byUpcoming);
    } catch (_) {
      return [];
    }
  }

  static int _byUpcoming(Birthday a, Birthday b) {
    final d = a.daysUntilNext().compareTo(b.daysUntilNext());
    return d != 0 ? d : a.name.compareTo(b.name);
  }

  void _persist() {
    LocalStore.instance.setString(
      StorageKeys.birthdays,
      jsonEncode(state.map((b) => b.toJson()).toList()),
    );
  }

  void add(Birthday b) {
    state = [...state, b]..sort(_byUpcoming);
    _persist();
  }

  void update(Birthday b) {
    state = [for (final x in state) x.id == b.id ? b : x]..sort(_byUpcoming);
    _persist();
  }

  void removeById(String id) {
    state = state.where((b) => b.id != id).toList();
    _persist();
  }

  /// 일괄 추가(연락처/vcf) — 같은 이름은 갱신, 새 이름은 추가.
  void addAll(List<Birthday> incoming) {
    final byName = <String, Birthday>{for (final b in state) b.name: b};
    for (final b in incoming) {
      if (b.name.isEmpty) continue;
      final existing = byName[b.name];
      byName[b.name] = existing == null
          ? b
          : existing.copyWith(month: b.month, day: b.day, year: b.year);
    }
    state = byName.values.toList()..sort(_byUpcoming);
    _persist();
  }

  void clear() {
    state = [];
    _persist();
  }
}

final birthdaysProvider =
    NotifierProvider<BirthdaysNotifier, List<Birthday>>(BirthdaysNotifier.new);
