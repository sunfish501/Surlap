import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';
import '../models/user_type.dart';
import '../providers/user_type_provider.dart';
import '../providers/neis_cache_provider.dart';
import '../providers/academic_schedule_provider.dart';
import '../supabase/neis_service.dart';
import '../widgets/mascot/mascot_feedback.dart';

Future<void> showNeisSetupModal(BuildContext context) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NeisSetupModal(),
    );

class NeisSetupModal extends ConsumerStatefulWidget {
  const NeisSetupModal({super.key});
  @override
  ConsumerState<NeisSetupModal> createState() => _NeisSetupModalState();
}

class _NeisSetupModalState extends ConsumerState<NeisSetupModal> {
  final _nameCtrl = TextEditingController();
  final _sloganCtrl = TextEditingController();
  final _logoCtrl = TextEditingController();
  final _classCtrl = TextEditingController(text: '1');
  List<Map<String, dynamic>> _results = [];
  Map<String, dynamic>? _selected;
  NeisSchool? _existing; // 이미 연결된 학교(재진입 시 슬로건 등 편집)
  int _grade = 1;
  int _classNm = 1;
  bool _loading = false;
  String? _status;

  @override
  void initState() {
    super.initState();
    // 이미 연결돼 있으면 학년/반/슬로건/로고를 미리 채운다.
    final s = NeisSchool.load();
    if (s != null) {
      _existing = s;
      _grade = s.grade;
      _classNm = s.classNm;
      _classCtrl.text = '${s.classNm}';
      _sloganCtrl.text = s.slogan;
      _logoCtrl.text = s.logoOverride;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _sloganCtrl.dispose();
    _logoCtrl.dispose();
    _classCtrl.dispose();
    super.dispose();
  }

  // 현재 선택(검색결과) 또는 기존 연결 학교의 종류 문자열.
  String get _activeKind =>
      _selected?['SCHUL_KND_SC_NM']?.toString() ?? _existing?.kind ?? '';

  int get _maxGrade => maxGradeForSchoolKind(_activeKind);

  // 학교가 선택/연결된 상태인가 — 학년·슬로건 등 추가 입력을 노출.
  bool get _hasSchool => _selected != null || _existing != null;

  // 미리보기용 로고 URL(직접 지정 우선, 없으면 홈페이지 파비콘).
  String? get _previewLogo {
    final override = _logoCtrl.text.trim();
    if (override.isNotEmpty) return override;
    final hp = _selected?['HMPG_ADRES']?.toString() ?? _existing?.homepage ?? '';
    return faviconUrlFor(hp);
  }

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: sh.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 그랩 핸들
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: sh.ink.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('🏫 학교 연결',
                  style: AppType.section.copyWith(
                      fontSize: 18, fontWeight: FontWeight.w800, color: sh.ink)),
              const SizedBox(height: 4),
              Text('초·중·고는 시간표·급식·학사일정을 자동으로 가져와요.',
                  style: AppType.caption.copyWith(color: sh.inkSoft)),
              const SizedBox(height: Gap.lg),

              // 현재 연결된 학교 카드(있으면)
              if (_existing != null && _selected == null) ...[
                _SchoolPreviewCard(sh: sh, logo: _previewLogo, name: _existing!.name,
                    sub: '${_existing!.kind} · ${_existing!.grade}학년 ${_existing!.classNm}반'),
                const SizedBox(height: 14),
              ],

              // 학교명 검색
              Row(children: [
                Expanded(child: TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: _existing == null ? '학교명' : '다른 학교로 변경',
                    hintText: '예) 한국디지털미디어고등학교',
                    hintStyle: TextStyle(color: sh.inkFaint),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                )),
                const SizedBox(width: Gap.sm),
                FilledButton(
                  onPressed: _loading ? null : _search,
                  child: _loading
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('검색'),
                ),
              ]),
              if (_status != null)
                Padding(
                  padding: const EdgeInsets.only(top: Gap.sm),
                  child: Text(_status!, style: AppType.caption.copyWith(color: sh.inkSoft)),
                ),
              // 검색 결과
              if (_results.isNotEmpty) ...[
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _results.length,
                    itemBuilder: (_, i) {
                      final r = _results[i];
                      final sel = _selected == r;
                      return ListTile(
                        dense: true,
                        tileColor: sel ? sh.accentBg : null,
                        title: Text(r['SCHUL_NM']?.toString() ?? '',
                            style: AppType.body.copyWith(
                                fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                                color: sel ? sh.accentInk : sh.ink)),
                        subtitle: Text(
                            '${r['LCTN_SC_NM'] ?? ''} · ${r['SCHUL_KND_SC_NM'] ?? ''}',
                            style: AppType.label.copyWith(color: sh.inkSoft)),
                        onTap: () => setState(() {
                          _selected = r;
                          // 학교 종류가 바뀌면 학년 상한을 넘지 않게 보정.
                          if (_grade > _maxGrade) _grade = 1;
                        }),
                      );
                    },
                  ),
                ),
              ],
              // 학년/반 — 초등학교면 1~6, 그 외 1~3
              if (_hasSchool) ...[
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('학년', style: AppType.caption.copyWith(color: sh.inkSoft)),
                      DropdownButton<int>(
                        value: _grade.clamp(1, _maxGrade),
                        isExpanded: true,
                        items: List.generate(_maxGrade, (i) => i + 1)
                            .map((g) => DropdownMenuItem(value: g,
                                child: Text('$g학년'))).toList(),
                        onChanged: (v) { if (v != null) setState(() => _grade = v); },
                      ),
                    ],
                  )),
                  const SizedBox(width: Gap.lg),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('반', style: AppType.caption.copyWith(color: sh.inkSoft)),
                      TextField(
                        keyboardType: TextInputType.number,
                        controller: _classCtrl,
                        decoration: InputDecoration(
                            hintText: '1',
                            hintStyle: TextStyle(color: sh.inkFaint)),
                        onChanged: (v) => _classNm = int.tryParse(v) ?? 1,
                      ),
                    ],
                  )),
                ]),

                // ── 로고 · 슬로건 ──
                const SizedBox(height: 18),
                Row(children: [
                  _LogoThumb(sh: sh, url: _previewLogo),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('학교 로고',
                            style: AppType.label.copyWith(
                                fontWeight: FontWeight.w700, color: sh.ink)),
                        const SizedBox(height: 2),
                        Text('홈페이지 아이콘을 자동으로 가져와요',
                            style: AppType.caption.copyWith(color: sh.inkSoft)),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                TextField(
                  controller: _sloganCtrl,
                  decoration: InputDecoration(
                    labelText: '슬로건 / 교훈 (선택)',
                    hintText: '예) 꿈을 키우는 행복한 학교',
                    hintStyle: TextStyle(color: sh.inkFaint),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _logoCtrl,
                  decoration: InputDecoration(
                    labelText: '로고 이미지 URL 직접 지정 (선택)',
                    hintText: '비워두면 홈페이지 아이콘 사용',
                    hintStyle: TextStyle(color: sh.inkFaint),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: sh.inkSoft,
                      side: BorderSide(color: sh.ink.withValues(alpha: 0.12)),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16))),
                  child: const Text('취소',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                )),
                const SizedBox(width: Gap.md),
                Expanded(flex: 2, child: FilledButton(
                  onPressed: _hasSchool ? _save : null,
                  style: FilledButton.styleFrom(
                      backgroundColor: sh.accent,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16))),
                  child: Text(_existing != null && _selected == null ? '저장' : '연결',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                )),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _search() async {
    final q = _nameCtrl.text.trim();
    if (q.isEmpty) { return; }
    setState(() { _loading = true; _status = '검색 중…'; _results = []; _selected = null; });
    try {
      final rows = await searchSchools(q);
      setState(() {
        _results = rows;
        _status = rows.isEmpty ? '검색 결과가 없습니다' : null;
        _loading = false;
      });
    } catch (e) {
      setState(() { _status = '오류: $e'; _loading = false; });
    }
  }

  Future<void> _save() async {
    // 새로 고른 학교가 있으면 그 정보로, 없으면 기존 학교 정보에 슬로건/로고만 갱신.
    final NeisSchool school;
    if (_selected != null) {
      school = NeisSchool(
        name: _selected!['SCHUL_NM']?.toString() ?? '',
        code: _selected!['SD_SCHUL_CODE']?.toString() ?? '',
        officeCode: _selected!['ATPT_OFCDC_SC_CODE']?.toString() ?? '',
        kind: _selected!['SCHUL_KND_SC_NM']?.toString() ?? '',
        grade: _grade.clamp(1, _maxGrade),
        classNm: _classNm,
        homepage: _selected!['HMPG_ADRES']?.toString() ?? '',
        slogan: _sloganCtrl.text.trim(),
        logoOverride: _logoCtrl.text.trim(),
      );
    } else if (_existing != null) {
      school = _existing!.copyWith(
        grade: _grade.clamp(1, _maxGrade),
        classNm: _classNm,
        slogan: _sloganCtrl.text.trim(),
        logoOverride: _logoCtrl.text.trim(),
      );
    } else {
      return;
    }
    await school.save();
    // 유형이 아직 선택 안 됐으면 학교 종류로 자동 설정(고/중/초 학생).
    if (ref.read(userTypeProvider) == null) {
      final k = school.kind;
      final inferred = k.contains('고등')
          ? UserType.high
          : k.contains('중학')
              ? UserType.middle
              : k.contains('초등')
                  ? UserType.elementary
                  : null;
      if (inferred != null) {
        await ref.read(userTypeProvider.notifier).set(inferred);
      }
    }
    // 학교가 바뀌었으니 시간표·학사일정을 바로 다시 받아 즉시 반영.
    ref.read(neisCacheProvider.notifier).refresh();
    ref.read(academicScheduleProvider.notifier).refresh();
    if (mounted) {
      MascotToast.success(context, '${school.name} 연결 완료!');
      Navigator.pop(context);
    }
  }
}

