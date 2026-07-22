import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../i18n/app_lang.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/surlap_logo.dart';

/// 첫 실행 시 가장 먼저 보이는 언어 선택 화면(온보딩·학교 연결 전).
/// 보라→블루 그라데이션(스플래시/온보딩 톤). 국기 + 자기 언어 이름.
class LanguageSelectScreen extends ConsumerWidget {
  final VoidCallback onDone;
  const LanguageSelectScreen({super.key, required this.onDone});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF5A2DF4),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5A2DF4), Color(0xFF7C4DFF)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              children: [
                const Spacer(flex: 2),
                const SurlapAppIconBadge(size: 96),
                const SizedBox(height: 20),
                // 미선택 상태라 중립적으로 두 언어 병기.
                const Text(
                  'Select language',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '언어 선택 · 言語 · 语言 · Idioma',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 28),
                ...AppLang.values.map(
                  (lang) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _LangTile(
                      lang: lang,
                      selected: lang == current,
                      onTap: () async {
                        await ref.read(localeProvider.notifier).set(lang);
                        onDone();
                      },
                    ),
                  ),
                ),
                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LangTile extends StatelessWidget {
  final AppLang lang;
  final bool selected;
  final VoidCallback onTap;
  const _LangTile({
    required this.lang,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              Text(lang.flag, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  lang.nativeName,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: selected ? const Color(0xFF5A2DF4) : Colors.white,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF5A2DF4),
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
