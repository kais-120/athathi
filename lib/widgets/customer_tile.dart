import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/customer.dart';
import '../utils/currency_formatter.dart';
import 'status_badge.dart';

/// Customer row: avatar, name, phone and the debt badge.
class CustomerTile extends StatelessWidget {
  const CustomerTile({
    super.key,
    required this.customer,
    required this.debt,
    this.onTap,
  });

  final Customer customer;
  final double debt;
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
                  customer.name.isEmpty ? '?' : customer.name.characters.first,
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
                      customer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (customer.phone.isNotEmpty)
                      Text(
                        customer.phone,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              debt > 0
                  ? StatusBadge(
                      label: 'عليه: ${CurrencyFormatter.format(debt)}',
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
