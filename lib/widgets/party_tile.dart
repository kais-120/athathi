import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../utils/currency_formatter.dart';
import 'status_badge.dart';

/// Supplier row: avatar, name, phone and what the shop owes him.
/// ([debt] is what the shop owes; 0 shows "لا يوجد دين".)
class PartyTile extends StatelessWidget {
  const PartyTile({
    super.key,
    required this.name,
    required this.phone,
    required this.debt,
    this.debtPrefix = 'عليه',
    this.onTap,
  });

  final String name;
  final String phone;
  final double debt;
  final String debtPrefix;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.primary,
                child: Text(
                  name.isEmpty ? '?' : name.characters.first,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (phone.isNotEmpty)
                      Text(
                        phone,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              debt > 0
                  ? StatusBadge(
                      label: '$debtPrefix: ${CurrencyFormatter.format(debt)}',
                      color: AppColors.warning,
                    )
                  : const StatusBadge(
                      label: 'لا يوجد دين',
                      color: AppColors.success,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
