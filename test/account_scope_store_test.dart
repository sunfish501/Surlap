import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:surlap/core/constants/storage_keys.dart';
import 'package:surlap/storage/local_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('legacy migration → guest scope, then per-account isolation', () async {
    // 기존(프리픽스 없는) 계정 데이터 + 기기 설정 키
    SharedPreferences.setMockInitialValues({
      StorageKeys.events: '{"2026-06-01":[{"t":"old"}]}',
      StorageKeys.colorPreset: 'forest', // 기기 설정(스코프 제외)
    });
    await LocalStore.init();
    final s = LocalStore.instance;
    s.setScope('guest');

    await s.migrateLegacyToGuestOnce();

    // 마이그레이션: 레거시 계정 데이터가 guest 스코프로 보존되고 백업 생성
    expect(s.getString(StorageKeys.events), contains('old'),
        reason: 'guest 스코프에서 기존 데이터가 읽혀야 함');

    // A 계정: 데이터 생성
    s.setScope('user_A');
    await s.setString(StorageKeys.events, '{"2026-06-02":[{"t":"A-event"}]}');
    await s.setString(StorageKeys.themes, '[{"id":"a","name":"A","color":"#111"}]');
    expect(s.getString(StorageKeys.events), contains('A-event'));

    // B 계정으로 전환: A 데이터가 보이면 안 됨(빈 상태)
    s.setScope('user_B');
    expect(s.getString(StorageKeys.events), isNull,
        reason: 'B는 A의 데이터를 볼 수 없어야 함');
    await s.setString(StorageKeys.events, '{"2026-06-03":[{"t":"B-event"}]}');
    expect(s.getString(StorageKeys.events), contains('B-event'));

    // 다시 A: 데이터 복구
    s.setScope('user_A');
    expect(s.getString(StorageKeys.events), contains('A-event'),
        reason: 'A로 돌아오면 A 데이터가 복구돼야 함');

    // 게스트: 마이그레이션된 원본만(계정 데이터와 안 섞임)
    s.setScope('guest');
    expect(s.getString(StorageKeys.events), contains('old'));
    expect(s.getString(StorageKeys.events), isNot(contains('A-event')));

    // 기기 설정(colorPreset)은 스코프와 무관하게 공유
    for (final scope in ['guest', 'user_A', 'user_B']) {
      s.setScope(scope);
      expect(s.getString(StorageKeys.colorPreset), 'forest',
          reason: '기기 설정은 모든 스코프에서 동일해야 함');
    }
  });

  test('clearScope only clears that account, others intact', () async {
    SharedPreferences.setMockInitialValues({});
    await LocalStore.init();
    final s = LocalStore.instance;

    s.setScope('user_A');
    await s.setString(StorageKeys.memos, '{"2026-06-01":"A memo"}');
    s.setScope('user_B');
    await s.setString(StorageKeys.memos, '{"2026-06-01":"B memo"}');

    await s.clearScope('user_A');

    s.setScope('user_A');
    expect(s.getString(StorageKeys.memos), isNull);
    s.setScope('user_B');
    expect(s.getString(StorageKeys.memos), contains('B memo'));
  });
}
