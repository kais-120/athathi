import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../app/theme.dart';
import '../../models/sale.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';
import '../../utils/invoice_formatter.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';

/// Sale details shown as an invoice.
class SaleDetailsScreen extends StatefulWidget {
  const SaleDetailsScreen({super.key, required this.saleId});

  final String saleId;

  @override
  State<SaleDetailsScreen> createState() => _SaleDetailsScreenState();
}

class _SaleDetailsScreenState extends State<SaleDetailsScreen> {
  late final AppServices _services;

  @override
  void initState() {
    super.initState();
    _services = AppScope.of(context);
  }

  Future<void> _copyInvoice(Sale sale) async {
    final settings = _services.settings.current;
    await Clipboard.setData(ClipboardData(
      text: InvoiceFormatter.text(
        sale,
        businessName: settings.businessName,
        subtitle: settings.businessSubtitle,
      ),
    ));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('تم نسخ الفاتورة')));
  }

  @override
  Widget build(BuildContext context) {
    final sale = _services.sales.byId(widget.saleId);
    if (sale == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل العملية')),
        body: const EmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'العملية غير موجودة',
        ),
      );
    }

    final theme = Theme.of(context);
    final settings = _services.settings.current;
    final muted = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return Scaffold(
      appBar: AppBar(title: Text('فاتورة #${sale.number}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.chair_alt_rounded,
                            size: 36, color: theme.colorScheme.primary),
                        const SizedBox(height: 6),
                        Text(settings.businessName,
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        Text(settings.businessSubtitle, style: muted),
                      ],
                    ),
                  ),
                  const Divider(height: 28),
                  _InfoRow('رقم العملية', '#${sale.number}'),
                  _InfoRow('التاريخ', DateFormatter.dateTime(sale.createdAt)),
                  _InfoRow('الحريف', sale.displayCustomer),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(child: Text('طريقة الدفع', style: muted)),
                        StatusBadge.payment(sale.method),
                      ],
                    ),
                  ),
                  const Divider(height: 28),
                  Text('المنتجات',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  for (final item in sale.items) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.productName,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w700)),
                              Text(
                                '${item.quantity} × ${CurrencyFormatter.format(item.unitPrice)}',
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
                    const SizedBox(height: 12),
                  ],
                  const Divider(height: 20),
                  _InfoRow('الإجمالي', CurrencyFormatter.format(sale.total),
                      bold: true),
                  _InfoRow('المدفوع', CurrencyFormatter.format(sale.paid)),
                  _InfoRow(
                    'المتبقي',
                    CurrencyFormatter.format(sale.remaining),
                    bold: true,
                    color: sale.remaining > 0
                        ? AppColors.warning
                        : AppColors.success,
                  ),
                  if (sale.notes.trim().isNotEmpty) ...[
                    const Divider(height: 28),
                    Text('ملاحظات', style: muted),
                    const SizedBox(height: 4),
                    Text(sale.notes.trim(), style: theme.textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: OutlinedButton.icon(
            onPressed: () => _copyInvoice(sale),
            icon: const Icon(Icons.copy_rounded),
            label: const Text('نسخ الفاتورة'),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value, {this.bold = false, this.color});

  final String label;
  final String value;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
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
  }
}
