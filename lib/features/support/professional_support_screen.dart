import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/country_support.dart';
import '../../providers.dart';
import 'support_lines_card.dart';
import '../../l10n/tx.dart';
import '../../core/theme/app_theme.dart';

/// "Destek al": kriz hatları + profesyonel desteğe nasıl ulaşılır (Türkiye).
/// Haven kullanıcılarının bir kısmı profesyonel desteğe ihtiyaç duyabilir;
/// bu ekran uygulamanın her yerinden en fazla iki dokunuş uzaklıkta.
class ProfessionalSupportScreen extends ConsumerStatefulWidget {
  const ProfessionalSupportScreen({super.key});

  @override
  ConsumerState<ProfessionalSupportScreen> createState() => _ProfessionalSupportScreenState();
}

class _ProfessionalSupportScreenState extends ConsumerState<ProfessionalSupportScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(analyticsProvider).professionalSupportOpened();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(tx('Destek al'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            tx(
              'Yardım istemek bir zayıflık değil; kendine verdiğin en güçlü sözlerden biri. Haven bir yol arkadaşıdır, ama bir uzmanın yerini tutmaz.',
            ),
            style: t.bodyLarge,
          ),
          const SizedBox(height: 16),
          const SupportLinesCard(),
          const SizedBox(height: 20),
          Text(tx('Profesyonel destek nasıl alınır?'), style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          for (final r in ref.watch(countryProvider).isTurkey ? kHelpResources : kHelpResourcesGlobal)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: HavenCard(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: CircleAvatar(
                    backgroundColor: scheme.primaryContainer,
                    child: Icon(r.icon, color: scheme.primary),
                  ),
                  title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(r.description),
                ),
              ),
            ),
          const SizedBox(height: 12),
          HavenCard(
            color: scheme.primaryContainer.withValues(alpha: 0.5),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tx('İlk görüşmeye hazırlık'), style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(
                    tx(
                      '• Ne zamandır zorlandığını ve en çok neyin zorladığını not al.\n• Haven\'daki ay takviminden zor günlerinin sıklığını gösterebilirsin.\n• Soracağın soruları önceden yaz; her şeyi tek seferde anlatmak zorunda değilsin.',
                    ),
                    style: t.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
