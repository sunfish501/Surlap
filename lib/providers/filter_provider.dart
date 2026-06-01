import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/storage_keys.dart';
import '../storage/local_store.dart';

class FilterNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final raw = LocalStore.instance.getString(StorageKeys.themeFilter);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        return list.map((e) => e.toString()).toSet();
      } catch (_) {}
    }
    return {};
  }

  Future<void> toggle(String themeId) async {
    final next = Set<String>.from(state);
    if (next.contains(themeId)) {
      next.remove(themeId);
    } else {
      next.add(themeId);
    }
    state = next;
    await _save();
  }

  Future<void> setAll(List<String> ids) async {
    state = ids.toSet();
    await _save();
  }

  Future<void> clear() async {
    state = {};
    await _save();
  }

  bool isHidden(String themeId) => state.contains(themeId);

  Future<void> _save() async {
    await LocalStore.instance.setString(
        StorageKeys.themeFilter, jsonEncode(state.toList()));
  }
}

final filterProvider =
    NotifierProvider<FilterNotifier, Set<String>>(FilterNotifier.new);
