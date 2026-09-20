import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/purchase.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';

/// Purchase summary card: supplier, date, pieces, total and unpaid rest.
class PurchaseTile extends StatelessWidget {
  const PurchaseTile({super.key, required this.purchase, this.onTap});

  final Purchase purchase;
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
                  Icon(Icons.shopping_bag_outlined,
                      size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      purchase.displaySupplier,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text('${purchase.pieces} قطعة', style: muted),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      CurrencyFormatter.format(purchase.total),
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(DateFormatter.dateTime(purchase.createdAt), style: muted),
                ],
              ),
              if (purchase.remaining > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'المتبقي للمورد: ${CurrencyFormatter.format(purchase.remaining)}',
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
