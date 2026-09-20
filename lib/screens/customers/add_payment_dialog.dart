import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_scope.dart';
import '../../models/customer.dart';
import '../../models/payment.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/id_generator.dart';
import '../../utils/measure_formatter.dart';
import '../../utils/validators.dart';

/// Registers a payment of [customer] against his [debt].
/// Returns true if the payment was saved.
class AddPaymentDialog extends StatefulWidget {
  const AddPaymentDialog({super.key, required this.customer, required this.debt});

  final Customer customer;
  final double debt;

  @override
  State<AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends State<AddPaymentDialog> {
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

  String? _validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) return 'المبلغ مطلوب';
    final amount = Validators.parseNumber(value);
    if (amount == null || amount <= 0) return 'المبلغ يجب أن يكون أكبر من 0';
    if (_round3(amount) > widget.debt) {
      return 'المبلغ أكبر من الدين المتبقي (${CurrencyFormatter.format(widget.debt)})';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final payment = Payment(
        id: IdGenerator.next(),
        customerId: widget.customer.id,
        amount: _round3(Validators.parseNumber(_amount.text) ?? 0),
        note: _note.text.trim(),
        createdAt: DateTime.now(),
      );
      await AppScope.of(context)
          .payments
          .add(payment, customerName: widget.customer.name);
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
      title: const Text('تسجيل دفعة'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.customer.name,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                'الدين المتبقي: ${CurrencyFormatter.format(widget.debt)}',
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
                validator: _validateAmount,
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
