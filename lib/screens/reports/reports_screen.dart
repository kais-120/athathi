import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../utils/report_period.dart';
import 'debts_report_view.dart';
import 'expenses_report_view.dart';
import 'inventory_report_view.dart';
import 'profit_report_view.dart';
import 'purchases_report_view.dart';
import 'sales_report_view.dart';

enum _ReportType {
  sales('المبيعات', true),
  profit('الأرباح', true),
  purchases('المشتريات', true),
  expenses('المصاريف', true),
  inventory('المخزون', false),
  customerDebts('ديون الحرفاء', false),
  supplierDebts('ديون الموردين', false);

  const _ReportType(this.label, this.usesPeriod);

  final String label;

  /// Inventory and debts show the current situation, so the period filter is
  /// hidden for them.
  final bool usesPeriod;
}

/// التقارير: sales, profit, purchases, expenses, inventory and debts, with a
/// period filter (today / this week / this month / custom range).
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late final AppServices _services;
  _ReportType _type = _ReportType.sales;
  ReportPeriod _period = const ReportPeriod(ReportRange.month);

  @override
  void initState() {
    super.initState();
    _services = AppScope.of(context);
  }

  Future<void> _selectRange(ReportRange kind) async {
    if (kind != ReportRange.custom) {
      setState(() => _period = ReportPeriod(kind));
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current =
        _period.kind == ReportRange.custom ? _period.displayRange() : null;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: today,
      initialDateRange: current ??
          DateTimeRange(start: DateTime(today.year, today.month, 1), end: today),
      helpText: 'اختر الفترة',
      saveText: 'تأكيد',
    );
    if (picked == null || !mounted) return;
    setState(() => _period = ReportPeriod.custom(picked));
  }

  Widget _chips<T>({
    required List<T> values,
    required String Function(T) labelOf,
    required bool Function(T) isSelected,
    required void Function(T) onSelected,
  }) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final v in values)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(
                label: Text(labelOf(v)),
                selected: isSelected(v),
                onSelected: (_) => onSelected(v),
              ),
            ),
        ],
      ),
    );
  }

  Widget _content() {
    final range = _period.range();
    final reports = _services.reports;
    return switch (_type) {
      _ReportType.sales => SalesReportView(reports: reports, range: range),
      _ReportType.profit => ProfitReportView(reports: reports, range: range),
      _ReportType.purchases =>
        PurchasesReportView(reports: reports, range: range),
      _ReportType.expenses =>
        ExpensesReportView(reports: reports, range: range),
      _ReportType.inventory => InventoryReportView(
          reports: reports,
          lowStockThreshold: _services.settings.current.lowStockThreshold,
        ),
      _ReportType.customerDebts =>
        DebtsReportView(report: reports.customerDebts(), forCustomers: true),
      _ReportType.supplierDebts =>
        DebtsReportView(report: reports.supplierDebts(), forCustomers: false),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('التقارير')),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          _services.sales,
          _services.purchases,
          _services.expenses,
          _services.products,
          _services.customers,
          _services.suppliers,
          _services.payments,
          _services.supplierPayments,
          _services.settings,
        ]),
        builder: (context, _) {
          return Column(
            children: [
              _chips<_ReportType>(
                values: _ReportType.values,
                labelOf: (t) => t.label,
                isSelected: (t) => t == _type,
                onSelected: (t) => setState(() => _type = t),
              ),
              if (_type.usesPeriod) ...[
                _chips<ReportRange>(
                  values: ReportRange.values,
                  labelOf: (r) => r.label,
                  isSelected: (r) => r == _period.kind,
                  onSelected: _selectRange,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      Icon(Icons.date_range_outlined,
                          size: 18, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(
                        'الفترة: ${_period.describe()}',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
              Expanded(
                child: ListView(
                  key: ValueKey(_type),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [_content()],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
