import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/report_data.dart';
import '../utils/currency_formatter.dart';

/// Horizontal bars, one row per item (name, value, note and a bar sized
/// against the biggest value). Rows with an id are tappable when [onTap] is
/// given.
class RankedBars extends StatelessWidget {
  const RankedBars({
    super.key,
    required this.items,
    required this.color,
    this.onTap,
  });

  final List<RankedItem> items;
  final Color color;
  final void Function(RankedItem item)? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    var maxValue = 0.0;
    for (final item in items) {
      if (item.value.abs() > maxValue) maxValue = item.value.abs();
    }

    return Column(
      children: [
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 6),
            child: _row(context, theme, items[i], maxValue),
          ),
      ],
    );
  }

  Widget _row(
      BuildContext context, ThemeData theme, RankedItem item, double maxValue) {
    final negative = item.value < 0;
    final barColor = negative ? AppColors.danger : color;
    final fraction = maxValue <= 0 ? 0.0 : item.value.abs() / maxValue;

    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                CurrencyFormatter.format(item.value),
                style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: negative ? AppColors.danger : null),
              ),
            ],
          ),
          if (item.note.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(item.note,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              color: barColor,
              backgroundColor: barColor.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );

    final tap = onTap;
    if (tap == null || item.id == null) return content;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => tap(item),
      child: content,
    );
  }
}
