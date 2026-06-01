import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_item.dart';
import '../core/constants/storage_keys.dart';
import '../storage/local_store.dart';

class EventsNotifier extends Notifier<Map<String, List<EventItem>>> {
  @override
  Map<String, List<EventItem>> build() {
    final raw = LocalStore.instance.getString(StorageKeys.events);
    return raw != null ? eventsFromJson(raw) : {};
  }

  Future<void> _save() async {
    await LocalStore.instance.setString(
      StorageKeys.events, eventsToJson(state));
  }

  List<EventItem> forDate(String dateKey) => state[dateKey] ?? [];

  Future<void> addEvent(String dateKey, EventItem item) async {
    final updated = Map<String, List<EventItem>>.from(state);
    updated[dateKey] = [...(updated[dateKey] ?? []), item];
    state = updated;
    await _save();
  }

  Future<void> updateEvent(String dateKey, int index, EventItem item) async {
    final updated = Map<String, List<EventItem>>.from(state);
    final list = List<EventItem>.from(updated[dateKey] ?? []);
    if (index >= 0 && index < list.length) {
      list[index] = item;
      updated[dateKey] = list;
      state = updated;
      await _save();
    }
  }

  Future<void> deleteEvent(String dateKey, int index) async {
    final updated = Map<String, List<EventItem>>.from(state);
    final list = List<EventItem>.from(updated[dateKey] ?? []);
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      if (list.isEmpty) {
        updated.remove(dateKey);
      } else {
        updated[dateKey] = list;
      }
      state = updated;
      await _save();
    }
  }

  /// Supabase pull 후 전체 교체
  Future<void> replaceAll(Map<String, List<EventItem>> next) async {
    state = next;
    await _save();
  }
}

final eventsProvider =
    NotifierProvider<EventsNotifier, Map<String, List<EventItem>>>(
        EventsNotifier.new);