// ─── 현재 연결된 학교 미리보기 카드 ─────────────────────────────────
class _SchoolPreviewCard extends StatelessWidget {
  final SpaceHourColors sh;
  final String? logo;
  final String name;
  final String sub;
  const _SchoolPreviewCard(
      {required this.sh, required this.logo, required this.name, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: sh.accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: sh.accent.withValues(alpha: 0.16)),
      ),
      child: Row(children: [
        _LogoThumb(sh: sh, url: logo),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.body.copyWith(
                      fontWeight: FontWeight.w800, color: sh.ink)),
              const SizedBox(height: 2),
              Text(sub,
                  style: AppType.label.copyWith(color: sh.inkSoft)),
            ],
          ),
        ),
        Icon(Icons.check_circle_rounded, color: sh.accent, size: 20),
      ]),
    );
  }
}

// ─── 로고 썸네일(파비콘/URL, 실패 시 학교 아이콘) ──────────────────
class _LogoThumb extends StatelessWidget {
  final SpaceHourColors sh;
  final String? url;
  const _LogoThumb({required this.sh, required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: sh.ink.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: (url != null && url!.isNotEmpty)
          ? Image.network(
              url!,
              width: 32,
              height: 32,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) =>
                  Icon(Icons.school_rounded, color: sh.inkSoft, size: 22),
            )
          : Icon(Icons.school_rounded, color: sh.inkSoft, size: 22),
    );
  }
}
