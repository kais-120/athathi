import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/empty_state.dart';

/// Purchase details: supplier, products bought, totals.
class PurchaseDetailsScreen extends StatefulWidget {
  const PurchaseDetailsScreen({super.key, required this.purchaseId});

  final String purchaseId;

  @override
  State<PurchaseDetailsScreen> createState() => _PurchaseDetailsScreenState();
}

class _PurchaseDetailsScreenState extends State<PurchaseDetailsScreen> {
  late final AppServices _services;

  @override
  void initState() {
    super.initState();
    _services = AppScope.of(context);
  }

  @override
  Widget build(BuildContext context) {
    final purchase = _services.purchases.byId(widget.purchaseId);
    if (purchase == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل الشراء')),
        body: const EmptyState(
          icon: Icons.shopping_bag_outlined,
          title: 'عملية الشراء غير موجودة',
        ),
      );
    }

    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    Widget row(String label, String value, {bool bold = false, Color? color}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(child: Text(label, style: muted)),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: color,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الشراء')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  row('المورد', purchase.displaySupplier, bold: true),
                  row('التاريخ', DateFormatter.dateTime(purchase.createdAt)),
                  row('عدد القطع', '${purchase.pieces}'),
                  const Divider(height: 28),
                  Text('المنتجات',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  for (final item in purchase.items) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w700)),
                              Text(
                                '${item.quantity} × ${CurrencyFormatter.format(item.unitCost)}',
                                style: muted,
                              ),
                            ],
                          ),
                        ),
                        Text(CurrencyFormatter.format(item.lineTotal),
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w700)),
                      ],
                    ),
                    if (item.productId != null &&
                        _services.products.byId(item.productId!) != null)
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            AppRoutes.productDetails,
                            arguments: item.productId,
                          ),
                          child: const Text('عرض المنتج'),
                        ),
                      ),
                    const SizedBox(height: 4),
                  ],
                  const Divider(height: 20),
                  row('الإجمالي', CurrencyFormatter.format(purchase.total),
                      bold: true),
                  row('المدفوع', CurrencyFormatter.format(purchase.paid)),
                  row(
                    'المتبقي للمورد',
                    CurrencyFormatter.format(purchase.remaining),
                    bold: true,
                    color: purchase.remaining > 0
                        ? AppColors.warning
                        : AppColors.success,
                  ),
                  if (purchase.notes.trim().isNotEmpty) ...[
                    const Divider(height: 28),
                    Text('ملاحظات', style: muted),
                    const SizedBox(height: 4),
                    Text(purchase.notes.trim(),
                        style: theme.textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
