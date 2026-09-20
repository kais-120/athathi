import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/account_transaction.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';

/// One ledger line: icon, title, subtitle, date and the signed amount
/// (green + for income, red − for outflow).
class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction, this.onTap});

  final AccountTransaction transaction;
  final VoidCallback? onTap;

  static IconData _icon(TransactionKind kind) => switch (kind) {
        TransactionKind.saleIncome => Icons.point_of_sale_outlined,
        TransactionKind.customerPayment => Icons.payments_outlined,
        TransactionKind.purchase => Icons.shopping_bag_outlined,
        TransactionKind.supplierPayment => Icons.local_shipping_outlined,
        TransactionKind.expense => Icons.receipt_long_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = transaction;
    final color = t.isIncome ? AppColors.success : AppColors.danger;
    final sign = t.isIncome ? '+' : '−';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                foregroundColor: color,
                child: Icon(_icon(t.kind), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (t.subtitle.isNotEmpty)
                      Text(
                        t.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    Text(
                      DateFormatter.dateTime(t.date),
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$sign ${CurrencyFormatter.format(t.amount)}',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
