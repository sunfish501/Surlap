import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'providers/color_preset_provider.dart';
import 'providers/themes_provider.dart';
import 'screens/splash/splash_gate.dart';
import 'supabase/theme_share_service.dart';

/// 딥링크 등 어디서든 스낵바를 띄우기 위한 전역 messenger key.
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class SpaceHourApp extends ConsumerStatefulWidget {
  const SpaceHourApp({super.key});

  @override
  ConsumerState<SpaceHourApp> createState() => _SpaceHourAppState();
}

class _SpaceHourAppState extends ConsumerState<SpaceHourApp> {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    // 앱이 링크로 처음 실행된 경우
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handleUri(initial);
    } catch (_) {}
    // 앱 실행 중 들어오는 링크
    _sub = _appLinks.uriLinkStream.listen(_handleUri, onError: (_) {});
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  /// `spacehour://theme/CODE` 또는 (향후) `https://DOMAIN/theme/CODE`
  void _handleUri(Uri uri) {
    String? code;
    if (uri.scheme == ThemeShareService.scheme && uri.host == 'theme') {
      if (uri.pathSegments.isNotEmpty) code = uri.pathSegments.first;
    } else {
      final segs = uri.pathSegments;
      if (segs.length >= 2 && segs[segs.length - 2] == 'theme') {
        code = segs.last;
      }
    }
    if (code == null || code.trim().isEmpty) return;
    _subscribeToCode(code.toUpperCase().trim());
  }

  Future<void> _subscribeToCode(String code) async {
    final messenger = scaffoldMessengerKey.currentState;
    void snack(String m) =>
        messenger?.showSnackBar(SnackBar(content: Text(m)));
    try {
      final theme = await ThemeShareService.fetchByCode(code);
      if (theme == null) {
        snack('캘린더를 찾을 수 없어요: $code');
        return;
      }
      final existing = ref.read(themesProvider);
      if (existing.any((t) => t.shareCode == theme.shareCode)) {
        snack('이미 구독 중인 캘린더예요: ${theme.name}');
        return;
      }
      await ref
          .read(themesProvider.notifier)
          .add(theme.copyWith(shareRole: 'subscriber'));
      snack('캘린더 "${theme.name}" 구독 완료');
    } catch (e) {
      snack('링크 처리 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final preset = ref.watch(colorPresetProvider);
    return MaterialApp(
      title: 'HourSpace',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: buildTheme(preset),
      home: const SplashGate(),
    );
  }
}
