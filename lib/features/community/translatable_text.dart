import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/moderation/content_moderator.dart';
import '../../data/services/post_translator.dart';
import '../../l10n/tx.dart';
import '../../providers.dart';

/// Bir paylaşım ya da yanıt metni: okuyana göre tetikleyici ifadeler gizlenir
/// ve metin okuyanın dilinden farklı bir dildeyse "Çevir" düğmesi çıkar.
/// Çeviri cihaz üstünde yapılır (PostTranslator); çeviriye de aynı gizleme uygulanır.
class TranslatableText extends ConsumerStatefulWidget {
  const TranslatableText({super.key, required this.text, required this.lang, this.style});

  final String text;

  /// Metnin yazıldığı dil ('tr', 'en', …).
  final String lang;
  final TextStyle? style;

  @override
  ConsumerState<TranslatableText> createState() => _TranslatableTextState();
}

class _TranslatableTextState extends ConsumerState<TranslatableText> {
  String? _translated;
  bool _loading = false;
  bool _failed = false;

  Future<void> _translate() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final out = await PostTranslator.translate(widget.text, from: widget.lang, to: Tx.code);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _translated = out;
      _failed = out == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final readerCats = ref.watch(readerCategoriesProvider);
    final shown = ContentModerator.maskFor(_translated ?? widget.text, readerCats);
    final canTranslate = PostTranslator.supports(widget.lang, Tx.code);
    final scheme = Theme.of(context).colorScheme;
    final small = Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.primary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(shown.text, style: widget.style),
        if (shown.hidden > 0) const HiddenWordsNote(),
        if (canTranslate)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: _loading
                ? Row(
                    children: [
                      const SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                      const SizedBox(width: 8),
                      Text(tx('Çevriliyor… (ilk seferde dil modeli indirilir)'), style: small),
                    ],
                  )
                : InkWell(
                    onTap: _translated == null ? _translate : () => setState(() => _translated = null),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.translate_rounded, size: 15, color: scheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            _translated == null
                                ? (_failed ? tx('Çeviri şu an yapılamadı. Tekrar dene') : tx('Çevir'))
                                : tx('Orijinalini göster'),
                            style: small,
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
      ],
    );
  }
}

/// "Senin için gizlendi" notu: okuyanı koruyan gizlemenin açıklaması.
class HiddenWordsNote extends StatelessWidget {
  const HiddenWordsNote({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, size: 14, color: scheme.outline),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              tx('Senin için hassas olabilecek ifadeler gizlendi.'),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.outline),
            ),
          ),
        ],
      ),
    );
  }
}
