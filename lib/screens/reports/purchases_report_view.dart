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

/// تقرير المشتريات.
class PurchasesReportView extends StatelessWidget {
  const PurchasesReportView(
      {super.key, required this.reports, required this.range});

  final ReportsRepository reports;
  final DateTimeRange range;

  @override
  Widget build(BuildContext context) {
    final r = reports.purchasesReport(range);
    if (r.isEmpty) {
      return const SizedBox(
        height: 320,
        child: EmptyState(
          icon: Icons.shopping_bag_outlined,
          title: 'لا توجد مشتريات في هذه الفترة',
        ),
      );
    }

    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        StatGrid(cards: [
          StatisticCard(
            label: 'إجمالي المشتريات',
            value: CurrencyFormatter.format(r.total),
            icon: Icons.shopping_bag_outlined,
            color: AppColors.info,
          ),
          StatisticCard(
            label: 'عدد العمليات',
            value: '${r.count}',
            icon: Icons.receipt_long_outlined,
            color: primary,
          ),
          StatisticCard(
            label: 'القطع المشتراة',
            value: '${r.pieces}',
            icon: Icons.chair_alt_outlined,
            color: AppColors.lightGreen,
          ),
          StatisticCard(
            label: 'المدفوع',
            value: CurrencyFormatter.format(r.paid),
            icon: Icons.call_made_rounded,
            color: AppColors.success,
          ),
          StatisticCard(
            label: 'المتبقي للموردين',
            value: CurrencyFormatter.format(r.remaining),
            icon: Icons.hourglass_bottom_rounded,
            color: AppColors.warning,
          ),
        ]),
        const SizedBox(height: 16),
        BarChartCard(
          title: 'المشتريات حسب الفترة (د.ت)',
          labels: [for (final b in r.buckets) b.label],
          series: [
            BarSeries(name: 'المشتريات', color: AppColors.info, values: r.totals),
          ],
        ),
        const SizedBox(height: 16),
        ReportCard(
          title: 'أهم الموردين',
          subtitle: 'حسب قيمة المشتريات',
          child: RankedBars(
            items: r.topSuppliers,
            color: AppColors.info,
            onTap: (item) {
              if (reports.supplierExists(item.id!)) {
                Navigator.pushNamed(context, AppRoutes.supplierDetails,
                    arguments: item.id);
              }
            },
          ),
        ),
        const SizedBox(height: 16),
        BucketTable(
          title: 'تفصيل المشتريات',
          buckets: r.buckets,
          columns: [
            BarSeries(name: 'المشتريات', color: AppColors.info, values: r.totals),
          ],
        ),
      ],
    );
  }
}
