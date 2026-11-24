import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import '../../l10n/tx.dart';

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
    final st = HavenStyle.of(context);
    final danger = st.danger;
    final country = ref.watch(countryProvider);
    final categories = (ref.watch(strugglesProvider).value ?? const []).map((s) => s.category).toSet();
    final mostCare = highestCare(categories);
    final tip = mostCare == null ? null : mostCare.calmTips[DateTime.now().hour % mostCare.calmTips.length];

    return Scaffold(
      appBar: AppBar(title: Text(l.calmTitle), actions: const [NotificationBell(), SizedBox(width: 4)]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Text(l.calmIntro, style: t.bodyMedium),
          const SizedBox(height: 14),

          // 1) Acil destek — her zaman en üstte.
          HavenCard(
            color: danger.withValues(alpha: st.dark ? 0.16 : 0.12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.emergency_outlined, color: danger),
                      const SizedBox(width: 8),
                      Text(l.emergencyTitle, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(l.emergencyBody, style: t.bodySmall),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: danger,
                            foregroundColor: st.isClassic ? null : st.t.onDanger,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () => callSupportLine(country.emergency),
                          icon: const Icon(Icons.call_rounded),
                          label: Text(tx('{number} Acil', {'number': country.emergency})),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: p.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: country.lines.isEmpty
                              ? openHelplineDirectory
                              : () => callSupportLine(country.lines.first.number),
                          icon: Icon(country.lines.isEmpty ? Icons.travel_explore_rounded : Icons.call_rounded),
                          label: Text(
                            country.lines.isEmpty ? tx('Yardım hatları') : country.lines.first.number,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => pushScreen(context, 'professional_support', const ProfessionalSupportScreen()),
                    child: Text('${l.supportTitle} → ${l.supportDesc}'),
                  ),
                ],
              ),
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
              _GridTile(
                Icons.center_focus_strong_outlined,
                l.groundingTitle,
                l.groundingDesc,
                st.game(0),
                () => pushScreen(context, 'game_grounding', const GroundingGame()),
              ),
              _GridTile(
                Icons.bubble_chart_outlined,
                l.gameBubbles,
                l.gameBubblesDesc,
                st.game(1),
                () => pushScreen(context, 'game_bubbles', const BubblePopGame()),
              ),
              _GridTile(
                Icons.palette_outlined,
                l.gameColors,
                l.gameColorsDesc,
                st.game(2),
                () => pushScreen(context, 'game_colors', const MemoryGame(colorMode: true)),
              ),
              _GridTile(
                Icons.style_outlined,
                l.gameMemory,
                l.gameMemoryDesc,
                st.game(3),
                () => pushScreen(context, 'game_memory', const MemoryGame()),
              ),
            ],
          ),
          if (tip != null) ...[
            const SizedBox(height: 14),
            HavenCard(
              child: ListTile(
                leading: Icon(Icons.lightbulb_outline_rounded, color: p.accent),
                title: Text(tx('Şu an işe yarayabilir')),
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
  const _BigTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final st = HavenStyle.of(context);
    return HavenCard(
      clipBehavior: Clip.antiAlias,
      color: st.isClassic || !st.t.tileFilled
          ? Color.alphaBlend(color.withValues(alpha: 0.12), Theme.of(context).colorScheme.surfaceContainerLow)
          : st.t.primarySoft,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: st.tileBox(color, shape: BoxShape.circle),
                child: Icon(icon, color: st.isClassic || !st.t.tileFilled ? color : st.t.onPrimary, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: t.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.play_circle_fill_rounded, size: 34),
            ],
          ),
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
    final st = HavenStyle.of(context);
    return HavenCard(
      clipBehavior: Clip.antiAlias,
      // Neşeli: kutu dolu renk; diğerleri açık ton.
      color: !st.isClassic && st.t.tileFilled
          ? color
          : Color.alphaBlend(
              color.withValues(alpha: dark ? 0.18 : 0.1),
              Theme.of(context).colorScheme.surfaceContainerLow,
            ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: !st.isClassic && st.t.tileFilled
                    ? st.box(color: Colors.white, radius: 14)
                    : st.box(color: color.withValues(alpha: 0.16), radius: 14, outlined: false),
                child: Icon(
                  icon,
                  color: !st.isClassic && st.t.tileFilled ? st.t.ink : (st.isClassic ? color : st.readable(color)),
                  size: 26,
                ),
              ),
              const Spacer(),
              Text(title, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              Text(subtitle, style: t.bodySmall, maxLines: 2),
            ],
          ),
        ),
      ),
    );
  }
}
