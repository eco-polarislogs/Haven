import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers.dart';
import '../../../l10n/tx.dart';

/// 5-4-3-2-1 topraklanma: kaygı/panik anında zihni şimdiye getirir.
/// Haven uyarlaması: klasik "tadını alabildiğin 1 şey" adımı yerine
/// "kendine söyleyebileceğin 1 nazik cümle" (yeme bozukluğu tetikleyicisi olmasın).
class GroundingGame extends ConsumerStatefulWidget {
  const GroundingGame({super.key});

  @override
  ConsumerState<GroundingGame> createState() => _GroundingGameState();
}

class _GroundingGameState extends ConsumerState<GroundingGame> {
  // Her adım: sayı, ekranda görünen etiket, simge, açıklama. Getter: dil değişince yenilenir.
  static List<(int, String, IconData, String)> get _steps => [
    (
      5,
      tx('{n} şey gör', {'n': 5}),
      Icons.visibility_outlined,
      tx('Etrafında görebildiğin 5 şeyi fark et. Her biri için dokun.'),
    ),
    (
      4,
      tx('{n} şeye dokun', {'n': 4}),
      Icons.pan_tool_outlined,
      tx('Dokunabildiğin 4 şeyi hisset: kumaş, masa, kendi ellerin…'),
    ),
    (
      3,
      tx('{n} ses duy', {'n': 3}),
      Icons.hearing_outlined,
      tx('Duyabildiğin 3 sese kulak ver: uzaktan bir araba, nefesin…'),
    ),
    (
      2,
      tx('{n} koku fark et', {'n': 2}),
      Icons.air_rounded,
      tx('Fark edebildiğin 2 kokuyu ara. Bulamazsan en sevdiğin kokuyu hayal et.'),
    ),
    (
      1,
      tx('{n} iyi dilek', {'n': 1}),
      Icons.favorite_border_rounded,
      tx('Kendine iyi gelen bir cümle söyle: "Şu an güvendeyim."'),
    ),
  ];

  int _step = 0;
  int _count = 0;

  bool get _done => _step >= _steps.length;

  void _tap() {
    if (_done) return;
    HapticFeedback.lightImpact();
    setState(() {
      _count++;
      if (_count >= _steps[_step].$1) {
        _step++;
        _count = 0;
        if (_done) ref.read(analyticsProvider).gameFinished('grounding', 15);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('5-4-3-2-1 topraklanma')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _steps.length; i++)
                  Container(
                    width: 36,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: i < _step || _done ? scheme.primary : scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            if (_done) ...[
              Icon(Icons.self_improvement_rounded, size: 72, color: primary),
              const SizedBox(height: 16),
              Text(tx('Şu andasın.'), style: t.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                tx('Zihnini nazikçe şimdiye getirdin. Bu bir beceri ve her denemede güçleniyor.'),
                style: t.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => setState(() {
                  _step = 0;
                  _count = 0;
                }),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Yeniden yap'),
              ),
            ] else ...[
              Text(_steps[_step].$2, style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Text(_steps[_step].$4, style: t.bodyLarge, textAlign: TextAlign.center),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: _tap,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primary.withValues(alpha: 0.12),
                    border: Border.all(color: primary, width: 3),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_steps[_step].$3, size: 48, color: primary),
                      const SizedBox(height: 8),
                      Text(
                        '${_steps[_step].$1 - _count}',
                        style: t.displaySmall?.copyWith(color: primary, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(tx('Fark ettikçe dokun'), style: t.bodySmall),
            ],
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
