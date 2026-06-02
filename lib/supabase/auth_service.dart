// auth.js 대응 — 아이디는 '<id>@cal-id.local' 이메일로 합성.
// Supabase Dashboard에서 이메일 확인 비활성화 필요.
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    return sb?.auth.currentUser;
  }

  Future<void> signInWithId(String id, String password) async {
    final client = sb;
    if (client == null) { throw Exception('Supabase 클라이언트가 없습니다'); }
    if (!isValidId(id)) { throw Exception('아이디는 4~20자 영문/숫자/_'); }
    try {
      final res = await client.auth.signInWithPassword(
          email: idToEmail(id), password: password);
      state = res.user;
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
      // 신규 계정은 빈 데이터로 시작(게스트 데이터는 guest 스코프에 보존).
      // 스코프 전환/invalidate 는 AccountScope 가 처리.
    } catch (e, st) {
      debugPrint('[Auth] signUpWithId 실패: ${e.runtimeType} → $e');
      debugPrint('$st');
      rethrow;
    }
  }

  Future<void> signInGoogle() async {
    final client = sb;
    if (client == null) { throw Exception('Supabase 클라이언트가 없습니다'); }
    try {
      await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: Uri.base.origin,   // 웹: 현재 페이지로 복귀
      );
      // OAuth는 리다이렉트 방식 — onAuthStateChange에서 상태 갱신됨
    } catch (e, st) {
      debugPrint('[Auth] signInGoogle 실패: ${e.runtimeType} → $e');
      debugPrint('$st');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await sb?.auth.signOut();
    state = null;
  }

  bool get isLoggedIn => state != null;
  String get displayName => userDisplayName(state);
}

final authProvider = NotifierProvider<AuthNotifier, User?>(AuthNotifier.new);
