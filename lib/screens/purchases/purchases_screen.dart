import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../app/routes.dart';
import '../../models/purchase.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/period.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/purchase_tile.dart';
import '../../widgets/search_field.dart';

/// Purchase history + entry point of "شراء جديد".
class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  late final AppServices _services;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _services = AppScope.of(context);
  }

  void _newPurchase() => Navigator.pushNamed(context, AppRoutes.purchaseNew);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المشتريات')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newPurchase,
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('شراء جديد'),
      ),
      body: ListenableBuilder(
        listenable: _services.purchases,
        builder: (context, _) {
          final all = _services.purchases.all;
          if (all.isEmpty) {
            return EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'لا توجد عمليات شراء مسجلة',
              message: 'سجّل ما تشتريه من أثاث لإضافته إلى المخزون',
              actionLabel: 'شراء جديد',
              onAction: _newPurchase,
            );
          }

          final query = _query.trim().toLowerCase();
          final purchases = all
              .where((p) =>
                  query.isEmpty ||
                  p.displaySupplier.toLowerCase().contains(query) ||
                  p.items.any((i) => i.name.toLowerCase().contains(query)))
              .toList();

          final month = Period.month.range();
          final monthPurchases =
              all.where((p) => Period.contains(month, p.createdAt)).toList();
          final monthTotal =
              monthPurchases.fold(0.0, (sum, Purchase p) => sum + p.total);

          final theme = Theme.of(context);
          Widget cell(String label, String value) => Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
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

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        cell('مشتريات هذا الشهر',
                            CurrencyFormatter.format(monthTotal)),
                        cell('عدد العمليات', '${monthPurchases.length}'),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SearchField(
                  hintText: 'ابحث باسم المورد أو المنتج...',
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              Expanded(
                child: purchases.isEmpty
                    ? const EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'لا توجد نتائج مطابقة',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                        itemCount: purchases.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) => PurchaseTile(
                          purchase: purchases[i],
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.purchaseDetails,
                            arguments: purchases[i].id,
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
