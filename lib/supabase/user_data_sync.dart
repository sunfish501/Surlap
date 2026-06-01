// userDataSync.js 대응 — user_data KV 테이블에 localStorage 키를 push/pull.
import '../core/constants/storage_keys.dart';
import '../storage/local_store.dart';
import 'supabase_client.dart';

const _trackedKeys = [
  StorageKeys.themes,
  StorageKeys.colorPreset,
  StorageKeys.neisSchool,
  StorageKeys.memos,
  StorageKeys.starred,
  StorageKeys.circles,
  StorageKeys.notifyEnabled,
  StorageKeys.continuousView,
  StorageKeys.themeFilter,
  StorageKeys.cellDesign,
  StorageKeys.motto,
  StorageKeys.mottoIcon,
  StorageKeys.dayTemplates,
  StorageKeys.dayWidgetValues,
  StorageKeys.timetableTemplate,
  StorageKeys.timetableOverrides,
  StorageKeys.birthdays,
];

class UserDataSync {
  static Future<void> pushKey(String key) async {
    final client = sb;
    if (client == null) { return; }
    final uid = client.auth.currentUser?.id;
    if (uid == null) { return; }
    if (!_trackedKeys.contains(key)) { return; }

    final value = LocalStore.instance.getString(key);
    try {
      if (value == null) {
        await client.from('user_data')
            .delete().eq('user_id', uid).eq('key', key);
      } else {
        await client.from('user_data').upsert(
          {'user_id': uid, 'key': key, 'value': value},
          onConflict: 'user_id,key',
        );
      }
    } catch (_) {}
  }

  static Future<void> pushAll() async {
    for (final key in _trackedKeys) {
      await pushKey(key);
    }
  }

  static Future<void> pullAll() async {
    final client = sb;
    if (client == null) { return; }
    final uid = client.auth.currentUser?.id;
    if (uid == null) { return; }

    try {
      final data = await client
          .from('user_data')
          .select('key, value')
          .eq('user_id', uid)
          .inFilter('key', _trackedKeys);

      for (final row in data as List) {
        final key = row['key'] as String;
        final val = row['value'];
        if (val != null) {
          await LocalStore.instance.setString(key, val.toString());
        }
      }
    } catch (_) {}
  }
}
