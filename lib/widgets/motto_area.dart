import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../providers/settings_provider.dart';

class MottoArea extends ConsumerStatefulWidget {
  const MottoArea({super.key});
  @override
  ConsumerState<MottoArea> createState() => _MottoAreaState();
}

class _MottoAreaState extends ConsumerState<MottoArea> {
  late TextEditingController _ctrl;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsProvider);
    _ctrl = TextEditingController(text: s.motto);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    final motto = ref.watch(settingsProvider).motto;
    if (!_editing && _ctrl.text != motto) _ctrl.text = motto;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
      color: sh.bg,
      child: Row(
        children: [
          Text('"', style: TextStyle(fontSize: 18, color: sh.accentInk,
              fontWeight: FontWeight.w700, height: 1)),
          Expanded(
            child: TextField(
              controller: _ctrl,
              style: TextStyle(fontSize: 13, color: sh.inkSoft,
                  fontStyle: FontStyle.italic),
              decoration: InputDecoration(
                hintText: '이달의 교훈 / 나의 모토 — 클릭해서 적어보세요',
                hintStyle: TextStyle(color: sh.inkFaint, fontSize: 13,
                    fontStyle: FontStyle.italic),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              maxLength: 120,
              buildCounter: (_, {required int currentLength,
                required bool isFocused, required int? maxLength}) => null,
              onTap: () => setState(() => _editing = true),
              onSubmitted: (v) {
                ref.read(settingsProvider.notifier).setMotto(v);
                setState(() => _editing = false);
              },
              onEditingComplete: () {
                ref.read(settingsProvider.notifier).setMotto(_ctrl.text);
                setState(() => _editing = false);
              },
            ),
          ),
          Text('"', style: TextStyle(fontSize: 18, color: sh.accentInk,
              fontWeight: FontWeight.w700, height: 1)),
        ],
      ),
    );
  }
}
