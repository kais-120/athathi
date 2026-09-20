import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../app/routes.dart';
import '../../models/customer.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/customer_tile.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/search_field.dart';

/// Customers list: search, "with debt" filter, debt summary, add.
class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  late final AppServices _services;
  String _query = '';
  bool _onlyDebtors = false;

  @override
  void initState() {
    super.initState();
    _services = AppScope.of(context);
  }

  void _add() => Navigator.pushNamed(context, AppRoutes.customerForm);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الحرفاء')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.person_add_alt_1_outlined),
        label: const Text('إضافة حريف'),
      ),
      // Debts depend on sales and payments too.
      body: ListenableBuilder(
        listenable: Listenable.merge([
          _services.customers,
          _services.sales,
          _services.payments,
        ]),
        builder: (context, _) {
          final repo = _services.customers;
          if (repo.count == 0) {
            return EmptyState(
              icon: Icons.people_outline,
              title: 'لا يوجد حرفاء مسجلون',
              message: 'أضف حرفاءك لتتبع مشترياتهم وديونهم',
              actionLabel: 'إضافة حريف',
              onAction: _add,
            );
          }

          var customers = repo.search(_query);
          final debts = {for (final c in customers) c.id: repo.debtOf(c.id)};
          if (_onlyDebtors) {
            customers = customers.where((c) => debts[c.id]! > 0).toList()
              ..sort((a, b) => debts[b.id]!.compareTo(debts[a.id]!));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: _Summary(
                  count: repo.count,
                  debtors: repo.debtorsCount,
                  totalDebts: repo.totalDebts,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SearchField(
                  hintText: 'ابحث عن حريف...',
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: ChoiceChip(
                        label: const Text('الكل'),
                        selected: !_onlyDebtors,
                        onSelected: (_) => setState(() => _onlyDebtors = false),
                      ),
                    ),
                    ChoiceChip(
                      label: const Text('عليهم ديون'),
                      selected: _onlyDebtors,
                      onSelected: (_) => setState(() => _onlyDebtors = true),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: customers.isEmpty
                    ? EmptyState(
                        icon: _onlyDebtors
                            ? Icons.verified_outlined
                            : Icons.search_off_rounded,
                        title: _onlyDebtors && _query.isEmpty
                            ? 'لا توجد ديون على الحرفاء'
                            : 'لا توجد نتائج مطابقة',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                        itemCount: customers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final Customer c = customers[i];
                          return CustomerTile(
                            customer: c,
                            debt: debts[c.id] ?? 0,
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.customerDetails,
                              arguments: c.id,
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.count,
    required this.debtors,
    required this.totalDebts,
  });

  final int count;
  final int debtors;
  final double totalDebts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget cell(String label, String value) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(value,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            cell('عدد الحرفاء', '$count'),
            cell('عليهم ديون', '$debtors'),
            cell('إجمالي الديون', CurrencyFormatter.format(totalDebts)),
          ],
        ),
      ),
    );
  }
}
