import 'package:flutter/material.dart';

import '../../core/constants/struggle_catalog.dart';
import '../../core/theme/app_theme.dart';

/// Kategori kartları içinde seçilebilir alanlar. Kayıtta ve düzenlemede ortak.
class StruggleSelector extends StatelessWidget {
  const StruggleSelector({super.key, required this.selected, required this.onToggle});

  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final c in StruggleCategory.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _CategoryCard(category: c, selected: selected, onToggle: onToggle),
          ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.selected, required this.onToggle});

  final StruggleCategory category;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final accent = categoryAccent(category);
    final anySelected = typesOf(category).any((t) => selected.contains(t.id));
    return Card(
      color: categoryCardColor(category, scheme),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
            color: anySelected ? accent.withValues(alpha: 0.6) : Colors.transparent, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CategoryIcon(category: category),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category.title,
                          style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                      Text(category.subtitle, style: text.bodySmall),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Bu alan hakkında',
                  icon: Icon(Icons.info_outline_rounded, color: accent),
                  onPressed: () => showCategoryInfo(context, category),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in typesOf(category))
                  FilterChip(
                    label: Text(t.label),
                    selected: selected.contains(t.id),
                    selectedColor: accent.withValues(alpha: 0.18),
                    checkmarkColor: accent,
                    onSelected: (_) => onToggle(t.id),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryIcon extends StatelessWidget {
  const CategoryIcon({super.key, required this.category, this.size = 40});

  final StruggleCategory category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final accent = categoryAccent(category);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(category.icon, color: accent, size: size * 0.55),
    );
  }
}

/// Kanıta dayalı kısa bilgi + kaynak.
Future<void> showCategoryInfo(BuildContext context, StruggleCategory c) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      final text = Theme.of(ctx).textTheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                CategoryIcon(category: c, size: 44),
                const SizedBox(width: 12),
                Expanded(child: Text(c.title, style: text.titleLarge)),
              ]),
              const SizedBox(height: 16),
              Text(c.info, style: text.bodyLarge),
              if (c.fact != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: categoryAccent(c).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(children: [
                    Icon(Icons.public_rounded, color: categoryAccent(c)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(c.fact!, style: text.bodyMedium)),
                  ]),
                ),
              ],
              if (c.source != null) ...[
                const SizedBox(height: 10),
                Text('Kaynak: ${c.source}', style: text.bodySmall),
              ],
              const SizedBox(height: 10),
              Text('Bu bilgiler tanı koymak için değildir.', style: text.bodySmall),
            ],
          ),
        ),
      );
    },
  );
}
