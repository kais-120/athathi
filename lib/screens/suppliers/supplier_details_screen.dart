import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/purchase.dart';
import '../../models/supplier.dart';
import '../../models/supplier_payment.dart';
import '../../repositories/supplier_repository.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/purchase_tile.dart';
import '../../widgets/status_badge.dart';
import 'add_supplier_payment_dialog.dart';

/// Supplier file: contact info, what we owe, purchase and payment history.
class SupplierDetailsScreen extends StatefulWidget {
  const SupplierDetailsScreen({super.key, required this.supplierId});

  final String supplierId;

  @override
  State<SupplierDetailsScreen> createState() => _SupplierDetailsScreenState();
}

enum _Tab { purchases, payments }

class _SupplierDetailsScreenState extends State<SupplierDetailsScreen> {
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

  Future<bool?> _confirm({
    required String title,
    required String message,
    required String action,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final scheme = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          icon: Icon(Icons.delete_outline, color: scheme.error, size: 36),
          title: Text(title),
          content: Text(message),
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
              child: Text(action),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addPayment(Supplier supplier, double debt) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AddSupplierPaymentDialog(supplier: supplier, debt: debt),
    );
    if (saved == true && mounted) _snack('تم تسجيل الدفعة بنجاح');
  }

  Future<void> _deletePayment(SupplierPayment payment) async {
    final ok = await _confirm(
      title: 'حذف الدفعة',
      message:
          'سيتم حذف دفعة بقيمة ${CurrencyFormatter.format(payment.amount)} وسيزداد المستحق للمورد بنفس المبلغ.',
      action: 'حذف',
    );
    if (ok != true) return;
    await _services.supplierPayments.delete(payment.id);
    if (mounted) _snack('تم حذف الدفعة');
  }

  Future<void> _deleteSupplier(Supplier supplier) async {
    final debt = _services.suppliers.debtOf(supplier.id);
    if (debt > 0) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.info_outline, size: 36),
          title: const Text('لا يمكن حذف المورد'),
          content: Text(
            'ما زال للمورد مبلغ مستحق بقيمة ${CurrencyFormatter.format(debt)}. '
            'سجّل الدفعات حتى يصبح صفرًا ثم احذفه.',
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

    final ok = await _confirm(
      title: 'حذف المورد',
      message:
          'هل تريد حذف "${supplier.name}"؟ ستبقى عمليات الشراء السابقة في السجل.',
      action: 'حذف',
    );
    if (ok != true) return;

    try {
      await _services.suppliers.delete(supplier.id);
      if (!mounted) return;
      _snack('تم حذف المورد');
      Navigator.pop(context);
    } on SupplierHasDebtException {
      if (mounted) _snack('لا يمكن حذف مورد له مستحقات');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _services.suppliers,
        _services.purchases,
        _services.supplierPayments,
      ]),
      builder: (context, _) {
        final supplier = _services.suppliers.byId(widget.supplierId);
        if (supplier == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('ملف المورد')),
            body: const EmptyState(
              icon: Icons.local_shipping_outlined,
              title: 'المورد غير موجود',
            ),
          );
        }
        return _buildDetails(context, supplier);
      },
    );
  }

  Widget _buildDetails(BuildContext context, Supplier supplier) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    final purchases = _services.purchases.forSupplier(supplier.id);
    final payments = _services.supplierPayments.forSupplier(supplier.id);
    final debt = _services.suppliers.debtOf(supplier.id);

    final purchasesTotal = purchases.fold(0.0, (sum, p) => sum + p.total);
    final paidAtPurchase = purchases.fold(0.0, (sum, p) => sum + p.paid);
    final laterPayments = payments.fold(0.0, (sum, p) => sum + p.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ملف المورد'),
        actions: [
          IconButton(
            tooltip: 'تعديل',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.supplierForm,
              arguments: supplier.id,
            ),
          ),
          IconButton(
            tooltip: 'حذف',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _deleteSupplier(supplier),
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
                      supplier.name.isEmpty ? '?' : supplier.name.characters.first,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(supplier.name,
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        if (supplier.phone.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          _IconLine(Icons.phone_outlined, supplier.phone),
                        ],
                        if (supplier.address.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          _IconLine(
                              Icons.location_on_outlined, supplier.address),
                        ],
                        if (supplier.notes.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          _IconLine(Icons.notes_outlined, supplier.notes),
                        ],
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
                  Text('المستحق للمورد', style: muted),
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
                  _AmountRow('المدفوع عند الشراء',
                      CurrencyFormatter.format(paidAtPurchase)),
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
                  value: _Tab.purchases,
                  label: Text('المشتريات (${purchases.length})')),
              ButtonSegment(
                  value: _Tab.payments,
                  label: Text('الدفعات (${payments.length})')),
            ],
            selected: {_tab},
            onSelectionChanged: (s) => setState(() => _tab = s.first),
          ),
          const SizedBox(height: 12),
          if (_tab == _Tab.purchases)
            ..._purchaseList(purchases)
          else
            ..._paymentList(payments),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: debt > 0 ? () => _addPayment(supplier, debt) : null,
            icon: const Icon(Icons.payments_outlined),
            label: const Text('تسديد دفعة للمورد'),
          ),
        ),
      ),
    );
  }

  List<Widget> _purchaseList(List<Purchase> purchases) {
    if (purchases.isEmpty) {
      return const [_InlineEmpty('لا توجد مشتريات من هذا المورد')];
    }
    return [
      for (final purchase in purchases) ...[
        PurchaseTile(
          purchase: purchase,
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.purchaseDetails,
            arguments: purchase.id,
          ),
        ),
        const SizedBox(height: 8),
      ],
    ];
  }

  List<Widget> _paymentList(List<SupplierPayment> payments) {
    if (payments.isEmpty) return const [_InlineEmpty('لا توجد دفعات مسجلة')];
    final theme = Theme.of(context);
    return [
      for (final payment in payments) ...[
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.danger.withValues(alpha: 0.12),
                  foregroundColor: AppColors.danger,
                  child: const Icon(Icons.payments_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(CurrencyFormatter.format(payment.amount),
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      Text(
                        DateFormatter.dateTime(payment.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                      if (payment.note.isNotEmpty)
                        Text(payment.note, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'حذف الدفعة',
                  icon: Icon(Icons.delete_outline,
                      color: theme.colorScheme.error),
                  onPressed: () => _deletePayment(payment),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    ];
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
