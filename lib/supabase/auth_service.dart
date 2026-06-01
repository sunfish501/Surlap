// auth.js 대응 — 아이디는 '<id>@cal-id.local' 이메일로 합성.
// Supabase Dashboard에서 이메일 확인 비활성화 필요.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';
import 'user_data_sync.dart';
import 'events_sync.dart';

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
      state = data.session?.user;
    });
    return sb?.auth.currentUser;
  }

  Future<void> signInWithId(String id, String password) async {
    final client = sb;
    if (client == null) { throw Exception('Supabase 클라이언트가 없습니다'); }
    if (!isValidId(id)) { throw Exception('아이디는 4~20자 영문/숫자/_'); }
    final res = await client.auth.signInWithPassword(
        email: idToEmail(id), password: password);
    state = res.user;
    // 로그인 성공 → 클라우드에서 데이터 pull
    EventsSync.forceReady();
    await UserDataSync.pullAll();
  }

  Future<void> signUpWithId(String id, String password) async {
    final client = sb;
    if (client == null) { throw Exception('Supabase 클라이언트가 없습니다'); }
    if (!isValidId(id)) { throw Exception('아이디는 4~20자 영문/숫자/_'); }
    final res = await client.auth.signUp(
        email: idToEmail(id), password: password,
        data: {'id': id});
    state = res.user;
    EventsSync.forceReady();
    await UserDataSync.pushAll();
  }

  Future<void> signInGoogle() async {
    final client = sb;
    if (client == null) { throw Exception('Supabase 클라이언트가 없습니다'); }
    await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: Uri.base.origin,   // 웹: 현재 페이지로 복귀
    );
    // OAuth는 리다이렉트 방식 — onAuthStateChange에서 상태 갱신됨
  }

  Future<void> signOut() async {
    await sb?.auth.signOut();
    state = null;
  }

  bool get isLoggedIn => state != null;
  String get displayName => userDisplayName(state);
}

final authProvider = NotifierProvider<AuthNotifier, User?>(AuthNotifier.new);
