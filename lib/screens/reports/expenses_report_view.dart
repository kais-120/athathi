import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../models/report_data.dart';
import '../../repositories/reports_repository.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/bar_chart.dart';
import '../../widgets/bucket_table.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/ranked_bars.dart';
import '../../widgets/report_widgets.dart';
import '../../widgets/statistic_card.dart';

/// تقرير المصاريف.
class ExpensesReportView extends StatelessWidget {
  const ExpensesReportView(
      {super.key, required this.reports, required this.range});

  final ReportsRepository reports;
  final DateTimeRange range;

  @override
  Widget build(BuildContext context) {
    final r = reports.expensesReport(range);
    if (r.isEmpty) {
      return const SizedBox(
        height: 320,
        child: EmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'لا توجد مصاريف في هذه الفترة',
        ),
      );
    }

    final biggest = r.byCategory.first;
    final categories = [
      for (final c in r.byCategory)
        RankedItem(
          name: c.name,
          value: c.value,
          note: '${c.note} • ${(c.value / r.total * 100).toStringAsFixed(1)}%',
        ),
    ];

    return Column(
      children: [
        StatGrid(cards: [
          StatisticCard(
            label: 'إجمالي المصاريف',
            value: CurrencyFormatter.format(r.total),
            icon: Icons.receipt_long_outlined,
            color: AppColors.danger,
          ),
          StatisticCard(
            label: 'عدد المصاريف',
            value: '${r.count}',
            icon: Icons.format_list_numbered_rounded,
            color: AppColors.info,
          ),
          StatisticCard(
            label: 'متوسط المصروف',
            value: CurrencyFormatter.format(r.average),
            icon: Icons.calculate_outlined,
            color: AppColors.warning,
          ),
          StatisticCard(
            label: 'أكبر تصنيف',
            value: biggest.name,
            icon: Icons.category_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
        ]),
        const SizedBox(height: 16),
        BarChartCard(
          title: 'المصاريف حسب الفترة (د.ت)',
          labels: [for (final b in r.buckets) b.label],
          series: [
            BarSeries(name: 'المصاريف', color: AppColors.danger, values: r.totals),
          ],
        ),
        const SizedBox(height: 16),
        ReportCard(
          title: 'المصاريف حسب التصنيف',
          child: RankedBars(items: categories, color: AppColors.danger),
        ),
        const SizedBox(height: 16),
        BucketTable(
          title: 'تفصيل المصاريف',
          buckets: r.buckets,
          columns: [
            BarSeries(name: 'المصاريف', color: AppColors.danger, values: r.totals),
          ],
        ),
      ],
    );
  }
}
