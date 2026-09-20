import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/supplier.dart';
import '../../repositories/purchase_repository.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/measure_formatter.dart';
import '../../utils/validators.dart';
import '../../widgets/status_badge.dart';
import 'purchase_line_screen.dart';
import 'supplier_picker_sheet.dart';

/// Records furniture bought from a supplier. Confirming adds the pieces to
/// the stock (and creates the products that are new).
class NewPurchaseScreen extends StatefulWidget {
  const NewPurchaseScreen({super.key});

  @override
  State<NewPurchaseScreen> createState() => _NewPurchaseScreenState();
}

class _NewPurchaseScreenState extends State<NewPurchaseScreen> {
  late final AppServices _services;
  final List<PurchaseDraftLine> _lines = [];
  final _paidController = TextEditingController();
  final _notesController = TextEditingController();

  Supplier? _supplier;
  bool _paidEdited = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _services = AppScope.of(context);
  }

  @override
  void dispose() {
    _paidController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  static double _round3(double v) => (v * 1000).round() / 1000;

  double get _total => _round3(_lines.fold(0.0, (sum, l) => sum + l.total));
  double get _paid => _round3(Validators.parseNumber(_paidController.text) ?? 0);
  double get _remaining => _round3(_total - _paid);

  /// The paid amount follows the total until the user edits it.
  void _syncPaid() {
    if (_paidEdited) return;
    _paidController.text = MeasureFormatter.number(_total);
  }

  Future<void> _addLine() async {
    final line = await Navigator.push<PurchaseDraftLine>(
      context,
      MaterialPageRoute<PurchaseDraftLine>(
        builder: (_) => const PurchaseLineScreen(),
      ),
    );
    if (line == null || !mounted) return;
    setState(() {
      _lines.add(line);
      _error = null;
      _syncPaid();
    });
  }

  Future<void> _editLine(int index) async {
    final line = await Navigator.push<PurchaseDraftLine>(
      context,
      MaterialPageRoute<PurchaseDraftLine>(
        builder: (_) => PurchaseLineScreen(initial: _lines[index]),
      ),
    );
    if (line == null || !mounted) return;
    setState(() {
      _lines[index] = line;
      _syncPaid();
    });
  }

  void _removeLine(int index) {
    setState(() {
      _lines.removeAt(index);
      _syncPaid();
    });
  }

  Future<void> _pickSupplier() async {
    final choice = await showSupplierPicker(context, selectedId: _supplier?.id);
    if (choice != null && mounted) {
      setState(() {
        _supplier = choice.supplier;
        _error = null;
      });
    }
  }

  Future<bool?> _confirmDiscard() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إلغاء عملية الشراء'),
        content: const Text('أضفت منتجات لم تُحفظ بعد. هل تريد إلغاء العملية؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('متابعة'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              minimumSize: const Size(100, 44),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('إلغاء العملية'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirm() async {
    FocusScope.of(context).unfocus();

    String? error;
    if (_lines.isEmpty) {
      error = 'أضف منتجًا واحدًا على الأقل';
    } else if (_paid > _total) {
      error = 'المبلغ المدفوع أكبر من إجمالي الشراء';
    } else if (_remaining > 0 && _supplier == null) {
      error = 'اختر موردًا لتسجيل المبلغ المتبقي كدين عليك';
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
      final purchase = await _services.purchases.create(
        lines: List.of(_lines),
        supplier: _supplier,
        paid: _paid,
        notes: _notesController.text.trim(),
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.purchaseDetails,
        arguments: purchase.id,
      );
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
            const SnackBar(content: Text('تمت عملية الشراء بنجاح')));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'تعذر حفظ عملية الشراء، حاول مرة أخرى';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = _remaining;

    return PopScope(
      canPop: _lines.isEmpty || _saving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final leave = await _confirmDiscard();
        if (leave == true && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('شراء جديد')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            _Section(
              title: 'المنتجات المشتراة',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_lines.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'لم تتم إضافة منتجات بعد',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  for (var i = 0; i < _lines.length; i++) ...[
                    _LineTile(
                      line: _lines[i],
                      enabled: !_saving,
                      onEdit: () => _editLine(i),
                      onRemove: () => _removeLine(i),
                    ),
                    const Divider(height: 20),
                  ],
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _addLine,
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة منتج'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'المورد',
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _saving ? null : _pickSupplier,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        foregroundColor: theme.colorScheme.primary,
                        child: const Icon(Icons.local_shipping_outlined),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_supplier?.name ?? 'مورد غير محدد',
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                            Text(
                              _supplier == null
                                  ? 'اضغط لاختيار مورد أو إضافة مورد جديد'
                                  : (_supplier!.phone.isEmpty
                                      ? 'مورد مسجل'
                                      : _supplier!.phone),
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
                    'المتبقي للمورد',
                    CurrencyFormatter.format(remaining < 0 ? 0 : remaining),
                    color:
                        remaining > 0 ? AppColors.warning : AppColors.success,
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
                  : Text('تأكيد الشراء • ${CurrencyFormatter.format(_total)}'),
            ),
          ),
        ),
      ),
    );
  }
}

class _LineTile extends StatelessWidget {
  const _LineTile({
    required this.line,
    required this.enabled,
    required this.onEdit,
    required this.onRemove,
  });

  final PurchaseDraftLine line;
  final bool enabled;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(line.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  if (line.isNewProduct) ...[
                    const SizedBox(width: 8),
                    const StatusBadge(label: 'منتج جديد', color: AppColors.info),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${line.quantity} × ${CurrencyFormatter.format(line.unitCost)} = ${CurrencyFormatter.format(line.total)}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'تعديل',
          icon: const Icon(Icons.edit_outlined),
          onPressed: enabled ? onEdit : null,
        ),
        IconButton(
          tooltip: 'إزالة',
          icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
          onPressed: enabled ? onRemove : null,
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
