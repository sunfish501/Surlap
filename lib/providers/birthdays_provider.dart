import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/storage_keys.dart';
import '../models/event_item.dart';
import '../storage/local_store.dart';

class Birthday {
  final String name;
  final int month;
  final int day;

  const Birthday({required this.name, required this.month, required this.day});

  Map<String, dynamic> toJson() => {'name': name, 'month': month, 'day': day};

  factory Birthday.fromJson(Map<String, dynamic> j) => Birthday(
    name: j['name'] as String? ?? '',
    month: j['month'] as int? ?? 1,
    day: j['day'] as int? ?? 1,
  );
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
          .toList();
    } catch (_) {
      return [];
    }
  }

  void _persist() {
    LocalStore.instance.setString(
      StorageKeys.birthdays,
      jsonEncode(state.map((b) => b.toJson()).toList()),
    );
  }

  void addAll(List<Birthday> newBirthdays) {
    // Merge: replace if same name, add if new
    final map = <String, Birthday>{
      for (final b in state) b.name: b,
    };
    for (final b in newBirthdays) {
      if (b.name.isNotEmpty) map[b.name] = b;
    }
    state = map.values.toList()
      ..sort((a, b) {
        final mc = a.month.compareTo(b.month);
        return mc != 0 ? mc : a.day.compareTo(b.day);
      });
    _persist();
  }

  void remove(String name) {
    state = state.where((b) => b.name != name).toList();
    _persist();
  }

  void clear() {
    state = [];
    _persist();
  }

  // dateKey별 생일 이벤트 (given year에서의 날짜)
  Map<String, EventItem> eventsForYear(int year) {
    final result = <String, EventItem>{};
    for (final b in state) {
      if (b.month < 1 || b.month > 12 || b.day < 1 || b.day > 31) continue;
      final key =
          '$year-${b.month.toString().padLeft(2, '0')}-${b.day.toString().padLeft(2, '0')}';
      result[key] = EventItem(t: '🎂 ${b.name}');
    }
    return result;
  }
}

final birthdaysProvider =
    NotifierProvider<BirthdaysNotifier, List<Birthday>>(BirthdaysNotifier.new);
