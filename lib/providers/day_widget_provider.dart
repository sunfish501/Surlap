import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/storage_keys.dart';
import '../models/day_template.dart';
import '../storage/local_store.dart';

// 위젯 입력값: { "YYYY-MM-DD": { tplId: { fieldId: dynamic } } }
class WidgetValuesNotifier extends Notifier<Map<String, Map<String, Map<String, dynamic>>>> {
  @override
  Map<String, Map<String, Map<String, dynamic>>> build() {
    final raw = LocalStore.instance.getString(StorageKeys.dayWidgetValues);
    if (raw == null) { return {}; }
    try {
      final outer = jsonDecode(raw) as Map<String, dynamic>;
      return outer.map((date, tpls) {
        final tplMap = (tpls as Map<String, dynamic>).map((tplId, fields) {
          final fieldMap = (fields as Map<String, dynamic>).cast<String, dynamic>();
          return MapEntry(tplId, fieldMap);
        });
        return MapEntry(date, tplMap);
      });
    } catch (_) { return {}; }
  }

  dynamic getValue(String dateKey, String tplId, String fieldId) =>
      state[dateKey]?[tplId]?[fieldId];

  Future<void> setValue(String dateKey, String tplId, String fieldId, dynamic value) async {
    final next = Map<String, Map<String, Map<String, dynamic>>>.from(state);
    next[dateKey] ??= {};
    next[dateKey]![tplId] ??= {};
    if (value == null) {
      next[dateKey]![tplId]!.remove(fieldId);
    } else {
      next[dateKey]![tplId]![fieldId] = value;
    }
    state = next;
    await _save();
  }

  Future<void> _save() async {
    await LocalStore.instance.setString(
      StorageKeys.dayWidgetValues, jsonEncode(state));
  }
}

final widgetValuesProvider =
    NotifierProvider<WidgetValuesNotifier, Map<String, Map<String, Map<String, dynamic>>>>(
        WidgetValuesNotifier.new);

// 템플릿 목록
class DayTemplatesNotifier extends Notifier<List<DayTemplate>> {
  @override
  List<DayTemplate> build() {
    final raw = LocalStore.instance.getString(StorageKeys.dayTemplates);
    return raw != null ? DayTemplate.listFromJson(raw) : [];
  }

  Future<void> add(DayTemplate tpl) async {
    state = [...state, tpl];
    await _save();
  }

  Future<void> update(DayTemplate tpl) async {
    state = [for (final t in state) t.id == tpl.id ? tpl : t];
    await _save();
  }

  Future<void> delete(String id) async {
    state = state.where((t) => t.id != id).toList();
    await _save();
  }

  List<DayTemplate> applicableFor(String dateKey) =>
      state.where((t) => t.enabled && t.scope.appliesTo(dateKey)).toList();

  Future<void> _save() async {
    await LocalStore.instance.setString(
        StorageKeys.dayTemplates, DayTemplate.listToJson(state));
  }
}

final dayTemplatesProvider =
    NotifierProvider<DayTemplatesNotifier, List<DayTemplate>>(DayTemplatesNotifier.new);
