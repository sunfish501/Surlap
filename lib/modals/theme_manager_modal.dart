import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';
import '../models/calendar_theme.dart';
import '../providers/themes_provider.dart';
import '../supabase/theme_share_service.dart';

Future<void> showThemeManagerModal(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const ThemeManagerModal(),
  );
}

class ThemeManagerModal extends ConsumerWidget {
  const ThemeManagerModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sh = context.sh;
    final themes = ref.watch(themesProvider);

    // 분류: local, owned(공유 중), sub(구독 중)
    final local  = themes.where((t) => t.shareCode == null).toList();
    final owned  = themes.where((t) => t.shareCode != null && t.shareRole == 'owner').toList();
    final subbed = themes.where((t) => t.shareCode != null && t.shareRole == 'subscriber').toList();

    return FractionallySizedBox(
      heightFactor: 0.88,
      child: Container(
        color: sh.card,
        child: Column(
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.sm, Gap.md),
              child: Row(
                children: [
                  Text('테마 관리',
                      style: AppType.title.copyWith(color: sh.ink)),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: sh.inkSoft, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(color: sh.border, height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, Gap.xl),
                children: [
                  if (local.isNotEmpty) ...[
                    _GroupLabel('내 카테고리', sh),
                    ...local.map((t) => _ThemeRow(
                        key: ValueKey(t.id),
                        theme: t, editable: true, ref: ref, sh: sh)),
                  ],
                  if (owned.isNotEmpty) ...[
                    _GroupLabel('🔗 공유 중 · 내가 공유', sh),
                    ...owned.map((t) => _ThemeRow(
                        key: ValueKey(t.id),
                        theme: t, editable: true, ref: ref, sh: sh,
                        shareCode: t.shareCode)),
                  ],
                  if (subbed.isNotEmpty) ...[
                    _GroupLabel('📥 구독 중', sh),
                    ...subbed.map((t) => _ThemeRow(
                        key: ValueKey(t.id),
                        theme: t, editable: false, ref: ref, sh: sh,
                        shareCode: t.shareCode)),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
            // 하단 버튼
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.lg),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _addTheme(context, ref),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('테마 추가'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: sh.accent,
                        side: BorderSide(color: sh.accent),
                        minimumSize: const Size.fromHeight(kMinTouch),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Radii.card)),
                      ),
                    ),
                  ),
                  const SizedBox(width: Gap.md),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _importTheme(context, ref, sh),
                      icon: const Icon(Icons.download_outlined, size: 18),
                      label: const Text('초대 링크로 가져오기'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: sh.inkSoft,
                        side: BorderSide(color: sh.border),
                        minimumSize: const Size.fromHeight(kMinTouch),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(Radii.card)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addTheme(BuildContext context, WidgetRef ref) {
    final theme = CalendarTheme(
      id: 'th_${const Uuid().v4().replaceAll('-', '').substring(0, 8)}',
      name: '새 카테고리',
      color: '#5b9bd5',
    );
    ref.read(themesProvider.notifier).add(theme);
  }

  void _importTheme(BuildContext context, WidgetRef ref, SpaceHourColors sh) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: sh.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('초대 코드 입력', style: AppType.section.copyWith(color: sh.ink)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'XXXXXXXX',
            hintStyle: TextStyle(color: sh.inkFaint),
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          FilledButton(
            onPressed: () async {
              final code = ctrl.text.trim();
              Navigator.pop(ctx);
              if (code.isEmpty) return;
              try {
                final theme = await ThemeShareService.fetchByCode(code);
                if (theme == null) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('해당 코드의 테마를 찾을 수 없습니다')),
                    );
                  }
                  return;
                }
                // Subscribe: add with role='subscriber'
                final subTheme = theme.copyWith(shareRole: 'subscriber');
                ref.read(themesProvider.notifier).add(subTheme);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('테마 "${theme.name}" 가져오기 완료')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('오류: $e')),
                  );
                }
              }
            },
            child: const Text('가져오기'),
          ),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String text;
  final SpaceHourColors sh;
  const _GroupLabel(this.text, this.sh);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(0, Gap.lg, 0, Gap.sm),
    child: Text(text, style: AppType.label.copyWith(color: sh.inkSoft)),
  );
}

