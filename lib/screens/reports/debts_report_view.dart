import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/report_data.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/ranked_bars.dart';
import '../../widgets/report_widgets.dart';
import '../../widgets/statistic_card.dart';

/// Debts report, shared by customers (what they owe us) and suppliers (what
/// we owe them). Shows the current balances, not filtered by a period.
class DebtsReportView extends StatelessWidget {
  const DebtsReportView({
    super.key,
    required this.report,
    required this.forCustomers,
  });

  final DebtsReport report;
  final bool forCustomers;

  @override
  Widget build(BuildContext context) {
    if (report.isEmpty) {
      return SizedBox(
        height: 320,
        child: EmptyState(
          icon: Icons.check_circle_outline_rounded,
          title: forCustomers
              ? 'لا توجد ديون على الحرفاء'
              : 'لا توجد ديون للموردين',
          message: 'كل الحسابات مسددة',
        ),
      );
    }

    final color = forCustomers ? AppColors.success : AppColors.danger;

    return Column(
      children: [
        ReportNote(
          text: forCustomers
              ? 'يعرض هذا التقرير ما بقي على الحرفاء حاليًا بعد خصم دفعاتهم، '
                  'ولا يتأثر بالفترة المختارة.'
              : 'يعرض هذا التقرير ما بقي علينا للموردين حاليًا بعد خصم دفعاتنا، '
                  'ولا يتأثر بالفترة المختارة.',
        ),
        const SizedBox(height: 16),
        StatGrid(cards: [
          StatisticCard(
            label: forCustomers ? 'إجمالي ديون الحرفاء' : 'إجمالي ديون الموردين',
            value: CurrencyFormatter.format(report.total),
            icon: forCustomers
                ? Icons.call_received_rounded
                : Icons.call_made_rounded,
            color: color,
          ),
          StatisticCard(
            label: forCustomers ? 'الحرفاء المدينون' : 'الموردون الدائنون',
            value: '${report.count}',
            icon: Icons.people_alt_outlined,
            color: AppColors.info,
          ),
        ]),
        const SizedBox(height: 16),
        ReportCard(
          title: forCustomers ? 'الحرفاء حسب قيمة الدين' : 'الموردون حسب قيمة الدين',
          subtitle: 'اضغط على الاسم لعرض التفاصيل',
          child: RankedBars(
            items: report.items,
            color: color,
            onTap: (item) => Navigator.pushNamed(
              context,
              forCustomers
                  ? AppRoutes.customerDetails
                  : AppRoutes.supplierDetails,
              arguments: item.id,
            ),
          ),
        ),
      ],
    );
  }
}
