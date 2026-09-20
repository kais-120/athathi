import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_scope.dart';
import '../../models/supplier.dart';
import '../../models/supplier_payment.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/id_generator.dart';
import '../../utils/measure_formatter.dart';
import '../../utils/validators.dart';

/// Registers a payment made to [supplier] against what the shop owes him.
/// Returns true if the payment was saved.
class AddSupplierPaymentDialog extends StatefulWidget {
  const AddSupplierPaymentDialog(
      {super.key, required this.supplier, required this.debt});

  final Supplier supplier;
  final double debt;

  @override
  State<AddSupplierPaymentDialog> createState() =>
      _AddSupplierPaymentDialogState();
}

class _AddSupplierPaymentDialogState extends State<AddSupplierPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount =
      TextEditingController(text: MeasureFormatter.number(widget.debt));
  final _note = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  static double _round3(double v) => (v * 1000).round() / 1000;

  String? _validate(String? value) {
    final base = Validators.positiveAmount(value);
    if (base != null) return base;
    if (_round3(Validators.parseNumber(value)!) > widget.debt) {
      return 'المبلغ أكبر من المستحق (${CurrencyFormatter.format(widget.debt)})';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final payment = SupplierPayment(
        id: IdGenerator.next(),
        supplierId: widget.supplier.id,
        amount: _round3(Validators.parseNumber(_amount.text) ?? 0),
        note: _note.text.trim(),
        createdAt: DateTime.now(),
      );
      await AppScope.of(context)
          .supplierPayments
          .add(payment, supplierName: widget.supplier.name);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تعذر حفظ الدفعة')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('دفعة للمورد'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.supplier.name,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                'المستحق للمورد: ${CurrencyFormatter.format(widget.debt)}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amount,
                enabled: !_saving,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                validator: _validate,
                decoration: const InputDecoration(
                  labelText: 'المبلغ',
                  suffixText: 'د.ت',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _note,
                enabled: !_saving,
                decoration:
                    const InputDecoration(labelText: 'ملاحظة (اختياري)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
          onPressed: _saving ? null : _save,
          child: const Text('حفظ الدفعة'),
        ),
      ],
    );
  }
}
