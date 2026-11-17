import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';

Future<void> callSupportLine(String number) async {
  try {
    await launchUrl(Uri(scheme: 'tel', path: number));
  } catch (e) {
    debugPrint('Arama başlatılamadı: $e');
  }
}

class SupportLinesCard extends StatelessWidget {
  const SupportLinesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('Yalnız değilsin', style: text.titleMedium),
            ),
            const SizedBox(height: 4),
            for (final line in kSupportLines)
              ListTile(
                onTap: () => callSupportLine(line.number),
                leading: CircleAvatar(
                  radius: 26,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    line.number,
                    style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                title: Text(line.name),
                subtitle: Text(line.description),
                trailing: Icon(Icons.call_outlined,
                    color: Theme.of(context).colorScheme.primary),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Haven bir tedavi aracı değildir; profesyonel desteğin yerini tutmaz.',
                style: text.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
