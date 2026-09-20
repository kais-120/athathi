import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../repositories/reports_repository.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/bar_chart.dart';
import '../../widgets/bucket_table.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/ranked_bars.dart';
import '../../widgets/report_widgets.dart';
import '../../widgets/statistic_card.dart';

/// تقرير الأرباح: gross profit, expenses and net profit.
class ProfitReportView extends StatelessWidget {
  const ProfitReportView({super.key, required this.reports, required this.range});

  final ReportsRepository reports;
  final DateTimeRange range;

  @override
  Widget build(BuildContext context) {
    final r = reports.profitReport(range);
    if (r.isEmpty) {
      return const SizedBox(
        height: 320,
        child: EmptyState(
          icon: Icons.trending_up_rounded,
          title: 'لا توجد مبيعات أو مصاريف في هذه الفترة',
        ),
      );
    }

    final net = r.net;
    final netColor = net >= 0 ? AppColors.success : AppColors.danger;

    return Column(
      children: [
        const ReportNote(
          text: 'الربح الإجمالي = مجموع (سعر البيع − سعر التكلفة) × الكمية '
              'لمبيعات الفترة، بغض النظر عن المبلغ المحصّل.\n'
              'الربح الصافي = الربح الإجمالي − المصاريف. '
              'المشتريات لا تُخصم مباشرة: تكلفتها تدخل في الربح عند بيع القطع.',
        ),
        const SizedBox(height: 16),
        StatGrid(cards: [
          StatisticCard(
            label: 'الربح الصافي',
            value: CurrencyFormatter.format(net),
            icon: net >= 0
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
            color: netColor,
          ),
          StatisticCard(
            label: 'الربح الإجمالي',
            value: CurrencyFormatter.format(r.gross),
            icon: Icons.savings_outlined,
            color: AppColors.success,
          ),
          StatisticCard(
            label: 'المصاريف',
            value: CurrencyFormatter.format(r.expenses),
            icon: Icons.receipt_long_outlined,
            color: AppColors.danger,
          ),
          StatisticCard(
            label: 'إجمالي المبيعات',
            value: CurrencyFormatter.format(r.revenue),
            icon: Icons.payments_outlined,
            color: AppColors.info,
          ),
          StatisticCard(
            label: 'تكلفة القطع المباعة',
            value: CurrencyFormatter.format(r.costOfGoods),
            icon: Icons.inventory_2_outlined,
            color: AppColors.warning,
          ),
          StatisticCard(
            label: 'هامش الربح',
            value: '${r.margin.toStringAsFixed(1)}%',
            icon: Icons.percent_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
        ]),
        if (r.itemsWithoutCost > 0) ...[
          const SizedBox(height: 16),
          ReportNote(
            icon: Icons.warning_amber_rounded,
            color: AppColors.warning,
            text: 'يوجد ${r.itemsWithoutCost} بند مباع بدون سعر تكلفة، '
                'لذلك قد يكون الربح مبالغًا فيه. '
                'حدّد سعر الشراء في بطاقة المنتج للحصول على أرقام دقيقة.',
          ),
        ],
        const SizedBox(height: 16),
        BarChartCard(
          title: 'الربح الإجمالي والمصاريف (د.ت)',
          labels: [for (final b in r.buckets) b.label],
          series: [
            BarSeries(
                name: 'الربح الإجمالي',
                color: AppColors.success,
                values: r.grossSeries),
            BarSeries(
                name: 'المصاريف',
                color: AppColors.danger,
                values: r.expenseSeries),
          ],
        ),
        const SizedBox(height: 16),
        ReportCard(
          title: 'أكثر المنتجات ربحًا',
          subtitle: 'حسب الربح الإجمالي',
          child: r.topProducts.isEmpty
              ? const Text('لا توجد مبيعات في هذه الفترة')
              : RankedBars(
                  items: r.topProducts,
                  color: AppColors.success,
                  onTap: (item) {
                    if (reports.productExists(item.id!)) {
                      Navigator.pushNamed(context, AppRoutes.productDetails,
                          arguments: item.id);
                    }
                  },
                ),
        ),
        const SizedBox(height: 16),
        BucketTable(
          title: 'تفصيل الأرباح',
          buckets: r.buckets,
          columns: [
            BarSeries(
                name: 'الربح الإجمالي',
                color: AppColors.success,
                values: r.grossSeries),
            BarSeries(
                name: 'المصاريف',
                color: AppColors.danger,
                values: r.expenseSeries),
          ],
        ),
      ],
    );
  }
}
