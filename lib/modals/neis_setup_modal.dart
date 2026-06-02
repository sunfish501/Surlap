import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/design_tokens.dart';
import '../supabase/neis_service.dart';

Future<void> showNeisSetupModal(BuildContext context) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const NeisSetupModal(),
    );

class NeisSetupModal extends StatefulWidget {
  const NeisSetupModal({super.key});
  @override State<NeisSetupModal> createState() => _NeisSetupModalState();
}

class _NeisSetupModalState extends State<NeisSetupModal> {
  final _nameCtrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  Map<String, dynamic>? _selected;
  int _grade = 1;
  int _classNm = 1;
  bool _loading = false;
  String? _status;

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        color: sh.card,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🏫 학교 연결',
                style: AppType.section.copyWith(fontWeight: FontWeight.w700, color: sh.ink)),
            const SizedBox(height: Gap.lg),
            // 학교명 검색
            Row(children: [
              Expanded(child: TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: '학교명',
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
                      onTap: () => setState(() => _selected = r),
                    );
                  },
                ),
              ),
            ],
            // 학년/반
            if (_selected != null) ...[
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('학년', style: AppType.caption.copyWith(color: sh.inkSoft)),
                    DropdownButton<int>(
                      value: _grade,
                      isExpanded: true,
                      items: [1,2,3].map((g) => DropdownMenuItem(value: g,
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
                      decoration: InputDecoration(
                          hintText: '1',
                          hintStyle: TextStyle(color: sh.inkFaint)),
                      onChanged: (v) => _classNm = int.tryParse(v) ?? 1,
                    ),
                  ],
                )),
              ]),
            ],
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                    foregroundColor: sh.inkSoft, side: BorderSide(color: sh.border)),
                child: const Text('취소'),
              )),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: FilledButton(
                onPressed: _selected == null ? null : _save,
                child: const Text('연결'),
              )),
            ]),
          ],
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
    if (_selected == null) { return; }
    final school = NeisSchool(
      name: _selected!['SCHUL_NM']?.toString() ?? '',
      code: _selected!['SD_SCHUL_CODE']?.toString() ?? '',
      officeCode: _selected!['ATPT_OFCDC_SC_CODE']?.toString() ?? '',
      kind: _selected!['SCHUL_KND_SC_NM']?.toString() ?? '',
      grade: _grade,
      classNm: _classNm,
    );
    await school.save();
    if (mounted) { Navigator.pop(context); }
  }
}
