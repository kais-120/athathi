import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/customer.dart';
import '../../models/enums.dart';
import '../../models/sale_item.dart';
import '../../repositories/product_repository.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/measure_formatter.dart';
import '../../utils/validators.dart';
import '../../widgets/product_image.dart';
import '../../widgets/quantity_stepper.dart';
import 'cart_controller.dart';
import 'customer_picker_sheet.dart';
import 'edit_price_dialog.dart';

/// POS step 2: review the cart, choose customer + payment, confirm the sale.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, required this.cart});

  final CartController cart;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late final AppServices _services;
  final _paidController = TextEditingController();
  final _notesController = TextEditingController();

  Customer? _customer;
  PaymentMethod _method = PaymentMethod.cash;
  bool _paidEdited = false;
  bool _saving = false;
  String? _error;

  CartController get _cart => widget.cart;

  @override
  void initState() {
    super.initState();
    _services = AppScope.of(context);
    _syncPaid();
    _cart.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    _cart.removeListener(_onCartChanged);
    _paidController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  static double _round3(double v) => (v * 1000).round() / 1000;

  double get _total => _round3(_cart.total);
  double get _paid => _round3(Validators.parseNumber(_paidController.text) ?? 0);
  double get _remaining => _round3(_total - _paid);

  /// Cash / card: the paid amount follows the total until the user edits it.
  void _syncPaid() {
    if (_paidEdited) return;
    _paidController.text =
        _method == PaymentMethod.credit ? '' : MeasureFormatter.number(_total);
  }

  void _onCartChanged() {
    if (!mounted || _saving) return;
    if (_cart.isEmpty) {
      Navigator.pop(context); // nothing left to sell
      return;
    }
    setState(_syncPaid);
  }

  Future<void> _editPrice(CartLine line) async {
    final price = await showDialog<double>(
      context: context,
      builder: (_) => EditPriceDialog(
        productName: line.product.name,
        price: line.unitPrice,
      ),
    );
    if (price != null) _cart.setPrice(line.product.id, price);
  }

  Future<void> _pickCustomer() async {
    final choice = await showCustomerPicker(context, selectedId: _customer?.id);
    if (choice != null && mounted) {
      setState(() {
        _customer = choice.customer;
        _error = null;
      });
    }
  }

  void _setMethod(PaymentMethod method) {
    setState(() {
      _method = method;
      _paidEdited = false;
      _error = null;
      _syncPaid();
    });
  }

  Future<void> _confirm() async {
    FocusScope.of(context).unfocus();

    final total = _total;
    final paid = _paid;
    final remaining = _remaining;

    String? error;
    if (paid > total) {
      error = 'المبلغ المدفوع أكبر من إجمالي الفاتورة';
    } else if (remaining > 0 && _customer == null) {
      error = 'اختر حريفًا لتسجيل المبلغ المتبقي كدين';
    } else if (_method == PaymentMethod.credit && remaining <= 0) {
      error = 'البيع بالدين يجب أن يترك مبلغًا متبقيًا على الحريف';
    }
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final items = [
        for (final line in _cart.lines)
          SaleItem(
            productId: line.product.id,
            productName: line.product.name,
            unitPrice: line.unitPrice,
            unitCost: line.product.purchasePrice,
            quantity: line.quantity,
          ),
      ];
      final sale = await _services.sales.create(
        items: items,
        customer: _customer,
        method: _method,
        paid: paid,
        notes: _notesController.text.trim(),
      );

      if (!mounted) return;
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);

      _cart.removeListener(_onCartChanged);
      _cart.clear();
      navigator.popUntil((route) => route.isFirst);
      navigator.pushNamed(AppRoutes.saleDetails, arguments: sale.id);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('تمت عملية البيع بنجاح')));
    } on InsufficientStockException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error =
            'الكمية المتوفرة من "${e.productName}" هي ${e.available} فقط';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'تعذر إتمام عملية البيع، حاول مرة أخرى';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = _remaining;

    return Scaffold(
      appBar: AppBar(title: const Text('إتمام البيع')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _Section(
            title: 'المنتجات',
            child: Column(
              children: [
                for (final line in _cart.lines) ...[
                  _CartLineTile(
                    line: line,
                    enabled: !_saving,
                    onEditPrice: () => _editPrice(line),
                    onQuantity: (q) => _cart.setQuantity(line.product.id, q),
                    onRemove: () => _cart.remove(line.product.id),
                  ),
                  if (line != _cart.lines.last) const Divider(height: 24),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'الحريف',
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _saving ? null : _pickCustomer,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.primary,
                      child: const Icon(Icons.person_outline),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_customer?.name ?? 'حريف عابر',
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          Text(
                            _customer == null
                                ? 'اضغط لاختيار حريف أو إضافة حريف جديد'
                                : (_customer!.phone.isEmpty
                                    ? 'حريف مسجل'
                                    : _customer!.phone),
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_left),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'الدفع',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SegmentedButton<PaymentMethod>(
                  showSelectedIcon: false,
                  segments: [
                    for (final m in PaymentMethod.values)
                      ButtonSegment(value: m, label: Text(m.label)),
                  ],
                  selected: {_method},
                  onSelectionChanged:
                      _saving ? null : (s) => _setMethod(s.first),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _paidController,
                  enabled: !_saving,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  onChanged: (_) => setState(() {
                    _paidEdited = true;
                    _error = null;
                  }),
                  decoration: InputDecoration(
                    labelText: 'المبلغ المدفوع',
                    suffixText: 'د.ت',
                    suffixIcon: TextButton(
                      onPressed: _saving
                          ? null
                          : () => setState(() {
                                _paidController.text =
                                    MeasureFormatter.number(_total);
                                _paidEdited = true;
                                _error = null;
                              }),
                      child: const Text('دفع كامل'),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _SummaryRow('الإجمالي', CurrencyFormatter.format(_total),
                    bold: true),
                _SummaryRow('المدفوع', CurrencyFormatter.format(_paid)),
                _SummaryRow(
                  'المتبقي',
                  CurrencyFormatter.format(remaining < 0 ? 0 : remaining),
                  color: remaining > 0 ? AppColors.warning : AppColors.success,
                  bold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notesController,
            enabled: !_saving,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'ملاحظات (اختياري)'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      color: theme.colorScheme.onErrorContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_error!,
                        style: TextStyle(
                            color: theme.colorScheme.onErrorContainer)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: _saving ? null : _confirm,
            child: _saving
                ? SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: theme.colorScheme.onPrimary,
                    ),
                  )
                : Text('تأكيد البيع • ${CurrencyFormatter.format(_total)}'),
          ),
        ),
      ),
    );
  }
}

class _CartLineTile extends StatelessWidget {
  const _CartLineTile({
    required this.line,
    required this.enabled,
    required this.onEditPrice,
    required this.onQuantity,
    required this.onRemove,
  });

  final CartLine line;
  final bool enabled;
  final VoidCallback onEditPrice;
  final ValueChanged<int> onQuantity;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          children: [
            ProductImage(fileName: line.product.mainImage, size: 52),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(line.product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  InkWell(
                    onTap: enabled ? onEditPrice : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            CurrencyFormatter.format(line.unitPrice),
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.edit_outlined,
                              size: 14, color: theme.colorScheme.primary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'إزالة',
              onPressed: enabled ? onRemove : null,
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            QuantityStepper(
              quantity: line.quantity,
              max: line.maxQuantity,
              onChanged: enabled ? onQuantity : (_) {},
            ),
            const SizedBox(width: 8),
            Text('من ${line.maxQuantity}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const Spacer(),
            Text(CurrencyFormatter.format(line.total),
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value, {this.color, this.bold = false});

  final String label;
  final String value;
  final Color? color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: color,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
