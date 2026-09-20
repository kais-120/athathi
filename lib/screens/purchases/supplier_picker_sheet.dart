import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../models/supplier.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/id_generator.dart';
import '../../utils/validators.dart';
import '../../widgets/search_field.dart';

/// Result of the picker. `supplier == null` means "مورد غير محدد".
class SupplierChoice {
  const SupplierChoice(this.supplier);
  final Supplier? supplier;
}

/// Bottom sheet to choose the supplier of a purchase (or add a new one).
/// Returns null if dismissed.
Future<SupplierChoice?> showSupplierPicker(
  BuildContext context, {
  String? selectedId,
}) {
  return showModalBottomSheet<SupplierChoice>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.85,
      child: _SupplierSheet(selectedId: selectedId),
    ),
  );
}

class _SupplierSheet extends StatefulWidget {
  const _SupplierSheet({this.selectedId});

  final String? selectedId;

  @override
  State<_SupplierSheet> createState() => _SupplierSheetState();
}

class _SupplierSheetState extends State<_SupplierSheet> {
  String _query = '';

  Future<void> _addSupplier() async {
    final supplier = await showDialog<Supplier>(
      context: context,
      builder: (_) => const _AddSupplierDialog(),
    );
    if (supplier != null && mounted) {
      Navigator.pop(context, SupplierChoice(supplier));
    }
  }

  Widget? _subtitle(String phone, double debt) {
    final parts = [
      if (phone.isNotEmpty) phone,
      if (debt > 0) 'له: ${CurrencyFormatter.format(debt)}',
    ];
    return parts.isEmpty ? null : Text(parts.join(' • '));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = AppScope.of(context).suppliers;
    final suppliers = repo.search(_query);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('اختيار المورد',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                SearchField(
                  hintText: 'ابحث عن مورد...',
                  onChanged: (v) => setState(() => _query = v),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                ListTile(
                  leading: const CircleAvatar(
                      child: Icon(Icons.person_outline)),
                  title: const Text('مورد غير محدد',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('شراء من شخص بدون تسجيل مورد'),
                  trailing: widget.selectedId == null
                      ? Icon(Icons.check_circle,
                          color: theme.colorScheme.primary)
                      : null,
                  onTap: () =>
                      Navigator.pop(context, const SupplierChoice(null)),
                ),
                const Divider(),
                if (suppliers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        _query.isEmpty
                            ? 'لا يوجد موردون مسجلون بعد'
                            : 'لا توجد نتائج مطابقة',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                for (final s in suppliers)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.primary,
                      child: Text(s.name.isEmpty ? '?' : s.name.characters.first),
                    ),
                    title: Text(s.name,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: _subtitle(s.phone, repo.debtOf(s.id)),
                    trailing: widget.selectedId == s.id
                        ? Icon(Icons.check_circle,
                            color: theme.colorScheme.primary)
                        : null,
                    onTap: () => Navigator.pop(context, SupplierChoice(s)),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: OutlinedButton.icon(
              onPressed: _addSupplier,
              icon: const Icon(Icons.add_business_outlined),
              label: const Text('إضافة مورد جديد'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddSupplierDialog extends StatefulWidget {
  const _AddSupplierDialog();

  @override
  State<_AddSupplierDialog> createState() => _AddSupplierDialogState();
}

class _AddSupplierDialogState extends State<_AddSupplierDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final supplier = Supplier(
      id: IdGenerator.next(),
      name: _name.text.trim(),
      phone: _phone.text.trim(),
    );
    try {
      await AppScope.of(context).suppliers.add(supplier);
      if (mounted) Navigator.pop(context, supplier);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تعذر حفظ المورد')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة مورد جديد'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              autofocus: true,
              textInputAction: TextInputAction.next,
              validator: Validators.supplierName,
              decoration: const InputDecoration(labelText: 'اسم المورد'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'رقم الهاتف'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
          onPressed: _saving ? null : _save,
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
