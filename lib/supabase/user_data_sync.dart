// userDataSync.js 대응 — user_data KV 테이블에 계정 데이터 키를 push/pull.
import '../core/constants/storage_keys.dart';
import '../storage/local_store.dart';
import 'supabase_client.dart';

class UserDataSync {
  static Future<void> pushKey(String key) async {
    final client = sb;
    if (client == null) return;
    final uid = client.auth.currentUser?.id;
    if (uid == null) return;
    if (!StorageKeys.userDataKeys.contains(key)) return;

    final value = LocalStore.instance.getString(key); // 현재 스코프 값
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
    for (final key in StorageKeys.userDataKeys) {
      await pushKey(key);
    }
  }

  /// 클라우드 user_data → 현재 스코프 로컬 캐시. 성공하면 true.
  /// pull 실패 시 로컬을 건드리지 않는다(증발 방지). 클라우드에 없는 키는
  /// 그 스코프에서 비운다(클라우드가 원본).
  static Future<bool> pullAll() async {
    final client = sb;
    if (client == null) return false;
    final uid = client.auth.currentUser?.id;
    if (uid == null) return false;

    try {
      final data = await client
          .from('user_data')
          .select('key, value')
          .eq('user_id', uid)
          .inFilter('key', StorageKeys.userDataKeys.toList());

      final cloud = <String, String>{};
      for (final row in data as List) {
        final key = row['key'] as String?;
        final val = row['value'];
        if (key != null && val != null) cloud[key] = val.toString();
      }
      // 성공적으로 받은 뒤에만 로컬 교체(quiet — push 에코 방지)
      for (final key in StorageKeys.userDataKeys) {
        if (cloud.containsKey(key)) {
          await LocalStore.instance.setStringQuiet(key, cloud[key]!);
        } else {
          await LocalStore.instance.remove(key);
        }
      }
      return true;
    } catch (_) {
      return false; // 로컬 유지
    }
  }
}
