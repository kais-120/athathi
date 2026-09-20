import 'package:flutter/material.dart';

import '../models/product.dart';
import '../utils/currency_formatter.dart';
import 'product_image.dart';
import 'status_badge.dart';

/// Product summary card.
///
/// * `compact: true` (dashboard low-stock list): image, name, quantity and
///   stock badge only.
/// * Otherwise it shows category, condition, price, quantity and — when the
///   callbacks are provided — the عرض / تعديل / حذف actions.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.compact = false,
    this.lowStockThreshold = 3,
    this.categoryName = '',
    this.onTap,
    this.onView,
    this.onEdit,
    this.onDelete,
  });

  final Product product;
  final bool compact;
  final int lowStockThreshold;

  /// Name of the product's category (shown when not compact).
  final String categoryName;
  final VoidCallback? onTap;
  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = product.stockStatus(lowStockThreshold);
    final hasActions =
        !compact && (onView != null || onEdit != null || onDelete != null);

    final quantityText = Text(
      'الكمية: ${product.quantity}',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ?? onView,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProductImage(
                    fileName: product.mainImage,
                    size: compact ? 56 : 84,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (compact) ...[
                          const SizedBox(height: 4),
                          quantityText,
                        ] else ...[
                          const SizedBox(height: 2),
                          Text(
                            categoryName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              StatusBadge.condition(product.condition),
                              StatusBadge.stock(status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  CurrencyFormatter.format(
                                      product.sellingPrice),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              quantityText,
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (compact) ...[
                    const SizedBox(width: 8),
                    StatusBadge.stock(status),
                  ],
                ],
              ),
              if (hasActions) ...[
                const SizedBox(height: 8),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onView != null)
                      TextButton.icon(
                        onPressed: onView,
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        label: const Text('عرض'),
                      ),
                    if (onEdit != null)
                      TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('تعديل'),
                      ),
                    if (onDelete != null)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                        ),
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('حذف'),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
