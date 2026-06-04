import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../supabase/auth_service.dart';
import '../../storage/local_store.dart';
import '../../core/constants/storage_keys.dart';
import '../main_shell.dart';
import '../onboarding/onboarding_screen.dart';
import '../login/login_screen.dart';
import 'splash_screen.dart';

/// 앱 진입점 게이트.
///
/// 스플래시를 표시하는 동안 (1) auth 정착(세션 복원 + 자동 로그인 시도)과
/// (2) 최소 표시 시간을 함께 기다린 뒤, 부드러운 fade 로 [MainShell] 로 전환한다.
///
/// 로그인 modal 은 여기서 띄우지 않는다 — MainShell 진입 후 overlay 로 표시된다
/// (기존 MainShell 로직 유지). 캘린더/시간표/Supabase 데이터 로직은 건드리지 않고,
/// auth 로딩 상태만 읽어 전환 타이밍에 활용한다.
class SplashGate extends ConsumerStatefulWidget {
  const SplashGate({super.key});

  @override
  ConsumerState<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends ConsumerState<SplashGate> {
  // 스플래시 최소 표시 시간 — 인트로 애니메이션(로고 등장 ~950ms)이 끝나고
  // 워드마크·로더가 충분히 보이도록 여유를 둔다(너무 빨리 지나가지 않게).
  static const _minSplash = Duration(milliseconds: 2200);

  bool _ready = false;
  // 온보딩 완료(또는 이미 시청) 여부. 미시청 첫 실행이면 false.
  bool _onboardingDone = false;
  // 이번 세션에서 로그인 화면을 이미 처리("나중에 하기" 포함)했는지.
  bool _loginHandled = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  void _finishOnboarding() {
    LocalStore.instance.setBool(StorageKeys.hasSeenOnboarding, true);
    if (mounted) setState(() => _onboardingDone = true);
  }

  Future<void> _bootstrap() async {
    // authProvider 를 읽어 notifier 를 구성 → 세션 복원/자동 로그인 파이프라인 시작.
    // (auth 상태 변화 시 데이터 pull/invalidate 는 기존 AccountScope 로직이 처리)
    final auth = ref.read(authProvider.notifier);

    // 최소 표시 시간과 auth(자동 로그인) 정착을 함께 대기.
    // ensureAutoLogin 은 1회만 실행되며, 세션이 이미 있으면 즉시 완료된다.
    await Future.wait<void>([
      Future<void>.delayed(_minSplash),
      auth.ensureAutoLogin(),
    ]);

    if (!mounted) return;
    // 온보딩을 이미 본 사용자면 바로 통과.
    final seen =
        LocalStore.instance.getBool(StorageKeys.hasSeenOnboarding) ?? false;
    setState(() {
      _ready = true;
      _onboardingDone = seen;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final Widget child;
    if (!_ready) {
      child = const SplashScreen(key: ValueKey('splash'));
    } else if (!_onboardingDone) {
      // 첫 실행: 스플래시 끝 → 온보딩.
      child = OnboardingScreen(
        key: const ValueKey('onboarding'),
        onDone: _finishOnboarding,
      );
    } else if (user == null && !_loginHandled) {
      // 미로그인 → 전체화면 로그인. 성공 또는 "나중에 하기" 시 홈으로.
      child = LoginScreen(
        key: const ValueKey('login'),
        showSkip: true,
        onDone: () => setState(() => _loginHandled = true),
      );
    } else {
      child = const MainShell(key: ValueKey('main'));
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: child,
    );
  }
}
