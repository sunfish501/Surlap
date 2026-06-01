// 별표(starred), 메모(memos), 동그라미(circles) — 날짜 셀 부가 기능.
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/storage_keys.dart';
import '../storage/local_store.dart';

// ── 별표 ──────────────────────────────────────────────────
class StarredNotifier extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() {
    final raw = LocalStore.instance.getString(StorageKeys.starred);
    if (raw == null) { return {}; }
    try {
      return (jsonDecode(raw) as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) { return {}; }
  }

  Future<void> toggle(String dateKey) async {
    final next = Map<String, int>.from(state);
    final cur = next[dateKey] ?? 0;
    if (cur >= 3) {
      next.remove(dateKey);
    } else {
      next[dateKey] = cur + 1;
    }
    state = next;
    await LocalStore.instance.setString(StorageKeys.starred, jsonEncode(next));
  }
}

final starredProvider =
    NotifierProvider<StarredNotifier, Map<String, int>>(StarredNotifier.new);

// ── 날짜 메모 ─────────────────────────────────────────────
class MemosNotifier extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() {
    final raw = LocalStore.instance.getString(StorageKeys.memos);
    if (raw == null) { return {}; }
    try {
      return (jsonDecode(raw) as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, v.toString()));
    } catch (_) { return {}; }
  }

  Future<void> set(String dateKey, String text) async {
    final next = Map<String, String>.from(state);
    if (text.isEmpty) {
      next.remove(dateKey);
    } else {
      next[dateKey] = text;
    }
    state = next;
    await LocalStore.instance.setString(StorageKeys.memos, jsonEncode(next));
  }
}

final memosProvider =
    NotifierProvider<MemosNotifier, Map<String, String>>(MemosNotifier.new);

// ── 동그라미 ─────────────────────────────────────────────
class CirclesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final raw = LocalStore.instance.getString(StorageKeys.circles);
    if (raw == null) { return {}; }
    try {
      return (jsonDecode(raw) as Map<String, dynamic>).keys.toSet();
    } catch (_) { return {}; }
  }

  Future<void> toggle(String dateKey) async {
    final next = Set<String>.from(state);
    if (next.contains(dateKey)) {
      next.remove(dateKey);
    } else {
      next.add(dateKey);
    }
    state = next;
    final map = {for (final k in next) k: true};
    await LocalStore.instance.setString(StorageKeys.circles, jsonEncode(map));
  }
}

final circlesProvider =
    NotifierProvider<CirclesNotifier, Set<String>>(CirclesNotifier.new);
