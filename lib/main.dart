import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'storage/local_store.dart';
import 'supabase/supabase_client.dart';
import 'supabase/account_scope.dart';
import 'providers/record_templates_provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 상태바 투명 처리
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));

  // 로컬 저장소 초기화 + 레거시 데이터 백업/마이그레이션(1회)
  await LocalStore.init();
  await LocalStore.instance.migrateLegacyToGuestOnce();
  // 기록 데이터 일반화 마이그레이션(공부 studyHours→primary 등, 1회)
  await migrateRecordDataOnce();

  // Supabase 초기화 (dart-define 값이 있을 때만)
  await initSupabase();

  // 복원된 세션에 맞춰 초기 계정 스코프 설정 + 변경 push 훅 설치
  final restored = sb?.auth.currentUser;
  LocalStore.instance.setScope(AccountScope.scopeFor(restored));
  AccountScope.installPushHook();

  runApp(
    const ProviderScope(
      child: SpaceHourApp(),
    ),
  );
}
