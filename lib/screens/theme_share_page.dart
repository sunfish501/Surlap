import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';
import '../models/calendar_theme.dart';
import '../providers/themes_provider.dart';
import '../supabase/theme_share_service.dart';
import '../modals/theme_manager_modal.dart';
import '../widgets/app_page_scaffold.dart';

/// 테마 공유 — 일정/루틴 테마를 공유받기·공유하기·비공개 보관으로 분류.
/// 색상 테마·학교 시간표 템플릿·추천 템플릿은 다루지 않는다.
class ThemeSharePage extends ConsumerStatefulWidget {
  const ThemeSharePage({super.key});

  @override
  ConsumerState<ThemeSharePage> createState() => _ThemeSharePageState();
}

enum _Tab { received, shared, private }

class _ThemeSharePageState extends ConsumerState<ThemeSharePage> {
  _Tab _tab = _Tab.received;

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    final themes = ref.watch(themesProvider);

    final received =
        themes.where((t) => t.shareRole == 'subscriber').toList();
    final shared = themes
        .where((t) => t.shareCode != null && t.shareRole == 'owner')
        .toList();
    final private = themes.where((t) => t.shareCode == null).toList();

    final list = switch (_tab) {
      _Tab.received => received,
      _Tab.shared => shared,
      _Tab.private => private,
    };

    return AppPageScaffold(
      title: '테마 공유',
      subtitle: '일정·루틴 테마를 공유하고 받아요',
      children: [
        // ── 세그먼트 ──
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: sh.card2,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: [
              _seg('공유받은', _Tab.received, received.length, sh),
              _seg('내가 공유한', _Tab.shared, shared.length, sh),
              _seg('비공개', _Tab.private, private.length, sh),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // 작은 보조 액션(가져오기/테마 관리) — 큰 버튼 대신 텍스트 링크.
        Row(
          children: [
            _miniLink(sh, Icons.download_rounded, '코드로 가져오기', () {
              showDialog(
                  context: context, builder: (_) => const _ImportThemeDialog());
            }),
            const SizedBox(width: 16),
            _miniLink(sh, Icons.tune_rounded, '테마 관리', () {
              showThemeManagerModal(context);
            }),
          ],
        ),
        const SizedBox(height: 12),

        // ── 리스트 ──
        if (list.isEmpty)
          _empty(sh, _tab)
        else
          for (final t in list)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ThemeCard(
                theme: t,
                tab: _tab,
                sh: sh,
                onManage: () => showThemeManagerModal(context),
                onShare: () => _share(t),
              ),
            ),
      ],
    );
  }

  Widget _seg(String label, _Tab tab, int count, SpaceHourColors sh) {
    final active = _tab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? sh.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text('$label${count > 0 ? ' $count' : ''}',
              textAlign: TextAlign.center,
              style: AppType.label.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : sh.inkSoft)),
        ),
      ),
    );
  }

  Widget _miniLink(
      SpaceHourColors sh, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: sh.accent),
          const SizedBox(width: 4),
          Text(label,
              style: AppType.label.copyWith(
                  fontSize: 12, fontWeight: FontWeight.w700, color: sh.accent)),
        ],
      ),
    );
  }

  Widget _empty(SpaceHourColors sh, _Tab tab) {
    final (IconData icon, String title, String sub) = switch (tab) {
      _Tab.received => (
          Icons.inbox_rounded,
          '공유받은 테마가 없어요',
          '친구에게 받은 코드로 가져와보세요'
        ),
      _Tab.shared => (
          Icons.ios_share_rounded,
          '아직 공유한 테마가 없어요',
          '비공개 테마에서 공유를 시작해보세요'
        ),
      _Tab.private => (
          Icons.bookmark_border_rounded,
          '저장한 일정 테마가 없어요',
          '자주 쓰는 일정 테마를 만들어보세요'
        ),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: sh.accent.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 28, color: sh.accent),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: AppType.body.copyWith(
                    fontSize: 15, fontWeight: FontWeight.w700, color: sh.ink)),
            const SizedBox(height: 4),
            Text(sub,
                textAlign: TextAlign.center,
                style: AppType.label.copyWith(
                    fontSize: 12.5, color: sh.inkSoft, height: 1.4)),
          ],
        ),
      ),
    );
  }

  Future<void> _share(CalendarTheme theme) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final code = await ThemeShareService.shareTheme(theme);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('공유 코드: $code — 친구에게 알려주세요')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('공유하려면 로그인이 필요해요')),
      );
    }
  }
}

