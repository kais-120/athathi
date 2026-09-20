import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../models/enums.dart';
import '../../models/product.dart';
import '../../repositories/purchase_repository.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/measure_formatter.dart';
import '../../utils/validators.dart';
import '../../widgets/product_image.dart';
import '../categories/category_dialog.dart';
import 'product_picker_sheet.dart';

/// One purchase line: an existing product (its stock increases) or a NEW
/// product (created when the purchase is confirmed).
/// Pops a [PurchaseDraftLine], or null if cancelled.
class PurchaseLineScreen extends StatefulWidget {
  const PurchaseLineScreen({super.key, this.initial});

  final PurchaseDraftLine? initial;

  @override
  State<PurchaseLineScreen> createState() => _PurchaseLineScreenState();
}

class _PurchaseLineScreenState extends State<PurchaseLineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _sellingPrice = TextEditingController();
  final _quantity = TextEditingController(text: '1');
  final _unitCost = TextEditingController();

  late final AppServices _services;
  bool _isNew = false;
  Product? _product;
  String? _category; // category id
  ProductCondition _condition = ProductCondition.good;
  bool _productMissing = false;

  @override
  void initState() {
    super.initState();
    _services = AppScope.of(context);
    final line = widget.initial;
    if (line != null) {
      _quantity.text = '${line.quantity}';
      _unitCost.text = MeasureFormatter.number(line.unitCost);
      _isNew = line.isNewProduct;
      _product = line.product;
      final draft = line.draft;
      if (draft != null) {
        _name.text = draft.name;
        _category = _services.categories.byId(draft.categoryId) == null
            ? null
            : draft.categoryId;
        _condition = draft.condition;
        _sellingPrice.text = MeasureFormatter.number(draft.sellingPrice);
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _sellingPrice.dispose();
    _quantity.dispose();
    _unitCost.dispose();
    super.dispose();
  }

  Future<void> _addCategory() async {
    final created = await showCategoryDialog(context);
    if (created != null && mounted) setState(() => _category = created.id);
  }

  Future<void> _chooseProduct() async {
    final product = await showProductPicker(context);
    if (product == null || !mounted) return;
    setState(() {
      _product = product;
      _productMissing = false;
      if (_unitCost.text.trim().isEmpty && product.purchasePrice > 0) {
        _unitCost.text = MeasureFormatter.number(product.purchasePrice);
      }
    });
  }

  void _submit() {
    final valid = _formKey.currentState!.validate();
    if (!_isNew && _product == null) {
      setState(() => _productMissing = true);
      return;
    }
    if (!valid) return;

    final quantity = Validators.parseInt(_quantity.text) ?? 1;
    final unitCost = Validators.parseNumber(_unitCost.text) ?? 0;

    final line = _isNew
        ? PurchaseDraftLine(
            draft: NewProductDraft(
              name: _name.text.trim(),
              categoryId: _category!,
              condition: _condition,
              sellingPrice: Validators.parseNumber(_sellingPrice.text) ?? 0,
            ),
            quantity: quantity,
            unitCost: unitCost,
          )
        : PurchaseDraftLine(
            product: _product,
            quantity: quantity,
            unitCost: unitCost,
          );
    Navigator.pop(context, line);
  }

  Widget _number(
    TextEditingController controller,
    String label, {
    String? suffix,
    bool decimal = true,
    String? helper,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
            RegExp(decimal ? r'[0-9.,]' : r'[0-9]')),
      ],
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        helperText: helper,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? 'إضافة منتج للشراء' : 'تعديل السطر'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: false, label: Text('منتج موجود')),
                ButtonSegment(value: true, label: Text('منتج جديد')),
              ],
              selected: {_isNew},
              onSelectionChanged: (s) => setState(() {
                _isNew = s.first;
                _productMissing = false;
              }),
            ),
            const SizedBox(height: 16),
            if (!_isNew) ...[
              Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _chooseProduct,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ProductImage(fileName: _product?.mainImage, size: 52),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _product?.name ?? 'اختيار منتج من المخزون',
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                _product == null
                                    ? 'ستضاف القطع المشتراة إلى مخزونه'
                                    : 'في المخزون: ${_product!.quantity} قطعة',
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
              if (_productMissing)
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: 12, left: 12),
                  child: Text('اختر منتجًا',
                      style: TextStyle(
                          color: theme.colorScheme.error, fontSize: 12)),
                ),
            ] else ...[
              TextFormField(
                controller: _name,
                textInputAction: TextInputAction.next,
                validator: Validators.productName,
                decoration: const InputDecoration(labelText: 'اسم المنتج'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _category,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'التصنيف'),
                validator: Validators.category,
                items: [
                  for (final c in _services.categories.all)
                    DropdownMenuItem(value: c.id, child: Text(c.name)),
                ],
                onChanged: (v) => setState(() => _category = v),
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: _addCategory,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('إضافة تصنيف جديد'),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ProductCondition>(
                // ignore: deprecated_member_use
                value: _condition,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'الحالة'),
                items: [
                  for (final c in ProductCondition.values)
                    DropdownMenuItem(value: c, child: Text(c.label)),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _condition = v);
                },
              ),
              const SizedBox(height: 16),
              _number(_sellingPrice, 'سعر البيع',
                  suffix: 'د.ت', validator: Validators.sellingPrice),
            ],
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _number(_quantity, 'الكمية',
                      decimal: false,
                      helper: 'عدد القطع',
                      validator: Validators.positiveQuantity),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _number(_unitCost, 'سعر الشراء للقطعة',
                      suffix: 'د.ت',
                      validator: Validators.purchasePrice),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListenableBuilder(
              listenable: Listenable.merge([_quantity, _unitCost]),
              builder: (context, _) {
                final qty = Validators.parseInt(_quantity.text) ?? 0;
                final cost = Validators.parseNumber(_unitCost.text) ?? 0;
                return Text(
                  'إجمالي السطر: ${CurrencyFormatter.format(qty * cost)}',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                );
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submit,
              child: Text(widget.initial == null ? 'إضافة إلى الشراء' : 'حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}
