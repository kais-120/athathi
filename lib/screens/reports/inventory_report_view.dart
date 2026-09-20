import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../repositories/reports_repository.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/ranked_bars.dart';
import '../../widgets/report_widgets.dart';
import '../../widgets/statistic_card.dart';
import '../../widgets/status_badge.dart';

/// تقرير المخزون: current stock (not filtered by a period).
class InventoryReportView extends StatelessWidget {
  const InventoryReportView({super.key, required this.reports, required this.lowStockThreshold});

  final ReportsRepository reports;
  final int lowStockThreshold;

  @override
  Widget build(BuildContext context) {
    final r = reports.inventoryReport();
    if (r.isEmpty) {
      return const SizedBox(
        height: 320,
        child: EmptyState(
          icon: Icons.inventory_2_outlined,
          title: 'لا توجد منتجات في المخزون',
        ),
      );
    }

    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Column(
      children: [
        const ReportNote(
          text: 'يعرض هذا التقرير حالة المخزون الحالية ولا يتأثر بالفترة المختارة.',
        ),
        const SizedBox(height: 16),
        StatGrid(cards: [
          StatisticCard(
            label: 'عدد المنتجات',
            value: '${r.productsCount}',
            icon: Icons.category_outlined,
            color: primary,
          ),
          StatisticCard(
            label: 'القطع في المخزون',
            value: '${r.pieces}',
            icon: Icons.chair_alt_outlined,
            color: AppColors.info,
          ),
          StatisticCard(
            label: 'القيمة بسعر الشراء',
            value: CurrencyFormatter.format(r.costValue),
            icon: Icons.inventory_2_outlined,
            color: AppColors.warning,
          ),
          StatisticCard(
            label: 'القيمة بسعر البيع',
            value: CurrencyFormatter.format(r.sellingValue),
            icon: Icons.sell_outlined,
            color: AppColors.success,
          ),
          StatisticCard(
            label: 'الربح المتوقع',
            value: CurrencyFormatter.format(r.expectedProfit),
            icon: Icons.trending_up_rounded,
            color: r.expectedProfit >= 0 ? AppColors.success : AppColors.danger,
          ),
          StatisticCard(
            label: 'كمية منخفضة / نافدة',
            value: '${r.lowCount} / ${r.outCount}',
            icon: Icons.warning_amber_rounded,
            color: r.lowCount + r.outCount > 0
                ? AppColors.danger
                : AppColors.success,
          ),
        ]),
        const SizedBox(height: 16),
        if (r.byCategory.isNotEmpty)
          ReportCard(
            title: 'قيمة المخزون حسب الصنف',
            subtitle: 'بسعر الشراء',
            child: RankedBars(items: r.byCategory, color: primary),
          ),
        if (r.attention.isNotEmpty) ...[
          const SizedBox(height: 16),
          ReportCard(
            title: 'منتجات تحتاج إلى تجديد المخزون',
            subtitle: 'الكمية ≤ $lowStockThreshold',
            child: Column(
              children: [
                for (var i = 0; i < r.attention.length; i++) ...[
                  if (i > 0) const Divider(),
                  InkWell(
                    onTap: () => Navigator.pushNamed(
                        context, AppRoutes.productDetails,
                        arguments: r.attention[i].id),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              r.attention[i].name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${r.attention[i].quantity} قطعة',
                              style: theme.textTheme.bodySmall),
                          const SizedBox(width: 8),
                          StatusBadge.stock(
                              r.attention[i].stockStatus(lowStockThreshold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
