import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../models/expense.dart';
import '../../utils/date_formatter.dart';
import '../../utils/id_generator.dart';
import '../../utils/measure_formatter.dart';
import '../../utils/validators.dart';
import '../../widgets/empty_state.dart';

/// Add / edit an expense. [expenseId] == null means "add".
class ExpenseFormScreen extends StatefulWidget {
  const ExpenseFormScreen({super.key, this.expenseId});

  final String? expenseId;

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _amount = TextEditingController();
  final _notes = TextEditingController();

  late final AppServices _services;
  Expense? _existing;
  String _category = kExpenseCategories.first;
  DateTime _date = DateTime.now();
  bool _saving = false;

  bool get _isEdit => widget.expenseId != null;

  @override
  void initState() {
    super.initState();
    _services = AppScope.of(context);
    final id = widget.expenseId;
    final expense = id == null ? null : _services.expenses.byId(id);
    if (expense != null) {
      _existing = expense;
      _title.text = expense.title;
      _amount.text = MeasureFormatter.number(expense.amount);
      _notes.text = expense.notes;
      _date = expense.createdAt;
      if (expense.category.isNotEmpty) _category = expense.category;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(now) ? now : _date,
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (picked == null || !mounted) return;
    final sameDay = picked.year == _date.year &&
        picked.month == _date.month &&
        picked.day == _date.day;
    if (sameDay) return;
    setState(() {
      // Keep a realistic time: "now" for today, noon for past days.
      final isToday = picked.year == now.year &&
          picked.month == now.month &&
          picked.day == now.day;
      _date = isToday
          ? now
          : DateTime(picked.year, picked.month, picked.day, 12);
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final existing = _existing;
      final expense = Expense(
        id: existing?.id ?? IdGenerator.next(),
        title: _title.text.trim(),
        category: _category,
        amount: ((Validators.parseNumber(_amount.text) ?? 0) * 1000).round() / 1000,
        notes: _notes.text.trim(),
        createdAt: _date,
      );
      if (existing == null) {
        await _services.expenses.add(expense);
      } else {
        await _services.expenses.update(expense);
      }
      if (!mounted) return;
      _snack(existing == null ? 'تمت إضافة المصروف بنجاح' : 'تم تحديث المصروف');
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('تعذر حفظ المصروف، حاول مرة أخرى');
    }
  }

  Future<void> _delete() async {
    final existing = _existing;
    if (existing == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final scheme = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          icon: Icon(Icons.delete_outline, color: scheme.error, size: 36),
          title: const Text('حذف المصروف'),
          content: Text('هل تريد حذف "${existing.title}"؟ لا يمكن التراجع عن هذا الإجراء.'),
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
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    await _services.expenses.delete(existing.id);
    if (!mounted) return;
    _snack('تم حذف المصروف');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isEdit && _existing == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تعديل مصروف')),
        body: const EmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'المصروف غير موجود',
        ),
      );
    }

    final categories = {...kExpenseCategories, _category}.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'تعديل مصروف' : 'إضافة مصروف'),
        actions: [
          if (_isEdit)
            IconButton(
              tooltip: 'حذف',
              icon: const Icon(Icons.delete_outline),
              onPressed: _saving ? null : _delete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            TextFormField(
              controller: _title,
              enabled: !_saving,
              textInputAction: TextInputAction.next,
              validator: Validators.expenseTitle,
              decoration: const InputDecoration(
                labelText: 'عنوان المصروف',
                prefixIcon: Icon(Icons.edit_note_outlined),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: _category,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'التصنيف'),
              items: [
                for (final c in categories)
                  DropdownMenuItem(value: c, child: Text(c)),
              ],
              onChanged: _saving
                  ? null
                  : (v) {
                      if (v != null) setState(() => _category = v);
                    },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amount,
              enabled: !_saving,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              validator: Validators.positiveAmount,
              decoration: const InputDecoration(
                labelText: 'المبلغ',
                suffixText: 'د.ت',
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _saving ? null : _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'التاريخ',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(DateFormatter.date(_date)),
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
                  : const Text('حفظ المصروف'),
            ),
          ],
        ),
      ),
    );
  }
}
