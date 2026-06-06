import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/storage_keys.dart';
import '../models/template_range.dart';
import '../storage/local_store.dart';

/// 기록 템플릿 적용 기간 목록. (정의=RecordTemplate, 기록=widgetValues 와 분리)
class TemplateRangesNotifier extends Notifier<List<TemplateRange>> {
  @override
  List<TemplateRange> build() {
    final raw = LocalStore.instance.getString(StorageKeys.recordTemplateRanges);
    return raw != null ? TemplateRange.listFromJson(raw) : [];
  }

  Future<void> add(TemplateRange r) async {
    state = [...state, r];
    await _save();
  }

  Future<void> update(TemplateRange r) async {
    state = [for (final e in state) e.id == r.id ? r : e];
    await _save();
  }

  Future<void> remove(String id) async {
    state = state.where((e) => e.id != id).toList();
    await _save();
  }

  /// 새 적용 기간 추가(고유 id 자동 생성).
  Future<void> apply(String templateId, String start, String end) async {
    final id = 'tr-${DateTime.now().microsecondsSinceEpoch}';
    await add(TemplateRange(
        id: id, templateId: templateId, start: start, end: end));
  }

  Future<void> _save() async {
    await LocalStore.instance.setString(
        StorageKeys.recordTemplateRanges, TemplateRange.listToJson(state));
  }
}

final templateRangesProvider =
    NotifierProvider<TemplateRangesNotifier, List<TemplateRange>>(
        TemplateRangesNotifier.new);
