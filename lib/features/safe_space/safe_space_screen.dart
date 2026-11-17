import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/struggle_catalog.dart';
import '../../core/navigation.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/l10n.dart';
import '../../providers.dart';
import '../notifications/notification_bell.dart';
import '../relax/games/bubble_pop_game.dart';
import '../relax/games/grounding_game.dart';
import '../relax/games/memory_game.dart';
import '../support/calm_screen.dart';
import '../support/professional_support_screen.dart';
import '../support/support_lines_card.dart';

/// "Sakinleş" — kriz anı güvenli alanı. Dürtü ya da kaygı geldiğinde tek
/// dokunuşla: acil arama, nefes (al-tut-ver), 5-4-3-2-1 ve kafa dağıtan
/// kısa oyunlar. Süre baskısı, kaybetme, puan kıyası ve REKLAM yok.
class SafeSpaceScreen extends ConsumerWidget {
  const SafeSpaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final p = HavenPalette.of(context);
    final categories = (ref.watch(strugglesProvider).value ?? const []).map((s) => s.category).toSet();
    final mostCare = highestCare(categories);
    final tip = mostCare == null
        ? null
        : mostCare.calmTips[DateTime.now().hour % mostCare.calmTips.length];

    return Scaffold(
      appBar: AppBar(title: Text(l.calmTitle), actions: const [NotificationBell(), SizedBox(width: 4)]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Text(l.calmIntro, style: t.bodyMedium),
          const SizedBox(height: 14),

          // 1) Acil destek — her zaman en üstte.
          Card(
            color: HavenColors.clay.withValues(alpha: 0.12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.emergency_outlined, color: HavenColors.clay),
                  const SizedBox(width: 8),
                  Text(l.emergencyTitle, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 4),
                Text(l.emergencyBody, style: t.bodySmall),
                const SizedBox(height: 12),
                Row(children: [
                  for (final line in kSupportLines) ...[
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: line.number == '112' ? HavenColors.clay : p.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => callSupportLine(line.number),
                        icon: const Icon(Icons.call_rounded),
                        label: Text(line.number == '112' ? '112 Acil' : '${line.number} Yeşilay'),
                      ),
                    ),
                    if (line != kSupportLines.last) const SizedBox(width: 10),
                  ],
                ]),
                TextButton(
                  onPressed: () => pushScreen(context, 'professional_support', const ProfessionalSupportScreen()),
                  child: Text('${l.supportTitle} → ${l.supportDesc}'),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 12),

          // 2) Nefes
          _BigTile(
            icon: Icons.air_rounded,
            title: l.breathingTitle,
            subtitle: l.breathingDesc,
            color: p.primary,
            onTap: () => pushScreen(context, 'calm', CalmScreen(category: mostCare)),
          ),
          const SizedBox(height: 12),

          // 3) Topraklanma + oyunlar
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.05,
            children: [
              _GridTile(Icons.center_focus_strong_outlined, l.groundingTitle, l.groundingDesc,
                  const Color(0xFF8A7458), () => pushScreen(context, 'game_grounding', const GroundingGame())),
              _GridTile(Icons.bubble_chart_outlined, l.gameBubbles, l.gameBubblesDesc, const Color(0xFF5B7DB1),
                  () => pushScreen(context, 'game_bubbles', const BubblePopGame())),
              _GridTile(Icons.palette_outlined, l.gameColors, l.gameColorsDesc, const Color(0xFFA0603F),
                  () => pushScreen(context, 'game_colors', const MemoryGame(colorMode: true))),
              _GridTile(Icons.style_outlined, l.gameMemory, l.gameMemoryDesc, const Color(0xFF4E8063),
                  () => pushScreen(context, 'game_memory', const MemoryGame())),
            ],
          ),
          if (tip != null) ...[
            const SizedBox(height: 14),
            Card(
              child: ListTile(
                leading: Icon(Icons.lightbulb_outline_rounded, color: p.accent),
                title: const Text('Şu an işe yarayabilir'),
                subtitle: Text(tip),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BigTile extends StatelessWidget {
  const _BigTile({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      color: Color.alphaBlend(color.withValues(alpha: 0.12), Theme.of(context).colorScheme.surfaceContainerLow),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.18), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle, style: t.bodySmall),
              ]),
            ),
            const Icon(Icons.play_circle_fill_rounded, size: 34),
          ]),
        ),
      ),
    );
  }
}

class _GridTile extends StatelessWidget {
  const _GridTile(this.icon, this.title, this.subtitle, this.color, this.onTap);
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      clipBehavior: Clip.antiAlias,
      color: Color.alphaBlend(color.withValues(alpha: dark ? 0.18 : 0.1), Theme.of(context).colorScheme.surfaceContainerLow),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color, size: 26),
            ),
            const Spacer(),
            Text(title, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            Text(subtitle, style: t.bodySmall, maxLines: 2),
          ]),
        ),
      ),
    );
  }
}
