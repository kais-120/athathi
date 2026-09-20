import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/measure_formatter.dart';
import '../../utils/validators.dart';

/// Asks for a new unit price (negotiation). Returns the price or null.
class EditPriceDialog extends StatefulWidget {
  const EditPriceDialog({super.key, required this.productName, required this.price});

  final String productName;
  final double price;

  @override
  State<EditPriceDialog> createState() => _EditPriceDialogState();
}

class _EditPriceDialogState extends State<EditPriceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller =
      TextEditingController(text: MeasureFormatter.number(widget.price));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, Validators.parseNumber(_controller.text));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تعديل سعر القطعة'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.productName,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              validator: Validators.sellingPrice,
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'السعر',
                suffixText: 'د.ت',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
          onPressed: _submit,
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
