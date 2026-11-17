import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/support_ticket.dart';

/// Talep durumunu gösteren küçük renkli etiket.
class TicketStatusChip extends StatelessWidget {
  const TicketStatusChip({super.key, required this.status, this.developer = false});

  final TicketStatus status;
  final bool developer;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (status) {
      TicketStatus.open => scheme.primary,
      TicketStatus.seen => scheme.outline,
      TicketStatus.planned => HavenColors.amber,
      TicketStatus.done => HavenColors.harbor,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            status.label(developer: developer),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
