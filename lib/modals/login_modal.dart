import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../supabase/auth_service.dart';

Future<void> showLoginModal(BuildContext context) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const LoginModal(),
    );

class LoginModal extends ConsumerStatefulWidget {
  const LoginModal({super.key});
  @override ConsumerState<LoginModal> createState() => _LoginModalState();
}

class _LoginModalState extends ConsumerState<LoginModal> {
  final _idCtrl  = TextEditingController();
  final _pwCtrl  = TextEditingController();
  String? _error;
  bool _loading = false;
  bool _showForm = false;

  @override void dispose() { _idCtrl.dispose(); _pwCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        color: sh.card,
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🕐 spaceHour',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: sh.ink)),
            const SizedBox(height: 8),
            Text('사용 방식을 선택해주세요',
                style: TextStyle(fontSize: 14, color: sh.inkSoft)),
            const SizedBox(height: 28),
            if (!_showForm) ...[
              // ── Google 로그인 ──
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _loading ? null : _signInGoogle,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: sh.ink,
                    side: BorderSide(color: sh.border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _GoogleLogo(),
                      const SizedBox(width: 10),
                      const Text('Google로 로그인',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // ── 구분선 ──
              Row(children: [
                Expanded(child: Divider(color: sh.border)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('또는',
                      style: TextStyle(fontSize: 12, color: sh.inkFaint)),
                ),
                Expanded(child: Divider(color: sh.border)),
              ]),
              const SizedBox(height: 8),
              // ── 아이디 로그인 ──
              SizedBox(width: double.infinity,
                child: FilledButton(
                  onPressed: () => setState(() => _showForm = true),
                  child: const Text('아이디로 로그인'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: sh.inkSoft, side: BorderSide(color: sh.border)),
                  child: const Text('로그인 없이 사용'),
                ),
              ),
            ] else ...[
              if (_error != null)
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: sh.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                  child: Text(_error!,
                      style: TextStyle(color: sh.danger, fontSize: 13)),
                ),
              TextField(
                controller: _idCtrl,
                decoration: InputDecoration(
                    labelText: '아이디',
                    hintText: '처음이면 새 아이디 등록',
                    hintStyle: TextStyle(color: sh.inkFaint)),
                autofillHints: const [AutofillHints.username],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pwCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: '비밀번호', hintText: '4자 이상'),
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => setState(() { _showForm = false; _error = null; }),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: sh.inkSoft, side: BorderSide(color: sh.border)),
                  child: const Text('뒤로'),
                )),
                const SizedBox(width: 10),
                Expanded(flex: 2, child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('확인'),
                )),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _signInGoogle() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(authProvider.notifier).signInGoogle();
      // OAuth는 리다이렉트 방식이라 여기서 pop 불필요 (페이지 이동됨)
      // 모달은 열어두고 리다이렉트 대기
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _submit() async {
    final id = _idCtrl.text.trim();
    final pw = _pwCtrl.text;
    if (id.isEmpty || pw.isEmpty) {
      setState(() => _error = '아이디와 비밀번호를 입력해주세요');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      // 먼저 로그인 시도, 실패하면 회원가입
      try {
        await ref.read(authProvider.notifier).signInWithId(id, pw);
      } catch (_) {
        await ref.read(authProvider.notifier).signUpWithId(id, pw);
      }
      if (mounted) { Navigator.pop(context); }
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }
}

/// Google 'G' 로고 (SVG 재현)
class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(18, 18),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;

    // 파란색 부분
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      -0.52, 2.62, false,
      Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.stroke..strokeWidth = 4 * s,
    );
    // 빨간색
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      2.09, 1.05, false,
      Paint()..color = const Color(0xFFEA4335)..style = PaintingStyle.stroke..strokeWidth = 4 * s,
    );
    // 노란색
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      3.14, 0.52, false,
      Paint()..color = const Color(0xFFFBBC05)..style = PaintingStyle.stroke..strokeWidth = 4 * s,
    );
    // 초록색
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      3.66, 0.52, false,
      Paint()..color = const Color(0xFF34A853)..style = PaintingStyle.stroke..strokeWidth = 4 * s,
    );
    // 흰 가로선 (G의 수평 부분)
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.5),
      Offset(size.width * 0.92, size.height * 0.5),
      Paint()..color = const Color(0xFF4285F4)..strokeWidth = 3.5 * s..strokeCap = StrokeCap.round,
    );
    // 중심 흰 원 (구멍)
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.32,
      Paint()..color = Colors.white..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_GoogleLogoPainter old) => false;
}

