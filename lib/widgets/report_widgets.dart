import 'package:flutter/material.dart';

import '../app/theme.dart';
import 'statistic_card.dart';

/// [StatisticCard]s laid out two per row.
class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.cards});

  final List<StatisticCard> cards;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < cards.length; i += 2)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cards[i]),
                const SizedBox(width: 12),
                Expanded(
                  child: i + 1 < cards.length
                      ? cards[i + 1]
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// White card with a title (and optional subtitle) above [child].
class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// Small tinted information / warning box.
class ReportNote extends StatelessWidget {
  const ReportNote({
    super.key,
    required this.text,
    this.icon = Icons.info_outline_rounded,
    this.color = AppColors.info,
  });

  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: theme.textTheme.bodySmall?.copyWith(height: 1.6)),
          ),
        ],
      ),
    );
  }
}
