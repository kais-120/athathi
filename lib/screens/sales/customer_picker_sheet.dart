import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../models/customer.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/id_generator.dart';
import '../../widgets/search_field.dart';

/// Result of the picker. `customer == null` means "حريف عابر" (no customer).
class CustomerChoice {
  const CustomerChoice(this.customer);
  final Customer? customer;
}

/// Bottom sheet to choose the customer of a sale. Returns null if dismissed.
Future<CustomerChoice?> showCustomerPicker(
  BuildContext context, {
  String? selectedId,
}) {
  return showModalBottomSheet<CustomerChoice>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.85,
      child: _CustomerSheet(selectedId: selectedId),
    ),
  );
}

class _CustomerSheet extends StatefulWidget {
  const _CustomerSheet({this.selectedId});

  final String? selectedId;

  @override
  State<_CustomerSheet> createState() => _CustomerSheetState();
}

class _CustomerSheetState extends State<_CustomerSheet> {
  String _query = '';

  Future<void> _addCustomer() async {
    final customer = await showDialog<Customer>(
      context: context,
      builder: (_) => const _AddCustomerDialog(),
    );
    if (customer != null && mounted) {
      Navigator.pop(context, CustomerChoice(customer));
    }
  }

  Widget? _subtitle(String phone, double debt) {
    final parts = [
      if (phone.isNotEmpty) phone,
      if (debt > 0) 'عليه: ${CurrencyFormatter.format(debt)}',
    ];
    return parts.isEmpty ? null : Text(parts.join(' • '));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = AppScope.of(context).customers;
    final customers = repo.search(_query);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('اختيار الحريف',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                SearchField(
                  hintText: 'ابحث عن حريف...',
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
                  leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                  title: const Text('حريف عابر',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('بدون تسجيل حريف'),
                  trailing: widget.selectedId == null
                      ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                      : null,
                  onTap: () => Navigator.pop(context, const CustomerChoice(null)),
                ),
                const Divider(),
                if (customers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        _query.isEmpty
                            ? 'لا يوجد حرفاء مسجلون بعد'
                            : 'لا توجد نتائج مطابقة',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                for (final c in customers)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.primary,
                      child: Text(c.name.isEmpty ? '?' : c.name.characters.first),
                    ),
                    title: Text(c.name,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: _subtitle(c.phone, repo.debtOf(c.id)),
                    trailing: widget.selectedId == c.id
                        ? Icon(Icons.check_circle,
                            color: theme.colorScheme.primary)
                        : null,
                    onTap: () => Navigator.pop(context, CustomerChoice(c)),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: OutlinedButton.icon(
              onPressed: _addCustomer,
              icon: const Icon(Icons.person_add_alt_outlined),
              label: const Text('إضافة حريف جديد'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddCustomerDialog extends StatefulWidget {
  const _AddCustomerDialog();

  @override
  State<_AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<_AddCustomerDialog> {
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
    final customer = Customer(
      id: IdGenerator.next(),
      name: _name.text.trim(),
      phone: _phone.text.trim(),
    );
    try {
      await AppScope.of(context).customers.add(customer);
      if (mounted) Navigator.pop(context, customer);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تعذر حفظ الحريف')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة حريف جديد'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              autofocus: true,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'اسم الحريف مطلوب' : null,
              decoration: const InputDecoration(labelText: 'اسم الحريف'),
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
