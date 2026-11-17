import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

/// Sevimli hayvan avatarı (gerçek fotoğraf yok: toplulukta anonimlik ve güvenlik).
class AvatarBadge extends StatelessWidget {
  const AvatarBadge({super.key, required this.index, this.radius = 22, this.locked = false});

  final int index;
  final double radius;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final a = avatarAt(index);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Stack(clipBehavior: Clip.none, children: [
      CircleAvatar(
        radius: radius,
        backgroundColor: a.color.withValues(alpha: dark ? 0.35 : 0.16),
        child: Opacity(
          opacity: locked ? 0.35 : 1,
          child: Text(a.emoji, style: TextStyle(fontSize: radius * 1.05, height: 1.1)),
        ),
      ),
      if (locked)
        Positioned(
          right: -2,
          bottom: -2,
          child: CircleAvatar(
            radius: radius * 0.36,
            backgroundColor: Theme.of(context).colorScheme.surface,
            child: Icon(Icons.lock_rounded, size: radius * 0.42),
          ),
        ),
    ]);
  }
}

/// Duolingo tarzı seri rozeti: alev + gün sayısı.
class StreakBadge extends StatelessWidget {
  const StreakBadge({super.key, required this.days, this.compact = true});

  final int days;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final active = days > 0;
    final color = active ? const Color(0xFFE3A64F) : Theme.of(context).colorScheme.outline;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12, vertical: compact ? 3 : 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department_rounded, size: compact ? 16 : 20, color: color),
          const SizedBox(width: 3),
          Text('$days',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: color, fontSize: compact ? 13 : 15)),
        ],
      ),
    );
  }
}

/// Bölüm başlığı.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
