import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/color_presets.dart';
import '../providers/color_preset_provider.dart';
import '../widgets/sidebar_drawer.dart';
import '../modals/theme_manager_modal.dart';
import '../modals/profile_modal.dart';
import '../utils/screenshot_util.dart';

class AppHeader extends ConsumerWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sh = context.sh;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      color: sh.bg,
      child: Row(
        children: [
          // spaceHour 브랜드
          Row(
            children: [
              _SpaceHourLogo(color: sh.ink),
              const SizedBox(width: 6),
              Text('spaceHour',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: sh.ink,
                      letterSpacing: -0.3)),
            ],
          ),
          const Spacer(),
          // 이미지 저장 버튼
          InkWell(
            onTap: captureAndShare,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Icon(Icons.ios_share_outlined, size: 18, color: sh.inkSoft),
            ),
          ),
          const SizedBox(width: 2),
          // 색상 프리셋 팔레트 버튼
          _PaletteDot(ref: ref, sh: sh),
          const SizedBox(width: 4),
          // 카테고리 관리 버튼
          _HeaderBtn(
            icon: Icons.label_outline_rounded,
            label: '카테고리',
            color: sh.inkSoft,
            onTap: () => showThemeManagerModal(context),
          ),
          const SizedBox(width: 2),
          // 설정 버튼
          _HeaderBtn(
            icon: Icons.settings_outlined,
            label: '설정',
            color: sh.inkSoft,
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => const FractionallySizedBox(
                heightFactor: 0.85,
                child: SidebarDrawer(),
              ),
            ),
          ),
          const SizedBox(width: 2),
          // 프로필 버튼
          _HeaderBtn(
            icon: Icons.person_outline_rounded,
            label: '프로필',
            color: sh.inkSoft,
            onTap: () => showProfileModal(context),
          ),
        ],
      ),
    );
  }
}

class _SpaceHourLogo extends StatelessWidget {
  final Color color;
  const _SpaceHourLogo({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(22, 22),
      painter: _LogoPainter(color: color),
    );
  }
}

class _LogoPainter extends CustomPainter {
  final Color color;
  _LogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final s = size.width;
    // outer rect
    final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(1, 1.5, s - 2, s - 2.5), const Radius.circular(3));
    canvas.drawRRect(rrect, p);
    // header line
    canvas.drawLine(Offset(1, s * 0.36), Offset(s - 1, s * 0.36), p);
    // hanger lines
    canvas.drawLine(Offset(s * 0.29, 0), Offset(s * 0.29, s * 0.22), p);
    canvas.drawLine(Offset(s * 0.71, 0), Offset(s * 0.71, s * 0.22), p);
    // dot grid
    final dp = Paint()..color = color..style = PaintingStyle.fill;
    for (final x in [s * 0.3, s * 0.5, s * 0.7]) {
      canvas.drawCircle(Offset(x, s * 0.59), 1.2, dp);
    }
    canvas.drawCircle(Offset(s * 0.3, s * 0.78), 1.2, dp);
    canvas.drawCircle(Offset(s * 0.5, s * 0.78), 1.2, dp);
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.color != color;
}

class _PaletteDot extends StatelessWidget {
  final WidgetRef ref;
  final SpaceHourColors sh;
  const _PaletteDot({required this.ref, required this.sh});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPalette(context, ref),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: sh.dot,
          shape: BoxShape.circle,
          border: Border.all(color: sh.border, width: 1.5),
        ),
      ),
    );
  }

  void _showPalette(BuildContext context, WidgetRef ref) {
    final preset = ref.read(colorPresetProvider);
    showModalBottomSheet(
      context: context,
      builder: (_) => _PaletteSheet(currentId: preset.id, ref: ref),
    );
  }
}

class _PaletteSheet extends StatelessWidget {
  final String currentId;
  final WidgetRef ref;
  const _PaletteSheet({required this.currentId, required this.ref});

  @override
  Widget build(BuildContext context) {
    final sh = context.sh;
    return Container(
      padding: const EdgeInsets.all(20),
      color: sh.card,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('색상 테마',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: sh.inkSoft)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: kColorPresets.map((p) {
              final selected = p.id == currentId;
              return GestureDetector(
                onTap: () {
                  ref.read(colorPresetProvider.notifier).setPreset(p.id);
                  Navigator.pop(context);
                },
                child: Tooltip(
                  message: p.name,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: p.dot,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? sh.ink : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: selected
                          ? [BoxShadow(color: p.dot.withValues(alpha: 0.4), blurRadius: 6)]
                          : null,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _HeaderBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _HeaderBtn({required this.icon, required this.label,
    required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
