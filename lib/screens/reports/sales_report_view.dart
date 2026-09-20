import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/enums.dart';
import '../../models/report_data.dart';
import '../../repositories/reports_repository.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/bar_chart.dart';
import '../../widgets/bucket_table.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/ranked_bars.dart';
import '../../widgets/report_widgets.dart';
import '../../widgets/statistic_card.dart';

/// تقرير المبيعات.
class SalesReportView extends StatelessWidget {
  const SalesReportView({super.key, required this.reports, required this.range});

  final ReportsRepository reports;
  final DateTimeRange range;

  @override
  Widget build(BuildContext context) {
    final r = reports.salesReport(range);
    if (r.isEmpty) {
      return const SizedBox(
        height: 320,
        child: EmptyState(
          icon: Icons.point_of_sale_rounded,
          title: 'لا توجد مبيعات في هذه الفترة',
        ),
      );
    }

    final primary = Theme.of(context).colorScheme.primary;
    final methods = [
      for (final m in PaymentMethod.values)
        if (r.byMethod[m]!.count > 0)
          RankedItem(
            name: m.label,
            value: r.byMethod[m]!.total,
            note: '${r.byMethod[m]!.count} عملية',
          ),
    ];

    return Column(
      children: [
        StatGrid(cards: [
          StatisticCard(
            label: 'إجمالي المبيعات',
            value: CurrencyFormatter.format(r.total),
            icon: Icons.payments_outlined,
            color: AppColors.success,
          ),
          StatisticCard(
            label: 'عدد العمليات',
            value: '${r.count}',
            icon: Icons.receipt_long_outlined,
            color: AppColors.info,
          ),
          StatisticCard(
            label: 'متوسط الفاتورة',
            value: CurrencyFormatter.format(r.average),
            icon: Icons.calculate_outlined,
            color: primary,
          ),
          StatisticCard(
            label: 'القطع المباعة',
            value: '${r.pieces}',
            icon: Icons.chair_alt_outlined,
            color: AppColors.lightGreen,
          ),
          StatisticCard(
            label: 'المحصّل عند البيع',
            value: CurrencyFormatter.format(r.collected),
            icon: Icons.download_done_rounded,
            color: AppColors.success,
          ),
          StatisticCard(
            label: 'المتبقي عند البيع',
            value: CurrencyFormatter.format(r.remaining),
            icon: Icons.hourglass_bottom_rounded,
            color: AppColors.warning,
          ),
        ]),
        const SizedBox(height: 16),
        BarChartCard(
          title: 'المبيعات حسب الفترة (د.ت)',
          labels: [for (final b in r.buckets) b.label],
          series: [
            BarSeries(name: 'المبيعات', color: primary, values: r.totals),
          ],
        ),
        const SizedBox(height: 16),
        ReportCard(
          title: 'حسب طريقة الدفع',
          child: RankedBars(items: methods, color: AppColors.info),
        ),
        const SizedBox(height: 16),
        ReportCard(
          title: 'أكثر المنتجات مبيعًا',
          subtitle: 'حسب قيمة المبيعات',
          child: RankedBars(
            items: r.topProducts,
            color: primary,
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
          title: 'تفصيل المبيعات',
          buckets: r.buckets,
          columns: [
            BarSeries(name: 'المبيعات', color: primary, values: r.totals),
          ],
        ),
      ],
    );
  }
}
