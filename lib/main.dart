import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'storage/local_store.dart';
import 'supabase/supabase_client.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 상태바 투명 처리
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));

  // 로컬 저장소 초기화
  await LocalStore.init();

  // Supabase 초기화 (dart-define 값이 있을 때만)
  await initSupabase();

  runApp(
    const ProviderScope(
      child: SpaceHourApp(),
    ),
  );
}
