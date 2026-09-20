import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/enums.dart';

/// Small rounded colored badge (condition, stock status, payment method...).
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  factory StatusBadge.condition(ProductCondition condition) => StatusBadge(
        label: condition.label,
        color: switch (condition) {
          ProductCondition.excellent => AppColors.success,
          ProductCondition.veryGood => AppColors.lightGreen,
          ProductCondition.good => AppColors.info,
          ProductCondition.acceptable => AppColors.warning,
          ProductCondition.needsRepair => AppColors.danger,
        },
      );

  factory StatusBadge.stock(StockStatus status) => StatusBadge(
        label: status.label,
        color: switch (status) {
          StockStatus.inStock => AppColors.success,
          StockStatus.low => AppColors.warning,
          StockStatus.out => AppColors.danger,
        },
        icon: switch (status) {
          StockStatus.inStock => Icons.check_circle_outline,
          StockStatus.low => Icons.warning_amber_rounded,
          StockStatus.out => Icons.remove_circle_outline,
        },
      );

  factory StatusBadge.payment(PaymentMethod method) => StatusBadge(
        label: method.label,
        color: switch (method) {
          PaymentMethod.cash => AppColors.success,
          PaymentMethod.credit => AppColors.warning,
        },
      );

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