class _ThemeRow extends ConsumerStatefulWidget {
  final CalendarTheme theme;
  final bool editable;
  final WidgetRef ref;
  final SpaceHourColors sh;
  final String? shareCode;

  const _ThemeRow({
    super.key,
    required this.theme, required this.editable,
    required this.ref, required this.sh, this.shareCode,
  });

  @override
  ConsumerState<_ThemeRow> createState() => _ThemeRowState();
}

class _ThemeRowState extends ConsumerState<_ThemeRow> {
  late TextEditingController _nameCtrl;
  late Color _color;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.theme.name);
    _color = widget.theme.colorValue;
  }

  @override
  void didUpdateWidget(covariant _ThemeRow old) {
    super.didUpdateWidget(old);
    // 같은 행(ValueKey로 theme.id 고정)에서 테마 속성이 외부 변경되면 재동기화.
    if (old.theme.color != widget.theme.color) {
      _color = widget.theme.colorValue;
    }
    if (old.theme.name != widget.theme.name &&
        widget.theme.name != _nameCtrl.text) {
      _nameCtrl.text = widget.theme.name;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sh = widget.sh;
    return Container(
      margin: const EdgeInsets.only(bottom: Gap.sm),
      padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.md),
      decoration: BoxDecoration(
        color: sh.card2,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: sh.border),
      ),
      child: Row(
        children: [
          // 색상 도트 (탭하면 색상 변경)
          GestureDetector(
            onTap: widget.editable ? _pickColor : null,
            child: Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: _color,
                shape: BoxShape.circle,
                border: Border.all(color: sh.border, width: 1.5),
              ),
            ),
          ),
          const SizedBox(width: Gap.md),
          // 이름 편집
          Expanded(
            child: TextField(
              controller: _nameCtrl,
              readOnly: !widget.editable,
              style: AppType.body.copyWith(color: sh.ink),
              decoration: InputDecoration(
                hintText: '카테고리 이름',
                hintStyle: TextStyle(color: sh.inkFaint),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (v) => _saveName(v),
              onEditingComplete: () => _saveName(_nameCtrl.text),
            ),
          ),
          // 공유 코드 배지 (탭하면 링크 공유)
          if (widget.shareCode != null)
            GestureDetector(
              onTap: () => _shareLink(widget.theme.name, widget.shareCode!),
              child: Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: sh.accentBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(widget.shareCode!,
                    style: AppType.label.copyWith(color: sh.accentInk)),
              ),
            ),
          // 구독 테마: 최신 내용 받기(owner 수정 반영) + 내 테마로 복제
          if (widget.theme.shareRole == 'subscriber') ...[
            IconButton(
              icon: Icon(Icons.refresh_rounded, size: 18, color: sh.inkSoft),
              tooltip: '최신 내용 받기',
              onPressed: _refreshSubscribed,
              padding: const EdgeInsets.only(left: 2),
              constraints: const BoxConstraints(),
            ),
            IconButton(
              icon: Icon(Icons.copy_rounded, size: 17, color: sh.inkSoft),
              tooltip: '내 테마로 복제',
              onPressed: _duplicateToMine,
              padding: const EdgeInsets.only(left: 2),
              constraints: const BoxConstraints(),
            ),
          ],
          // 공유 버튼 (로컬·오너 테마만 — subscriber는 제외)
          if (widget.editable && widget.shareCode == null)
            IconButton(
              icon: Icon(Icons.link_rounded, size: 18, color: sh.inkSoft),
              tooltip: '공유하기',
              onPressed: () => _shareTheme(context),
              padding: const EdgeInsets.only(left: 2),
              constraints: const BoxConstraints(),
            ),
          // 삭제 버튼 (구독 테마는 "구독 취소")
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, size: 18, color: sh.danger),
            tooltip: widget.theme.shareRole == 'subscriber' ? '구독 취소' : '삭제',
            onPressed: _delete,
            padding: const EdgeInsets.only(left: 4),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  void _saveName(String name) {
    if (name.trim().isEmpty) { return; }
    final updated = widget.theme.copyWith(name: name.trim());
    ref.read(themesProvider.notifier).update(updated);
    _syncOwned(updated);
  }

  // owner가 소유 테마를 수정하면 클라우드 payload도 갱신(실패해도 로컬은 유지).
  void _syncOwned(CalendarTheme t) {
    if (t.shareCode != null && t.shareRole == 'owner') {
      ThemeShareService.updateShare(t.shareCode!, t).catchError((Object e) {
        debugPrint('[ThemeShare] 소유 테마 수정 동기화 실패: $e');
      });
    }
  }

  // 구독 테마의 최신 내용을 클라우드에서 다시 받아 반영(owner 수정 반영).
  Future<void> _refreshSubscribed() async {
    final code = widget.theme.shareCode;
    if (code == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final latest = await ThemeShareService.fetchByCode(code);
      if (latest == null) {
        messenger.showSnackBar(
            const SnackBar(content: Text('원본 테마를 찾을 수 없습니다(삭제됨?)')));
        return;
      }
      // id/역할/코드는 유지, 내용(이름·색·이미지)만 최신으로.
      ref.read(themesProvider.notifier).update(widget.theme.copyWith(
            name: latest.name,
            color: latest.color,
            image: latest.image,
          ));
      messenger.showSnackBar(
          SnackBar(content: Text('"${latest.name}" 최신 내용 반영됨')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('새로고침 실패: $e')));
    }
  }

  // 구독 테마를 편집 가능한 내 로컬 테마로 복제.
  void _duplicateToMine() {
    final copy = CalendarTheme(
      id: 'th_${const Uuid().v4().replaceAll('-', '').substring(0, 8)}',
      name: '${widget.theme.name} (복사본)',
      color: widget.theme.color,
      image: widget.theme.image,
      // shareCode/shareRole 없음 → 내가 편집할 수 있는 로컬 테마
    );
    ref.read(themesProvider.notifier).add(copy);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${copy.name}" 내 테마로 복제됨')),
    );
  }

  void _pickColor() async {
    // 간단한 색상 선택: 미리 정의된 색상 팔레트
    final presets = [
      '#d33333','#e67e22','#f1c40f','#2ecc71','#1abc9c',
      '#3498db','#5b9bd5','#9b59b6','#e91e63','#607d8b',
      '#795548','#ff5722','#4caf50','#00bcd4','#673ab7',
    ];
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final sh = context.sh;
        return AlertDialog(
          backgroundColor: sh.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('색상 선택', style: AppType.section.copyWith(color: sh.ink)),
          content: Wrap(
            spacing: 10, runSpacing: 10,
            children: presets.map((hex) {
              final c = Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
              return GestureDetector(
                onTap: () => Navigator.pop(ctx, hex),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
    if (picked == null) { return; }
    setState(() => _color = Color(int.parse('FF${picked.replaceAll('#', '')}', radix: 16)));
    final updated = widget.theme.copyWith(color: picked);
    ref.read(themesProvider.notifier).update(updated);
    _syncOwned(updated);
  }

  void _delete() {
    ref.read(themesProvider.notifier).delete(widget.theme.id);
  }

  Future<void> _shareTheme(BuildContext context) async {
    try {
      final code = await ThemeShareService.shareTheme(widget.theme);
      ref.read(themesProvider.notifier).update(
          widget.theme.copyWith(shareCode: code, shareRole: 'owner'));
      if (context.mounted) _shareLink(widget.theme.name, code);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('공유 실패: $e')),
        );
      }
    }
  }

  // 공유 코드 + 링크를 시스템 공유 시트로 내보낸다(링크는 클립보드에도 복사).
  // https 앱링크를 주로, 커스텀 스킴/코드를 폴백으로 함께 담는다.
  void _shareLink(String name, String code) {
    final httpsLink = ThemeShareService.httpsLinkForCode(code);
    Clipboard.setData(ClipboardData(text: httpsLink));
    Share.share(
      '"$name" 테마를 공유했어요.\n'
      '링크로 열기: $httpsLink\n'
      '앱에서 바로 열기: ${ThemeShareService.linkForCode(code)}\n'
      '또는 코드 입력: $code',
      subject: 'spaceHour 테마 공유',
    );
  }
}
