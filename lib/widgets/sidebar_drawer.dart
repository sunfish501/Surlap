import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../providers/settings_provider.dart';
import '../providers/themes_provider.dart';
import '../providers/filter_provider.dart';
import '../providers/birthdays_provider.dart';
import '../utils/vcf_parser.dart';
import '../modals/neis_setup_modal.dart';
import '../modals/timetable_template_modal.dart';

class SidebarDrawer extends StatelessWidget {
  const SidebarDrawer({super.key});

  @override
  Widget build(BuildContext context) => const _SidebarContent();
}

class _SidebarContent extends ConsumerWidget {
  const _SidebarContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sh = context.sh;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final themes = ref.watch(themesProvider);
    final hidden = ref.watch(filterProvider);
    final birthdays = ref.watch(birthdaysProvider);

    return Drawer(
      backgroundColor: sh.card,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
              child: Row(
                children: [
                  Expanded(child: Text('설정 · 보기 옵션',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                          color: sh.ink))),
                  IconButton(
                    icon: Icon(Icons.close, color: sh.inkSoft, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(color: sh.border, height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // 카테고리 필터
                  _SectionLabel('카테고리 필터', sh),
                  _FilterAll(themes: themes, hidden: hidden,
                      ref: ref, sh: sh),
                  ...themes.map((t) => _FilterItem(
                    theme: t,
                    hidden: hidden.contains(t.id),
                    onToggle: () => ref.read(filterProvider.notifier).toggle(t.id),
                    sh: sh,
                  )),
                  Divider(color: sh.border, height: 24),

                  // 보기 옵션
                  _SectionLabel('보기 옵션', sh),
                  _ToggleRow(
                    icon: Icons.history_rounded,
                    label: '지난 날 표시',
                    value: settings.showPast,
                    onChanged: (v) => notifier.setShowPast(v),
                    sh: sh,
                  ),
                  _ToggleRow(
                    icon: Icons.notifications_outlined,
                    label: '알림',
                    value: settings.notifyEnabled,
                    onChanged: (v) => notifier.setNotify(v),
                    sh: sh,
                  ),
                  _ToggleRow(
                    icon: Icons.view_stream_outlined,
                    label: '연속 보기',
                    value: settings.continuousView,
                    onChanged: (v) => notifier.setContinuousView(v),
                    sh: sh,
                  ),
                  // 주 시작일
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 14, color: sh.inkSoft),
                        const SizedBox(width: 8),
                        Expanded(child: Text('주 시작일',
                            style: TextStyle(fontSize: 13, color: sh.ink))),
                        DropdownButton<int>(
                          value: settings.weekStartDow,
                          underline: const SizedBox(),
                          style: TextStyle(fontSize: 12,
                              color: sh.ink, fontFamily: 'Pretendard'),
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('월요일')),
                            DropdownMenuItem(value: 0, child: Text('일요일')),
                            DropdownMenuItem(value: 6, child: Text('토요일')),
                          ],
                          onChanged: (v) {
                            if (v != null) notifier.setWeekStart(v);
                          },
                        ),
                      ],
                    ),
                  ),
                  Divider(color: sh.border, height: 24),

                  // ─── 더보기 ────────────────────────────
                  _SectionLabel('더보기', sh),
                  _SidebarBtn(
                    icon: Icons.grid_view_rounded,
                    label: '반복 시간표 설정',
                    sh: sh,
                    onTap: () {
                      Navigator.pop(context);
                      showTimetableTemplateModal(context);
                    },
                  ),
                  _SidebarBtn(
                    icon: Icons.school_outlined,
                    label: '학교 연결 (NEIS)',
                    sh: sh,
                    onTap: () {
                      Navigator.pop(context);
                      showNeisSetupModal(context);
                    },
                  ),
                  _SidebarBtn(
                    icon: Icons.cake_outlined,
                    label: birthdays.isEmpty
                        ? '생일 연락처 가져오기 (.vcf)'
                        : '생일 연락처 (${birthdays.length}명)',
                    sh: sh,
                    onTap: () => _importVcf(context, ref),
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

class _SidebarBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final SpaceHourColors sh;
  final VoidCallback onTap;
  const _SidebarBtn({required this.icon, required this.label,
      required this.sh, required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    leading: Icon(icon, size: 16, color: sh.inkSoft),
    title: Text(label, style: TextStyle(fontSize: 13, color: sh.ink)),
    onTap: onTap,
  );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final SpaceHourColors sh;
  const _SectionLabel(this.text, this.sh);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
    child: Text(text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
            color: sh.inkSoft, letterSpacing: 0.4)),
  );
}

class _FilterAll extends StatelessWidget {
  final List themes;
  final Set<String> hidden;
  final WidgetRef ref;
  final SpaceHourColors sh;
  const _FilterAll({required this.themes, required this.hidden,
    required this.ref, required this.sh});

  @override
  Widget build(BuildContext context) {
    final allVisible = hidden.isEmpty;
    return _FilterItem(
      dotColor: sh.inkSoft,
      label: '전체',
      checked: allVisible,
      onToggle: () {
        if (allVisible) {
          ref.read(filterProvider.notifier)
              .setAll(themes.map((t) => (t as dynamic).id as String).toList());
        } else {
          ref.read(filterProvider.notifier).clear();
        }
      },
      sh: sh,
    );
  }
}

class _FilterItem extends StatelessWidget {
  final dynamic theme;
  final Color? dotColor;
  final String? label;
  final bool? checked;
  final bool? hidden;
  final VoidCallback onToggle;
  final SpaceHourColors sh;

  const _FilterItem({
    this.theme, this.dotColor, this.label, this.checked, this.hidden,
    required this.onToggle, required this.sh,
  });

  @override
  Widget build(BuildContext context) {
    final isChecked = checked ?? !(hidden ?? false);
    final dot = dotColor ??
        (theme != null ? _parseColor(theme.color) : sh.inkSoft);
    final name = label ?? (theme?.name ?? '');

    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            Checkbox(
              value: isChecked,
              onChanged: (_) => onToggle(),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(name, style: TextStyle(fontSize: 13, color: sh.ink)),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }
}

Future<void> _importVcf(BuildContext context, WidgetRef ref) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['vcf'],
  );
  if (result == null || result.files.single.path == null) return;
  try {
    final content = await File(result.files.single.path!).readAsString();
    final parsed = parseVcf(content);
    ref.read(birthdaysProvider.notifier).addAll(parsed);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('생일 ${parsed.length}명 가져오기 완료')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('가져오기 오류: $e')),
      );
    }
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final SpaceHourColors sh;
  const _ToggleRow({required this.icon, required this.label,
    required this.value, required this.onChanged, required this.sh});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: sh.inkSoft),
          const SizedBox(width: 8),
          Expanded(child: Text(label,
              style: TextStyle(fontSize: 13, color: sh.ink))),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