// ─── 테마 카드 ───────────────────────────────────────────────────
class _ThemeCard extends StatelessWidget {
  final CalendarTheme theme;
  final _Tab tab;
  final SpaceHourColors sh;
  final VoidCallback onManage;
  final VoidCallback onShare;

  const _ThemeCard({
    required this.theme,
    required this.tab,
    required this.sh,
    required this.onManage,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
      decoration: BoxDecoration(
        color: sh.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: sh.ink.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                    color: theme.colorValue, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(theme.name,
                    style: AppType.body.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: sh.ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              if (tab == _Tab.shared)
                _badge(sh, '공개 중', sh.accent)
              else if (tab == _Tab.received)
                _badge(sh, '구독 중', sh.inkSoft)
              else
                _badge(sh, '개인 저장', sh.inkSoft),
            ],
          ),
          if (theme.shareCode != null) ...[
            const SizedBox(height: 6),
            Text('코드 ${theme.shareCode}',
                style: AppType.label.copyWith(
                    fontSize: 11, color: sh.inkFaint)),
          ],
          const SizedBox(height: 12),
          // 작은 액션들
          Row(
            children: [
              if (tab == _Tab.private)
                _action(sh, '공유하기', filled: true, onTap: onShare),
              if (tab == _Tab.private) const SizedBox(width: 8),
              _action(sh, tab == _Tab.shared ? '수정 · 공유중지' : '관리',
                  filled: false, onTap: onManage),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(SpaceHourColors sh, String text, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: c.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999)),
        child: Text(text,
            style: AppType.label.copyWith(
                fontSize: 11, fontWeight: FontWeight.w700, color: c)),
      );

  Widget _action(SpaceHourColors sh, String label,
      {required bool filled, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: filled ? sh.accent : sh.ink.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label,
            style: AppType.label.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: filled ? Colors.white : sh.ink.withValues(alpha: 0.7))),
      ),
    );
  }
}

// ─── 테마 가져오기 (공유 코드) ───────────────────────────────────
class _ImportThemeDialog extends ConsumerStatefulWidget {
  const _ImportThemeDialog();

  @override
  ConsumerState<_ImportThemeDialog> createState() => _ImportThemeDialogState();
}

class _ImportThemeDialogState extends ConsumerState<_ImportThemeDialog> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    final code = _ctrl.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _error = '공유 코드를 입력해주세요');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final theme = await ThemeShareService.fetchByCode(code);
      if (theme == null) {
        setState(() {
          _error = '테마를 찾을 수 없습니다';
          _loading = false;
        });
        return;
      }
      final existing = ref.read(themesProvider);
      if (existing.any((t) => t.shareCode == theme.shareCode)) {
        setState(() {
          _error = '이미 가져온 테마예요';
          _loading = false;
        });
        return;
      }
      await ref
          .read(themesProvider.notifier)
          .add(theme.copyWith(shareRole: 'subscriber'));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('테마 "${theme.name}" 가져오기 완료')),
        );
      }
    } catch (e) {
      setState(() {
        _error = '가져오기 오류: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    return AlertDialog(
      title: Text('테마 가져오기',
          style: AppType.section
              .copyWith(fontWeight: FontWeight.w700, color: sh.ink)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('공유받은 8자리 코드를 입력하세요',
              style: AppType.label.copyWith(color: sh.inkSoft)),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(hintText: '예) ABCD2345'),
            onSubmitted: (_) => _import(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: AppType.label.copyWith(color: sh.danger)),
          ],
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('취소')),
        FilledButton(
          onPressed: _loading ? null : _import,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('가져오기'),
        ),
      ],
    );
  }
}
