import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/country_support.dart';
import '../../l10n/tx.dart';
import '../../providers.dart';

Future<void> callSupportLine(String number) async {
  try {
    await launchUrl(Uri(scheme: 'tel', path: number));
  } catch (e) {
    debugPrint('Arama başlatılamadı: $e');
  }
}

Future<void> openHelplineDirectory() async {
  try {
    await launchUrl(Uri.parse(kFindAHelplineUrl), mode: LaunchMode.externalApplication);
  } catch (e) {
    debugPrint('Rehber açılamadı: $e');
  }
}

/// Bulunduğun ülkenin acil ve destek hatları. Ülke telefondan tahmin edilir;
/// kullanıcı değiştirebilir (hesabında saklanır).
class SupportLinesCard extends ConsumerWidget {
  const SupportLinesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final country = ref.watch(countryProvider);
    final uid = ref.watch(uidProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(child: Text(tx('Yalnız değilsin'), style: text.titleMedium)),
                  PopupMenuButton<String>(
                    tooltip: tx('Ülke'),
                    onSelected: (code) {
                      if (uid != null) ref.read(repositoryProvider).setCountry(uid, code);
                    },
                    itemBuilder: (_) => [
                      for (final c in kCountrySupport)
                        CheckedPopupMenuItem(value: c.code, checked: c.code == country.code, child: Text(c.name)),
                    ],
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.public_rounded, size: 18),
                        const SizedBox(width: 4),
                        Text(country.name, style: text.labelLarge),
                        const Icon(Icons.arrow_drop_down_rounded),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            for (final line in country.allLines)
              ListTile(
                onTap: () => callSupportLine(line.number),
                leading: CircleAvatar(
                  radius: 26,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: FittedBox(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Text(line.number, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
                title: Text(line.name),
                subtitle: Text(line.description),
                trailing: Icon(Icons.call_outlined, color: Theme.of(context).colorScheme.primary),
              ),
            ListTile(
              onTap: openHelplineDirectory,
              leading: const CircleAvatar(radius: 26, child: Icon(Icons.travel_explore_rounded)),
              title: Text(tx('Dünya genelinde yardım hatları')),
              subtitle: Text(
                tx('findahelpline.com üzerinden ülkendeki ücretsiz ve gizli destek hatlarını bulabilirsin.'),
              ),
              trailing: const Icon(Icons.open_in_new_rounded),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                tx('Haven bir tedavi aracı değildir; profesyonel desteğin yerini tutmaz.'),
                style: text.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
