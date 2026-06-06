import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';
import '../models/calendar_theme.dart';
import '../models/shared_theme_payload.dart';
import '../providers/themes_provider.dart';
import '../providers/events_provider.dart';
import '../supabase/auth_service.dart';
import '../supabase/theme_share_service.dart';
import '../widgets/mascot/mascot.dart';
import '../widgets/mascot/mascot_feedback.dart';
import 'share_code_modal.dart';

Future<void> showThemeManagerModal(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const ThemeManagerModal(),
  );
}

class ThemeManagerModal extends ConsumerWidget {
  const ThemeManagerModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sh = context.sh;
    return FractionallySizedBox(
      heightFactor: 0.88,
      child: Container(
        decoration: BoxDecoration(
          color: sh.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // 그랩 핸들
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: sh.ink.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            // 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.sm, Gap.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('공유 캘린더',
                            style: AppType.title.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: sh.ink)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: sh.inkSoft, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(color: sh.border, height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.lg, Gap.xl),
                child: const ThemeManagerBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 테마(카테고리) 관리 본문 — 모달/테마 탭 양쪽에서 인라인으로 재사용.
class ThemeManagerBody extends ConsumerWidget {
  const ThemeManagerBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sh = context.sh;
    final themes = ref.watch(themesProvider);

    final local =
        themes.where((t) => t.shareCode == null).toList();
    final owned = themes
        .where((t) => t.shareCode != null && t.shareRole == 'owner')
        .toList();
    final subbed = themes
        .where((t) => t.shareCode != null && t.shareRole == 'subscriber')
        .toList();

    final allEmpty = local.isEmpty && owned.isEmpty && subbed.isEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (allEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: MascotEmptyState(
              expression: MascotExpression.neutral,
              title: '아직 만든 캘린더가 없어요',
              message: '캘린더를 만들어 일정을 색으로 구분해요',
              mascotSize: 92,
              showStars: false,
            ),
          ),
        if (local.isNotEmpty) ...[
          _GroupLabel('내 카테고리', sh),
          ...local.map((t) => _ThemeRow(
              key: ValueKey(t.id),
              theme: t, editable: true, ref: ref, sh: sh)),
        ],
        if (owned.isNotEmpty) ...[
          _GroupLabel('공유 중 · 내가 공유', sh),
          ...owned.map((t) => _ThemeRow(
              key: ValueKey(t.id),
              theme: t, editable: true, ref: ref, sh: sh,
              shareCode: t.shareCode)),
        ],
        if (subbed.isNotEmpty) ...[
          _GroupLabel('구독 중', sh),
          ...subbed.map((t) => _ThemeRow(
              key: ValueKey(t.id),
              theme: t, editable: false, ref: ref, sh: sh,
              shareCode: t.shareCode)),
        ],
        const SizedBox(height: 18),
        // ── primary: 새 캘린더 만들기(텍스트 CTA) + 가져오기(아이콘) ──
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _addTheme(ref),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('새 캘린더 만들기',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                style: FilledButton.styleFrom(
                  backgroundColor: sh.accent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // 가져오기 — 아이콘 버튼.
            Tooltip(
              message: '공유 코드로 가져오기',
              child: Semantics(
                button: true,
                label: '공유 코드로 가져오기',
                child: SizedBox(
                  width: 54,
                  height: 54,
                  child: OutlinedButton(
                    onPressed: () => _importTheme(context, ref, sh),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor:
                          sh.ink.withValues(alpha: sh.dark ? 0.04 : 0.02),
                      side:
                          BorderSide(color: sh.ink.withValues(alpha: 0.12)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Icon(Icons.download_rounded,
                        size: 22, color: sh.inkSoft),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _addTheme(WidgetRef ref) {
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
        title: Text('공유 코드 입력', style: AppType.section.copyWith(color: sh.ink)),
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
                    MascotToast.error(context, '해당 코드의 캘린더를 찾을 수 없어요');
                  }
                  return;
                }
                // Subscribe: add with role='subscriber'
                final subTheme = theme.copyWith(shareRole: 'subscriber');
                ref.read(themesProvider.notifier).add(subTheme);
                if (context.mounted) {
                  MascotToast.success(context, '캘린더 "${theme.name}" 가져왔어요');
                }
              } catch (e) {
                if (context.mounted) {
                  MascotToast.error(context, '가져오기에 실패했어요');
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
    child: Text(text,
        style: AppType.label.copyWith(
            fontWeight: FontWeight.w800, color: sh.inkSoft)),
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
  bool _editing = false;
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.theme.name);
    _color = widget.theme.colorValue;
    // 편집 중 포커스 잃으면 저장 후 보기 모드로 복귀.
    _focus.addListener(() {
      if (!_focus.hasFocus && _editing) {
        _saveName(_nameCtrl.text);
        if (mounted) setState(() => _editing = false);
      }
    });
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
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sh = widget.sh;
    final t = widget.theme;
    final subtitle = t.shareRole == 'owner'
        ? '내가 공유 중'
        : t.shareRole == 'subscriber'
            ? '구독 중'
            : '공유 안 됨';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: sh.card2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: sh.ink.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _colorDot(sh),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _nameField(sh),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: AppType.caption.copyWith(color: sh.inkSoft)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(spacing: 8, children: _actionChips(sh)),
          ),
        ],
      ),
    );
  }

  // 색상 원 — 큰 사이즈 + 글로우 + 흰 링으로 "탭 가능" 강조.
  Widget _colorDot(SpaceHourColors sh) {
    final dot = Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: _color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: _color.withValues(alpha: 0.40), blurRadius: 14),
        ],
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.22), width: 2),
      ),
    );
    if (!widget.editable) return dot;
    return GestureDetector(onTap: _pickColor, child: dot);
  }

  // 이름 — 평소엔 카드 제목 텍스트, 탭하면 편집 모드.
  Widget _nameField(SpaceHourColors sh) {
    final titleStyle = AppType.body.copyWith(
        fontSize: 20, fontWeight: FontWeight.w800, color: sh.ink);
    if (_editing) {
      return TextField(
        controller: _nameCtrl,
        focusNode: _focus,
        autofocus: true,
        style: titleStyle,
        decoration: InputDecoration(
          isDense: true,
          filled: false,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintText: '캘린더 이름',
          hintStyle: TextStyle(color: sh.inkFaint),
        ),
        onSubmitted: (v) {
          _saveName(v);
          setState(() => _editing = false);
        },
      );
    }
    final empty = widget.theme.name.trim().isEmpty;
    final title = Text(
      empty ? '캘린더 이름' : widget.theme.name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: empty ? titleStyle.copyWith(color: sh.inkFaint) : titleStyle,
    );
    if (!widget.editable) return title;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _editing = true),
      child: title,
    );
  }

  // 상태별 액션 칩(라벨 + 약한 배경).
  List<Widget> _actionChips(SpaceHourColors sh) {
    final t = widget.theme;
    if (t.shareRole == 'subscriber') {
      return [
        _chip(Icons.refresh_rounded, '받기', sh.inkSoft, _refreshSubscribed, sh),
        _chip(Icons.copy_rounded, '복제', sh.accent, _duplicateToMine, sh),
        _chip(Icons.delete_outline_rounded, '구독 취소', sh.danger, _delete, sh),
      ];
    }
    final chips = <Widget>[];
    if (widget.shareCode != null) {
      chips.add(_chip(Icons.ios_share_rounded, '공유', sh.accent,
          () => _shareLink(t.name, widget.shareCode!), sh));
    } else if (widget.editable) {
      chips.add(_chip(
          Icons.link_rounded, '공유', sh.accent, () => _shareTheme(context), sh));
    }
    chips.add(_chip(Icons.delete_outline_rounded, '삭제', sh.danger, _delete, sh));
    return chips;
  }

  // 아이콘 버튼(라벨 없음). 접근성 위해 Tooltip + Semantics 유지.
  Widget _chip(IconData icon, String label, Color color, VoidCallback onTap,
      SpaceHourColors sh) {
    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: sh.dark ? 0.16 : 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
        ),
      ),
    );
  }

  void _saveName(String name) {
    if (name.trim().isEmpty) { return; }
    final updated = widget.theme.copyWith(name: name.trim());
    ref.read(themesProvider.notifier).update(updated);
    _syncOwned(updated);
  }

  // owner가 소유 테마를 수정하면 클라우드 payload도 갱신(테마 + 일정).
  // 실제 업로드는 themeSharingProvider 가 themesProvider 변경을 듣고 디바운스 처리한다.
  void _syncOwned(CalendarTheme t) {
    if (t.shareCode != null && t.shareRole == 'owner') {
      final events = eventsForTheme(ref.read(eventsProvider), t.id);
      ThemeShareService.updateShare(t.shareCode!, t, events)
          .catchError((Object e) {
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
            const SnackBar(content: Text('원본 캘린더를 찾을 수 없어요(삭제됨?)')));
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
    MascotToast.success(context, '"${copy.name}" 내 캘린더로 복제했어요');
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
    // 로그인 안 된 경우: 예외 대신 친절한 안내.
    if (ref.read(authProvider) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인해야 이용할 수 있는 서비스입니다')),
      );
      return;
    }
    try {
      final events = eventsForTheme(ref.read(eventsProvider), widget.theme.id);
      final code = await ThemeShareService.shareTheme(widget.theme, events);
      ref.read(themesProvider.notifier).update(
          widget.theme.copyWith(shareCode: code, shareRole: 'owner'));
      if (context.mounted) _shareLink(widget.theme.name, code);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인해야 이용할 수 있는 서비스입니다')),
        );
      }
    }
  }

  // OS 공유창 대신 앱 자체 모달(코드창)을 띄운다 — 코드/링크 각각 클립보드 복사.
  void _shareLink(String name, String code) {
    final httpsLink = ThemeShareService.httpsLinkForCode(code);
    showShareCodeModal(context, name, code, httpsLink);
  }
}
