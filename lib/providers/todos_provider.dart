import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/todo_item.dart';
import '../core/constants/storage_keys.dart';
import '../storage/local_store.dart';

/// 할 일(Todo) 목록 — 일정과 분리된 별도 시스템(로컬 저장).
class TodosNotifier extends Notifier<List<TodoItem>> {
  @override
  List<TodoItem> build() {
    final raw = LocalStore.instance.getString(StorageKeys.todos);
    return raw != null ? todosFromJson(raw) : [];
  }

  Future<void> _save() async {
    await LocalStore.instance.setString(StorageKeys.todos, todosToJson(state));
  }

  /// 특정 날짜의 할 일 (우선순위 오름차순, 우선순위 없음은 뒤로).
  List<TodoItem> forDate(String dateKey) {
    final list = state.where((t) => t.dateKey == dateKey).toList();
    list.sort(_byPriority);
    return list;
  }

  static int _byPriority(TodoItem a, TodoItem b) {
    int rank(TodoItem t) => t.hasPriority ? t.priority : 99;
    final r = rank(a).compareTo(rank(b));
    if (r != 0) return r;
    return (a.createdAt ?? '').compareTo(b.createdAt ?? '');
  }

  Future<void> add(TodoItem item) async {
    state = [...state, item];
    await _save();
  }

  Future<void> update(String id, TodoItem item) async {
    state = [for (final t in state) if (t.id == id) item else t];
    await _save();
  }

  // 한 번 누를 때마다 없음 → 진행중 → 완료 → 없음 순으로 순환.
  Future<void> toggleDone(String id) async {
    state = [
      for (final t in state)
        if (t.id == id) t.copyWith(status: (t.status + 1) % 3) else t
    ];
    await _save();
  }

  Future<void> remove(String id) async {
    state = state.where((t) => t.id != id).toList();
    await _save();
  }

  /// 계정 전환/클라우드 pull 후 전체 교체.
  Future<void> replaceAll(List<TodoItem> next) async {
    state = next;
    await _save();
  }
}

final todosProvider =
    NotifierProvider<TodosNotifier, List<TodoItem>>(TodosNotifier.new);
