// auth.js 대응 — 아이디는 '<id>@cal-id.local' 이메일로 합성.
// Supabase Dashboard에서 이메일 확인 비활성화 필요.
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/storage_keys.dart';
import '../storage/local_store.dart';
import 'supabase_client.dart';
import 'account_scope.dart';

const _idDomain = 'cal-id.local';

String idToEmail(String id) => '${id.toLowerCase().trim()}@$_idDomain';
bool isSyntheticEmail(String email) => email.endsWith('@$_idDomain');
String emailToId(String email) =>
    isSyntheticEmail(email) ? email.substring(0, email.length - _idDomain.length - 1) : email;
bool isValidId(String id) => RegExp(r'^[a-zA-Z0-9_]{4,20}$').hasMatch(id);

String userDisplayName(User? u) {
  if (u == null) { return ''; }
  final email = u.email ?? '';
  if (isSyntheticEmail(email)) { return emailToId(email); }
  return u.userMetadata?['nickname'] as String? ?? email;
}

class AuthNotifier extends Notifier<User?> {
  @override
  User? build() {
    sb?.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;
      state = user;
      // 계정 스코프 전환 + pull + provider invalidate 단일 처리
      AccountScope.applyAuth(ref, user);
    });
    final current = sb?.auth.currentUser;
    // Supabase 세션이 복원되지 않았으면 로컬 자격증명으로 자동 로그인 시도.
    if (current == null) {
      Future.microtask(ensureAutoLogin);
    }
    return current;
  }

  // 자동 로그인을 앱 프로세스당 1회만 실행하고 그 future를 캐시한다.
  // 스플래시(SplashGate)가 같은 future를 await 해 전환 타이밍을 맞출 수 있다.
  Future<void>? _autoLoginOnce;

  /// 자동 로그인 1회 실행 후 그 future 반환(이미 실행됐으면 동일 future).
  /// 세션이 이미 복원돼 있으면 [tryAutoLogin] 이 즉시 반환한다.
  Future<void> ensureAutoLogin() => _autoLoginOnce ??= tryAutoLogin();

  // ── 자동 로그인용 자격증명 (전역 저장, base64 난독화) ──────────
  Future<void> _saveCredentials(String id, String password) async {
    final ls = LocalStore.instance;
    await ls.setString(StorageKeys.savedAuthId, id.toLowerCase().trim());
    await ls.setString(
        StorageKeys.savedAuthPw, base64Encode(utf8.encode(password)));
  }

  Future<void> _clearCredentials() async {
    final ls = LocalStore.instance;
    await ls.remove(StorageKeys.savedAuthId);
    await ls.remove(StorageKeys.savedAuthPw);
  }

  /// 앱 시작 시: 활성 세션이 없고 로컬에 저장된 로그인 기록이 있으면 재로그인.
  Future<void> tryAutoLogin() async {
    if (state != null) return; // 이미 세션 복원됨
    final ls = LocalStore.instance;
    final id = ls.getString(StorageKeys.savedAuthId);
    final pwEnc = ls.getString(StorageKeys.savedAuthPw);
    if (id == null || id.isEmpty || pwEnc == null || pwEnc.isEmpty) return;
    String pw;
    try {
      pw = utf8.decode(base64Decode(pwEnc));
    } catch (_) {
      return; // 손상된 값 → 무시
    }
    try {
      await signInWithId(id, pw);
    } catch (e) {
      // 실패해도 자격증명은 유지(네트워크 일시 오류일 수 있음).
      debugPrint('[Auth] 자동 로그인 실패: $e');
    }
  }

  Future<void> signInWithId(String id, String password) async {
    final client = sb;
    if (client == null) { throw Exception('Supabase 클라이언트가 없습니다'); }
    if (!isValidId(id)) { throw Exception('아이디는 4~20자 영문/숫자/_'); }
    try {
      final res = await client.auth.signInWithPassword(
          email: idToEmail(id), password: password);
      state = res.user;
      await _saveCredentials(id, password); // 자동 로그인용 저장
      // 스코프 전환 + 데이터 pull + invalidate 는 onAuthStateChange→AccountScope 처리
    } catch (e, st) {
      debugPrint('[Auth] signInWithId 실패: ${e.runtimeType} → $e');
      debugPrint('$st');
      rethrow;
    }
  }

  Future<void> signUpWithId(String id, String password) async {
    final client = sb;
    if (client == null) { throw Exception('Supabase 클라이언트가 없습니다'); }
    if (!isValidId(id)) { throw Exception('아이디는 4~20자 영문/숫자/_'); }
    try {
      final res = await client.auth.signUp(
          email: idToEmail(id), password: password,
          data: {'id': id});
      state = res.user;
      await _saveCredentials(id, password); // 자동 로그인용 저장
      // 신규 계정은 빈 데이터로 시작(게스트 데이터는 guest 스코프에 보존).
      // 스코프 전환/invalidate 는 AccountScope 가 처리.
    } catch (e, st) {
      debugPrint('[Auth] signUpWithId 실패: ${e.runtimeType} → $e');
      debugPrint('$st');
      rethrow;
    }
  }

  // 웹 OAuth 복귀 URL — 쿼리·프래그먼트(해시 라우트) 제거, 경로(서브패스)는 보존.
  // 예: https://kev208dev.github.io/Surlap/#/x → https://kev208dev.github.io/Surlap/
  String _webRedirectUrl() {
    final b = Uri.base;
    return Uri(
      scheme: b.scheme,
      host: b.host,
      port: b.hasPort ? b.port : null,
      path: b.path,
    ).toString();
  }

  Future<void> signInGoogle() async {
    final client = sb;
    if (client == null) { throw Exception('Supabase 클라이언트가 없습니다'); }
    try {
      await client.auth.signInWithOAuth(
        OAuthProvider.google,
        // 웹: 현재 앱 경로로 복귀 / 모바일: 등록된 딥링크 콜백으로 복귀.
        // 웹은 origin 만 쓰면 GitHub Pages 서브패스(/Surlap/)가 빠져
        // 앱이 아닌 루트로 복귀 → 세션을 못 받아 무한 로그인. 경로 보존 필요.
        // (Android의 Uri.base는 file:/// 이라 .origin이 StateError → 커스텀 스킴 사용)
        redirectTo: kIsWeb ? _webRedirectUrl() : 'spacehour://login-callback',
        // iOS: 기본(내장 SFSafariViewController)에선 Google이 임베디드 웹뷰로
        // 보고 흰 화면으로 막는다. 외부 Safari로 띄워야 로그인 후 커스텀 스킴
        // 콜백으로 정상 복귀. (Android는 supabase_flutter가 이미 external 강제)
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      // OAuth는 리다이렉트 방식 — 콜백 딥링크를 supabase_flutter가 받아
      // 세션을 복원하고 onAuthStateChange에서 상태 갱신됨
    } catch (e, st) {
      debugPrint('[Auth] signInGoogle 실패: ${e.runtimeType} → $e');
      debugPrint('$st');
      rethrow;
    }
  }

  /// Sign in with Apple — Apple App Store 4.8 요구사항 (Google 등 제3자 로그인 제공 시).
  /// iOS/macOS만 노출. Supabase 대시보드에 Apple provider 설정 + Service ID 필요.
  Future<void> signInApple() async {
    final client = sb;
    if (client == null) { throw Exception('Supabase 클라이언트가 없습니다'); }
    try {
      await client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: kIsWeb ? _webRedirectUrl() : 'spacehour://login-callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } catch (e, st) {
      debugPrint('[Auth] signInApple 실패: ${e.runtimeType} → $e');
      debugPrint('$st');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _clearCredentials(); // 자동 로그인 비활성화
    await sb?.auth.signOut();
    state = null;
  }

  /// 회원 탈퇴 — 서버 RPC(delete_account)가 auth 사용자와 연결 데이터를 삭제한다.
  /// Apple App Store 요구사항: 계정 생성이 가능한 앱은 앱 내 탈퇴를 제공해야 함.
  Future<void> deleteAccount() async {
    final client = sb;
    if (client == null) throw StateError('Supabase 미연결');
    await client.rpc('delete_account');
    await _clearCredentials();
    await client.auth.signOut();
    state = null;
  }

  bool get isLoggedIn => state != null;
  String get displayName => userDisplayName(state);
}

final authProvider = NotifierProvider<AuthNotifier, User?>(AuthNotifier.new);
