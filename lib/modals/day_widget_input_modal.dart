import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/date_utils.dart' as du;
import '../models/day_template.dart';
import '../providers/day_widget_provider.dart';
import '../day_widgets/widget_cell_renderer.dart';

Future<void> showDayWidgetInputModal(BuildContext context, String dateKey) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DayWidgetInputModal(dateKey: dateKey),
    );

class DayWidgetInputModal extends ConsumerWidget {
  final String dateKey;
  const DayWidgetInputModal({super.key, required this.dateKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sh = context.sh;
    final templates = ref.watch(dayTemplatesProvider);
    final applicable = templates.where((t) => t.scope.appliesTo(dateKey)).toList();
    final date = du.fromDateKey(dateKey);

    return FractionallySizedBox(
      heightFactor: 0.88,
      child: Container(
        color: sh.card,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 10),
              child: Row(children: [
                Text('📊 ${date.month}월 ${date.day}일 기록',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: sh.ink)),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: sh.inkSoft, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ]),
            ),
            Divider(color: sh.border, height: 1),
            Expanded(
              child: applicable.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.widgets_outlined, size: 48, color: sh.inkFaint),
                        const SizedBox(height: 12),
                        Text('이 날짜에 적용된 위젯 템플릿이 없어요',
                            style: TextStyle(color: sh.inkFaint, fontSize: 14)),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('닫기'),
                        ),
                      ]),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(20),
                      children: applicable.map((tpl) => _TemplateSection(
                        dateKey: dateKey, template: tpl, sh: sh, ref: ref,
                      )).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateSection extends StatelessWidget {
  final String dateKey;
  final DayTemplate template;
  final SpaceHourColors sh;
  final WidgetRef ref;
  const _TemplateSection({required this.dateKey, required this.template,
      required this.sh, required this.ref});

  @override
  Widget build(BuildContext context) {
    final values = ref.watch(widgetValuesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(template.name,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                  color: sh.inkSoft)),
        ),
        ...template.fields.map((field) {
          final value = values[dateKey]?[template.id]?[field.id];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: WidgetCellRenderer(
              field: field,
              value: value,
              sh: sh,
              compact: false,
              onChanged: (v) => ref.read(widgetValuesProvider.notifier)
                  .setValue(dateKey, template.id, field.id, v),
            ),
          );
        }),
        Divider(color: sh.border, height: 24),
      ],
    );
  }
}
