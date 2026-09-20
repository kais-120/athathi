import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../models/customer.dart';
import '../../utils/id_generator.dart';
import '../../utils/validators.dart';
import '../../widgets/empty_state.dart';

/// Add / edit a customer. [customerId] == null means "add".
class CustomerFormScreen extends StatefulWidget {
  const CustomerFormScreen({super.key, this.customerId});

  final String? customerId;

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _notes = TextEditingController();

  late final AppServices _services;
  Customer? _existing;
  bool _saving = false;

  bool get _isEdit => widget.customerId != null;

  @override
  void initState() {
    super.initState();
    _services = AppScope.of(context);
    final id = widget.customerId;
    final customer = id == null ? null : _services.customers.byId(id);
    if (customer != null) {
      _existing = customer;
      _name.text = customer.name;
      _phone.text = customer.phone;
      _address.text = customer.address;
      _notes.text = customer.notes;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final existing = _existing;
      final customer = Customer(
        id: existing?.id ?? IdGenerator.next(),
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        address: _address.text.trim(),
        notes: _notes.text.trim(),
        createdAt: existing?.createdAt,
      );

      if (existing == null) {
        await _services.customers.add(customer);
      } else {
        await _services.customers.update(customer);
      }

      if (!mounted) return;
      _snack(existing == null
          ? 'تمت إضافة الحريف بنجاح'
          : 'تم تحديث بيانات الحريف');
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('تعذر حفظ الحريف، حاول مرة أخرى');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEdit && _existing == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تعديل حريف')),
        body: const EmptyState(
          icon: Icons.person_off_outlined,
          title: 'الحريف غير موجود',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'تعديل حريف' : 'إضافة حريف')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            TextFormField(
              controller: _name,
              enabled: !_saving,
              textInputAction: TextInputAction.next,
              validator: Validators.customerName,
              decoration: const InputDecoration(
                labelText: 'اسم الحريف',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phone,
              enabled: !_saving,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _address,
              enabled: !_saving,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'العنوان',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notes,
              enabled: !_saving,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'ملاحظات',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    )
                  : const Text('حفظ الحريف'),
            ),
          ],
        ),
      ),
    );
  }
}
