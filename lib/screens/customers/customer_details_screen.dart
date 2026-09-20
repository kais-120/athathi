import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/customer.dart';
import '../../models/payment.dart';
import '../../models/sale.dart';
import '../../repositories/customer_repository.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/sale_tile.dart';
import '../../widgets/status_badge.dart';
import 'add_payment_dialog.dart';

/// Customer file: contact info, debt balance, purchase history and payments.
class CustomerDetailsScreen extends StatefulWidget {
  const CustomerDetailsScreen({super.key, required this.customerId});

  final String customerId;

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

enum _Tab { purchases, payments }

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  late final AppServices _services;
  _Tab _tab = _Tab.purchases;

  @override
  void initState() {
    super.initState();
    _services = AppScope.of(context);
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addPayment(Customer customer, double debt) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AddPaymentDialog(customer: customer, debt: debt),
    );
    if (saved == true && mounted) _snack('تم تسجيل الدفعة بنجاح');
  }

  Future<void> _deletePayment(Payment payment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final scheme = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          icon: Icon(Icons.delete_outline, color: scheme.error, size: 36),
          title: const Text('حذف الدفعة'),
          content: Text(
            'سيتم حذف دفعة بقيمة ${CurrencyFormatter.format(payment.amount)} '
            'وسيزداد دين الحريف بنفس المبلغ.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
                minimumSize: const Size(100, 44),
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    await _services.payments.delete(payment.id);
    if (mounted) _snack('تم حذف الدفعة');
  }

  Future<void> _deleteCustomer(Customer customer) async {
    final debt = _services.customers.debtOf(customer.id);
    if (debt > 0) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.info_outline, size: 36),
          title: const Text('لا يمكن حذف الحريف'),
          content: Text(
            'على الحريف دين بقيمة ${CurrencyFormatter.format(debt)}. '
            'سجّل الدفعات حتى يصبح الدين صفرًا ثم احذفه.',
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('حسنًا'),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final scheme = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          icon: Icon(Icons.delete_outline, color: scheme.error, size: 36),
          title: const Text('حذف الحريف'),
          content: Text(
            'هل تريد حذف "${customer.name}"؟ ستبقى عمليات البيع السابقة في سجل المبيعات.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
                minimumSize: const Size(100, 44),
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    try {
      await _services.customers.delete(customer.id);
      if (!mounted) return;
      _snack('تم حذف الحريف');
      Navigator.pop(context);
    } on CustomerHasDebtException {
      if (mounted) _snack('لا يمكن حذف حريف عليه دين');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _services.customers,
        _services.sales,
        _services.payments,
      ]),
      builder: (context, _) {
        final customer = _services.customers.byId(widget.customerId);
        if (customer == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('ملف الحريف')),
            body: const EmptyState(
              icon: Icons.person_off_outlined,
              title: 'الحريف غير موجود',
            ),
          );
        }
        return _buildDetails(context, customer);
      },
    );
  }

  Widget _buildDetails(BuildContext context, Customer customer) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    final sales = _services.sales.forCustomer(customer.id);
    final payments = _services.payments.forCustomer(customer.id);
    final debt = _services.customers.debtOf(customer.id);

    final purchasesTotal = sales.fold(0.0, (sum, s) => sum + s.total);
    final paidAtSale = sales.fold(0.0, (sum, s) => sum + s.paid);
    final laterPayments = payments.fold(0.0, (sum, p) => sum + p.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ملف الحريف'),
        actions: [
          IconButton(
            tooltip: 'تعديل',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.customerForm,
              arguments: customer.id,
            ),
          ),
          IconButton(
            tooltip: 'حذف',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _deleteCustomer(customer),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.primary,
                    child: Text(
                      customer.name.isEmpty ? '?' : customer.name.characters.first,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(customer.name,
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        if (customer.phone.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          _IconLine(Icons.phone_outlined, customer.phone),
                        ],
                        if (customer.address.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          _IconLine(
                              Icons.location_on_outlined, customer.address),
                        ],
                        if (customer.notes.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          _IconLine(Icons.notes_outlined, customer.notes),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          'حريف منذ ${DateFormatter.date(customer.createdAt)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('رصيد الدين', style: muted),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            CurrencyFormatter.format(debt),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: debt > 0
                                  ? AppColors.warning
                                  : AppColors.success,
                            ),
                          ),
                        ),
                      ),
                      if (debt <= 0)
                        const StatusBadge(
                          label: 'لا يوجد دين',
                          color: AppColors.success,
                          icon: Icons.check_circle_outline,
                        ),
                    ],
                  ),
                  const Divider(height: 28),
                  _AmountRow('إجمالي المشتريات',
                      CurrencyFormatter.format(purchasesTotal)),
                  _AmountRow('المدفوع عند البيع',
                      CurrencyFormatter.format(paidAtSale)),
                  _AmountRow('الدفعات اللاحقة',
                      CurrencyFormatter.format(laterPayments)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<_Tab>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                  value: _Tab.purchases, label: Text('المشتريات (${sales.length})')),
              ButtonSegment(
                  value: _Tab.payments,
                  label: Text('الدفعات (${payments.length})')),
            ],
            selected: {_tab},
            onSelectionChanged: (s) => setState(() => _tab = s.first),
          ),
          const SizedBox(height: 12),
          if (_tab == _Tab.purchases)
            ..._purchases(sales)
          else
            ..._payments(payments),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: debt > 0 ? () => _addPayment(customer, debt) : null,
            icon: const Icon(Icons.payments_outlined),
            label: const Text('تسجيل دفعة'),
          ),
        ),
      ),
    );
  }

  List<Widget> _purchases(List<Sale> sales) {
    if (sales.isEmpty) return const [_InlineEmpty('لا توجد مشتريات لهذا الحريف')];
    return [
      for (final sale in sales) ...[
        SaleTile(
          sale: sale,
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.saleDetails,
            arguments: sale.id,
          ),
        ),
        const SizedBox(height: 8),
      ],
    ];
  }

  List<Widget> _payments(List<Payment> payments) {
    if (payments.isEmpty) return const [_InlineEmpty('لا توجد دفعات مسجلة')];
    return [
      for (final payment in payments) ...[
        _PaymentTile(payment: payment, onDelete: () => _deletePayment(payment)),
        const SizedBox(height: 8),
      ],
    ];
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.payment, required this.onDelete});

  final Payment payment;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.success.withValues(alpha: 0.12),
              foregroundColor: AppColors.success,
              child: const Icon(Icons.payments_outlined),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        CurrencyFormatter.format(payment.amount),
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge.payment(payment.method),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormatter.dateTime(payment.createdAt),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  if (payment.note.isNotEmpty)
                    Text(payment.note, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            IconButton(
              tooltip: 'حذف الدفعة',
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _IconLine extends StatelessWidget {
  const _IconLine(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          Text(value,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            message,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}
