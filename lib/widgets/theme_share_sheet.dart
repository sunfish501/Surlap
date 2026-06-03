import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';
import '../providers/themes_provider.dart';
import '../supabase/theme_share_service.dart';
import '../modals/theme_manager_modal.dart';
import '../modals/timetable_template_modal.dart';

/// 일정 테마 공유 — 화면 아래에서 올라오는 floating bottom sheet.
/// 색상 테마가 아니라 일정 테마(카테고리)·시간표 템플릿 공유 기능.
/// 기존 ThemeManager / TimetableTemplate / ThemeShareService 로직을 재사용한다.
Future<void> showThemeShareSheet(BuildContext context) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent, // 자체 dim/blur 사용
      builder: (_) => const ThemeShareSheet(),
    );

class ThemeShareSheet extends StatelessWidget {
  const ThemeShareSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return SizedBox(
      height: h,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.pop(context),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.28)),
              ),
            ),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: _ShareSheetBody(),
          ),
        ],
      ),
    );
  }
}

class _ShareSheetBody extends ConsumerWidget {
  const _ShareSheetBody();

  // 추천 일정 템플릿 (placeholder — 적용 로직은 준비 중)
  static const _templates = [
    (title: '시험기간 루틴', sub: '공부 집중형',
        lines: ['19:00  국어', '20:30  수학', '22:00  영어']),
    (title: '학교 시간표', sub: '학생 기본형',
        lines: ['1교시  국어', '2교시  수학', '3교시  영어']),
    (title: '방학 루틴', sub: '자율 계획형',
        lines: ['09:00  공부', '14:00  운동', '21:00  복습']),
    (title: '운동 루틴', sub: '반복 일정형',
        lines: ['06:00  러닝', '18:00  헬스', '22:00  스트레칭']),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sh = context.sh;
    final h = MediaQuery.of(context).size.height;
    final themes = ref.watch(themesProvider);

    final mine = themes.where((t) => t.shareRole != 'subscriber').toList();
    final subbed = themes.where((t) => t.shareRole == 'subscriber').toList();

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(Gap.md, 0, Gap.md, Gap.md),
        constraints: BoxConstraints(maxHeight: h * 0.86),
        decoration: BoxDecoration(
          color: sh.bg,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 40,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 5,
              margin: const EdgeInsets.only(top: 10, bottom: 14),
              decoration: BoxDecoration(
                color: sh.ink.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            // 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 12, 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('테마 공유',
                            style: AppType.title.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: sh.ink)),
                        const SizedBox(height: 2),
                        Text('일정 루틴과 시간표 템플릿을 공유해요',
                            style: AppType.label.copyWith(
                                fontSize: 13, color: sh.inkSoft)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: sh.inkSoft),
                  ),
                ],
              ),
            ),
            // 본문
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 빠른 공유 ──
                    Row(
                      children: [
                        Expanded(
                          child: ThemeShareAction(
                            sh: sh,
                            icon: Icons.bookmark_add_outlined,
                            label: '테마 관리',
                            solid: true,
                            onTap: () {
                              final root = Navigator.of(context,
                                      rootNavigator: true)
                                  .context;
                              Navigator.pop(context);
                              showThemeManagerModal(root);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ThemeShareAction(
                            sh: sh,
                            icon: Icons.grid_view_rounded,
                            label: '시간표 템플릿',
                            solid: false,
                            onTap: () {
                              final root = Navigator.of(context,
                                      rootNavigator: true)
                                  .context;
                              Navigator.pop(context);
                              showTimetableTemplateModal(root);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ThemeShareAction(
                            sh: sh,
                            icon: Icons.download_rounded,
                            label: '가져오기',
                            solid: false,
                            onTap: () {
                              final root = Navigator.of(context,
                                      rootNavigator: true)
                                  .context;
                              Navigator.pop(context);
                              showDialog(
                                context: root,
                                builder: (_) => const _ImportThemeDialog(),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── 내 일정 테마 ──
                    _Section(
                      sh: sh,
                      title: '내 일정 테마',
                      child: mine.isEmpty
                          ? _EmptyHint(sh: sh, text: '아직 만든 일정 테마가 없어요')
                          : Column(
                              children: [
                                for (final t in mine)
                                  _ThemeRow(
                                    sh: sh,
                                    color: t.colorValue,
                                    name: t.name,
                                    shared: t.shareCode != null,
                                    onTap: () => _openManager(context),
                                  ),
                              ],
                            ),
                    ),

                    // ── 공유받은 테마 (있을 때만) ──
                    if (subbed.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _Section(
                        sh: sh,
                        title: '공유받은 테마',
                        child: Column(
                          children: [
                            for (final t in subbed)
                              _ThemeRow(
                                sh: sh,
                                color: t.colorValue,
                                name: t.name,
                                shared: false,
                                subscribed: true,
                                onTap: () => _openManager(context),
                              ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // ── 추천 템플릿 ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
                      child: Text('추천 템플릿',
                          style: AppType.label.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: sh.ink.withValues(alpha: 0.42))),
                    ),
                    SizedBox(
                      height: 150,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        itemCount: _templates.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (_, i) {
                          final t = _templates[i];
                          return TemplatePreviewCard(
                            sh: sh,
                            title: t.title,
                            sub: t.sub,
                            lines: t.lines,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('템플릿 적용 기능은 준비 중입니다.'),
                                    duration: Duration(seconds: 2)),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openManager(BuildContext context) {
    final root = Navigator.of(context, rootNavigator: true).context;
    Navigator.pop(context);
    showThemeManagerModal(root);
  }
}

// ─── 섹션 카드 ───────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final SpaceHourColors sh;
  final String title;
  final Widget child;
  const _Section({required this.sh, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
          child: Text(title,
              style: AppType.label.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: sh.ink.withValues(alpha: 0.42))),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: sh.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: sh.ink.withValues(alpha: 0.04)),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final SpaceHourColors sh;
  final String text;
  const _EmptyHint({required this.sh, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Center(
          child: Text(text,
              style: AppType.body.copyWith(color: sh.inkFaint)),
        ),
      );
}

// ─── 일정 테마 행 ────────────────────────────────────────────────
class _ThemeRow extends StatelessWidget {
  final SpaceHourColors sh;
  final Color color;
  final String name;
  final bool shared;
  final bool subscribed;
  final VoidCallback onTap;
  const _ThemeRow({
    required this.sh,
    required this.color,
    required this.name,
    required this.shared,
    this.subscribed = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(name,
                  style: AppType.body.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: sh.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            if (shared) _Badge(sh: sh, text: '공유 중', accent: true),
            if (subscribed) _Badge(sh: sh, text: '구독 중', accent: false),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 20, color: sh.inkFaint),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final SpaceHourColors sh;
  final String text;
  final bool accent;
  const _Badge({required this.sh, required this.text, required this.accent});

  @override
  Widget build(BuildContext context) {
    final c = accent ? sh.accent : sh.inkSoft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text,
          style: AppType.label.copyWith(
              fontSize: 11, fontWeight: FontWeight.w700, color: c)),
    );
  }
}

// ─── 빠른 공유 액션 버튼 ─────────────────────────────────────────
class ThemeShareAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool solid;
  final VoidCallback onTap;
  final SpaceHourColors sh;

  const ThemeShareAction({
    super.key,
    required this.icon,
    required this.label,
    required this.solid,
    required this.onTap,
    required this.sh,
  });

  @override
  Widget build(BuildContext context) {
    final fg = solid ? Colors.white : sh.ink;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: solid ? sh.accent : sh.card,
          borderRadius: BorderRadius.circular(16),
          border: solid
              ? null
              : Border.all(color: sh.ink.withValues(alpha: 0.06)),
          boxShadow: solid
              ? [
                  BoxShadow(
                    color: sh.accent.withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: fg),
            const SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                style: AppType.label.copyWith(
                    fontSize: 11.5, fontWeight: FontWeight.w700, color: fg)),
          ],
        ),
      ),
    );
  }
}

// ─── 추천 템플릿 미리보기 카드 ───────────────────────────────────
class TemplatePreviewCard extends StatelessWidget {
  final SpaceHourColors sh;
  final String title;
  final String sub;
  final List<String> lines;
  final VoidCallback onTap;

  const TemplatePreviewCard({
    super.key,
    required this.sh,
    required this.title,
    required this.sub,
    required this.lines,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 156,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: sh.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: sh.ink.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: AppType.body.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: sh.ink)),
            Text(sub,
                style: AppType.label.copyWith(
                    fontSize: 11, color: sh.accent, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            // 일정 구조 미리보기
            for (final l in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: sh.accent.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(l,
                          style: AppType.label.copyWith(
                              fontSize: 11, color: sh.inkSoft),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
          ],
        ),
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
          style: AppType.section.copyWith(
              fontWeight: FontWeight.w700, color: sh.ink)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('공유받은 8자리 코드를 입력하세요',
              style: AppType.label.copyWith(color: sh.inkSoft)),
          const SizedBox(height: Gap.md),
          TextField(
            controller: _ctrl,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(hintText: '예) ABCD2345'),
            onSubmitted: (_) => _import(),
          ),
          if (_error != null) ...[
            const SizedBox(height: Gap.sm),
            Text(_error!,
                style: AppType.label.copyWith(color: sh.danger)),
          ],
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소')),
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
