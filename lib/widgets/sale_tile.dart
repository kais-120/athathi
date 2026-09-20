import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/sale.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import 'status_badge.dart';

/// Sale summary card: number, customer, amount, payment method, date and the
/// unpaid rest (if any). Used by the dashboard and the sales history.
class SaleTile extends StatelessWidget {
  const SaleTile({super.key, required this.sale, this.onTap});

  final Sale sale;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('عملية #${sale.number}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      )),
                  const Spacer(),
                  StatusBadge.payment(sale.method),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                sale.displayCustomer,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      CurrencyFormatter.format(sale.total),
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(DateFormatter.dateTime(sale.createdAt), style: muted),
                ],
              ),
              if (sale.remaining > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'المتبقي: ${CurrencyFormatter.format(sale.remaining)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
