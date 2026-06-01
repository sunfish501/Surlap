import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/calendar_theme.dart';
import '../core/constants/storage_keys.dart';
import '../storage/local_store.dart';

class ThemesNotifier extends Notifier<List<CalendarTheme>> {
  @override
  List<CalendarTheme> build() {
    final raw = LocalStore.instance.getString(StorageKeys.themes);
    if (raw != null) {
      final list = CalendarTheme.listFromJson(raw);
      if (list.isNotEmpty) return list;
    }
    // 기본값: 공휴일 테마
    const defaults = [CalendarTheme(id: 'holidays', name: '공휴일', color: '#d33333')];
    _persist(defaults);
    return defaults;
  }

  void _persist(List<CalendarTheme> themes) {
    LocalStore.instance.setString(StorageKeys.themes, CalendarTheme.listToJson(themes));
  }

  Future<void> add(CalendarTheme theme) async {
    state = [...state, theme];
    _persist(state);
  }

  Future<void> update(CalendarTheme theme) async {
    state = [for (final t in state) t.id == theme.id ? theme : t];
    _persist(state);
  }

  Future<void> delete(String id) async {
    state = state.where((t) => t.id != id).toList();
    _persist(state);
  }

  CalendarTheme? byId(String id) {
    try {
      return state.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}

final themesProvider =
    NotifierProvider<ThemesNotifier, List<CalendarTheme>>(ThemesNotifier.new);
