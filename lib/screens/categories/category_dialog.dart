import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../models/product_category.dart';
import '../../repositories/category_repository.dart';

/// Add (when [existing] is null) or rename a category.
/// Returns the saved [ProductCategory], or null when cancelled.
Future<ProductCategory?> showCategoryDialog(
  BuildContext context, {
  ProductCategory? existing,
}) {
  return showDialog<ProductCategory>(
    context: context,
    builder: (_) => _CategoryDialog(existing: existing),
  );
}

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({this.existing});

  final ProductCategory? existing;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late final CategoryRepository _categories;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _categories = AppScope.of(context).categories;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'اسم التصنيف مطلوب';
    if (name.length > CategoryRepository.maxNameLength) {
      return 'الاسم طويل جدًا (${CategoryRepository.maxNameLength} حرفًا كحد أقصى)';
    }
    if (_categories.nameExists(name, exceptId: widget.existing?.id)) {
      return 'يوجد تصنيف بهذا الاسم';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final existing = widget.existing;
      final saved = existing == null
          ? await _categories.add(_name.text)
          : await _categories.rename(existing.id, _name.text);
      if (mounted) Navigator.pop(context, saved);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تعذر حفظ التصنيف')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'تعديل التصنيف' : 'إضافة تصنيف'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _name,
          enabled: !_saving,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _save(),
          validator: _validate,
          decoration: const InputDecoration(labelText: 'اسم التصنيف'),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(110, 44)),
          onPressed: _saving ? null : _save,
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
