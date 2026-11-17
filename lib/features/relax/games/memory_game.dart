import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n.dart';
import '../../../providers.dart';

/// Hafıza kartları / renk eşleştirme: 6 çifti eşleştir. Süre yok; hamle
/// sayısı sadece bilgi. `colorMode` → kartların yüzünde renkler (daha sade).
class MemoryGame extends ConsumerStatefulWidget {
  const MemoryGame({super.key, this.colorMode = false});

  final bool colorMode;

  @override
  ConsumerState<MemoryGame> createState() => _MemoryGameState();
}

class _MemoryGameState extends ConsumerState<MemoryGame> {
  static const _icons = [
    (Icons.favorite_border_rounded, Color(0xFF2B6B73)),
    (Icons.music_note_rounded, Color(0xFF5B7DB1)),
    (Icons.cloud_outlined, Color(0xFF3E8E9B)),
    (Icons.wb_sunny_outlined, Color(0xFFB9813A)),
    (Icons.nights_stay_outlined, Color(0xFF4B5A7A)),
    (Icons.star_outline_rounded, Color(0xFF8A7458)),
  ];

  static const _colors = [
    Color(0xFF2B6B73), Color(0xFF5B7DB1), Color(0xFFC98A3A),
    Color(0xFF6B7F5E), Color(0xFFA0603F), Color(0xFF7A6A9A),
  ];

  late List<int> _cards;
  final _open = <int>{};
  final _matched = <int>{};
  int _moves = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _shuffle();
  }

  void _shuffle() {
    _cards = [for (var i = 0; i < _icons.length; i++) ...[i, i]]..shuffle(Random());
    _open.clear();
    _matched.clear();
    _moves = 0;
    _busy = false;
  }

  Future<void> _tap(int i) async {
    if (_busy || _matched.contains(i) || _open.contains(i)) return;
    HapticFeedback.selectionClick();
    setState(() => _open.add(i));
    if (_open.length < 2) return;
    _moves++;
    final [a, b] = _open.toList();
    if (_cards[a] == _cards[b]) {
      setState(() {
        _matched.addAll(_open);
        _open.clear();
      });
      if (_matched.length == _cards.length) {
        ref.read(analyticsProvider).gameFinished(widget.colorMode ? 'colors' : 'memory', _moves);
      }
      return;
    }
    _busy = true;
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      _open.clear();
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final done = _matched.length == _cards.length;

    return Scaffold(
      appBar: AppBar(title: Text(widget.colorMode ? context.l10n.gameColors : context.l10n.gameMemory)),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          children: [
            Row(children: [
              Expanded(child: Text('Eşleşen çiftleri bul. Kendi hızında.', style: t.bodyMedium)),
              Chip(label: Text('$_moves hamle')),
            ]),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.85),
                itemCount: _cards.length,
                itemBuilder: (context, i) {
                  final faceUp = _open.contains(i) || _matched.contains(i);
                  final (icon, iconColor) = _icons[_cards[i]];
                  final color = widget.colorMode ? _colors[_cards[i]] : iconColor;
                  final back = Theme.of(context).colorScheme.primary;
                  return GestureDetector(
                    onTap: () => _tap(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      decoration: BoxDecoration(
                        color: faceUp ? color.withValues(alpha: widget.colorMode ? 0.9 : 0.14) : back,
                        borderRadius: BorderRadius.circular(18),
                        border: _matched.contains(i) ? Border.all(color: color, width: 2) : null,
                      ),
                      child: Center(
                        child: faceUp
                            ? (widget.colorMode
                                ? const Icon(Icons.circle_outlined, size: 34, color: Colors.white70)
                                : Icon(icon, size: 40, color: color))
                            : Icon(Icons.shield_outlined, size: 28, color: Colors.white.withValues(alpha: 0.35)),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (done) ...[
              Text('Hepsini buldun! $_moves hamlede. Zihnine güzel bir mola verdin.',
                  textAlign: TextAlign.center, style: t.titleMedium?.copyWith(color: scheme.primary)),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => setState(_shuffle),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Yeniden oyna'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
