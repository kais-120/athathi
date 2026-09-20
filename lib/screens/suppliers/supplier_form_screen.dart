import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../models/supplier.dart';
import '../../utils/id_generator.dart';
import '../../utils/validators.dart';
import '../../widgets/empty_state.dart';

/// Add / edit a supplier. [supplierId] == null means "add".
class SupplierFormScreen extends StatefulWidget {
  const SupplierFormScreen({super.key, this.supplierId});

  final String? supplierId;

  @override
  State<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends State<SupplierFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _notes = TextEditingController();

  late final AppServices _services;
  Supplier? _existing;
  bool _saving = false;

  bool get _isEdit => widget.supplierId != null;

  @override
  void initState() {
    super.initState();
    _services = AppScope.of(context);
    final id = widget.supplierId;
    final supplier = id == null ? null : _services.suppliers.byId(id);
    if (supplier != null) {
      _existing = supplier;
      _name.text = supplier.name;
      _phone.text = supplier.phone;
      _address.text = supplier.address;
      _notes.text = supplier.notes;
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
      final supplier = Supplier(
        id: existing?.id ?? IdGenerator.next(),
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        address: _address.text.trim(),
        notes: _notes.text.trim(),
        createdAt: existing?.createdAt,
      );
      if (existing == null) {
        await _services.suppliers.add(supplier);
      } else {
        await _services.suppliers.update(supplier);
      }
      if (!mounted) return;
      _snack(existing == null
          ? 'تمت إضافة المورد بنجاح'
          : 'تم تحديث بيانات المورد');
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('تعذر حفظ المورد، حاول مرة أخرى');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEdit && _existing == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تعديل مورد')),
        body: const EmptyState(
          icon: Icons.local_shipping_outlined,
          title: 'المورد غير موجود',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'تعديل مورد' : 'إضافة مورد')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            TextFormField(
              controller: _name,
              enabled: !_saving,
              textInputAction: TextInputAction.next,
              validator: Validators.supplierName,
              decoration: const InputDecoration(
                labelText: 'اسم المورد',
                prefixIcon: Icon(Icons.local_shipping_outlined),
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
                  : const Text('حفظ المورد'),
            ),
          ],
        ),
      ),
    );
  }
}
