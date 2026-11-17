import 'package:flutter/material.dart';

import '../../core/constants/struggle_catalog.dart';
import '../../core/navigation.dart';
import '../../core/theme/app_theme.dart';
import 'calm_screen.dart';
import 'professional_support_screen.dart';
import 'support_lines_card.dart';

/// "Zordu" check-in'inden sonra açılan şefkatli alt sayfa.
/// Seriden, sıfırlanmadan, kayıptan hiç bahsetmez. REKLAM YOK.
Future<void> showHardDaySheet(BuildContext context, StruggleCategory category, {int endedStreak = 0}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      final text = Theme.of(sheetContext).textTheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.favorite_rounded, size: 40, color: HavenColors.clay),
              const SizedBox(height: 12),
              Text(category.hardDayMessage, textAlign: TextAlign.center, style: text.titleMedium),
              const SizedBox(height: 8),
              Text(
                  endedStreak > 0
                      ? '$endedStreak günlük güzel bir seri yaptın ve o emek hâlâ seninle. Bu sadece küçük bir tümsek; '
                          'yarın bu rekorla birlikte yarışırız.'
                      : 'Topladığın iyi günler hiçbir yere gitmez; hepsi hâlâ seninle.',
                  textAlign: TextAlign.center,
                  style: text.bodyMedium),
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: const Icon(Icons.air_rounded),
                label: const Text('Birlikte nefes alalım'),
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  pushScreen(context, 'calm', CalmScreen(category: category));
                },
              ),
              const SizedBox(height: 10),
              if (category == StruggleCategory.selfHarm)
                OutlinedButton.icon(
                  icon: const Icon(Icons.phone_in_talk_outlined),
                  label: const Text('Güvende değilsen: 112'),
                  onPressed: () => callSupportLine('112'),
                )
              else
                OutlinedButton.icon(
                  icon: const Icon(Icons.volunteer_activism_outlined),
                  label: const Text('Profesyonel destek seçenekleri'),
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    pushScreen(context, 'professional_support', const ProfessionalSupportScreen());
                  },
                ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: const Text('Şimdilik kapat'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Toplulukta kriz belirtisi taşıyan bir not yazıldığında: not paylaşılmaz,
/// bunun yerine bu destek paneli açılır.
Future<void> showCrisisSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      final text = Theme.of(ctx).textTheme;
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.favorite_rounded, size: 40, color: HavenColors.clay),
              const SizedBox(height: 12),
              Text('Şu an çok zorlandığını görüyoruz',
                  textAlign: TextAlign.center, style: text.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Hissettiklerin önemli ve bu yükü yalnız taşımak zorunda değilsin. '
                'Şu an güvende değilsen lütfen hemen 112\'yi ara. Konuşmak, ilk adımdır.',
                textAlign: TextAlign.center,
                style: text.bodyLarge,
              ),
              const SizedBox(height: 16),
              const SupportLinesCard(),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  pushScreen(context, 'calm', const CalmScreen(category: StruggleCategory.selfHarm));
                },
                child: const Text('Birlikte nefes alalım'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
