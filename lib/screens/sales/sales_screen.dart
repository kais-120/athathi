import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../app/routes.dart';
import '../../models/enums.dart';
import '../../models/sale.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/sale_tile.dart';
import '../../widgets/search_field.dart';

/// Sales history + entry point of the POS ("بيع جديد").
class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  late final AppServices _services;
  String _query = '';
  PaymentMethod? _method;

  @override
  void initState() {
    super.initState();
    _services = AppScope.of(context);
  }

  void _newSale() => Navigator.pushNamed(context, AppRoutes.newSale);

  List<Sale> _apply(List<Sale> all) {
    final query = _query.trim().toLowerCase();
    return all.where((s) {
      if (_method != null && s.method != _method) return false;
      if (query.isEmpty) return true;
      return '${s.number}'.contains(query) ||
          s.displayCustomer.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المبيعات')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newSale,
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('بيع جديد'),
      ),
      body: ListenableBuilder(
        listenable: _services.sales,
        builder: (context, _) {
          final all = _services.sales.all;
          if (all.isEmpty) {
            return EmptyState(
              icon: Icons.point_of_sale_outlined,
              title: 'لا توجد عمليات بيع مسجلة',
              message: 'ابدأ أول عملية بيع من المنتجات المتوفرة في المخزون',
              actionLabel: 'بيع جديد',
              onAction: _newSale,
            );
          }

          final sales = _apply(all);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: _TodaySummary(
                  count: _services.sales.todayCount,
                  total: _services.sales.todayTotal,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SearchField(
                  hintText: 'ابحث برقم العملية أو اسم الحريف...',
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
                        selected: _method == null,
                        onSelected: (_) => setState(() => _method = null),
                      ),
                    ),
                    for (final m in PaymentMethod.values)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: ChoiceChip(
                          label: Text(m.label),
                          selected: _method == m,
                          onSelected: (_) => setState(() => _method = m),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: sales.isEmpty
                    ? const EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'لا توجد نتائج مطابقة',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                        itemCount: sales.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) => SaleTile(
                          sale: sales[i],
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.saleDetails,
                            arguments: sales[i].id,
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TodaySummary extends StatelessWidget {
  const _TodaySummary({required this.count, required this.total});

  final int count;
  final double total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget cell(String label, String value) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text(value,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            cell('مبيعات اليوم', CurrencyFormatter.format(total)),
            cell('عدد عمليات اليوم', '$count'),
          ],
        ),
      ),
    );
  }
}
