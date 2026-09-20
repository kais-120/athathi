import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../models/enums.dart';
import '../../models/product.dart';
import '../../utils/id_generator.dart';
import '../../utils/measure_formatter.dart';
import '../../utils/validators.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/product_image.dart';
import '../categories/category_dialog.dart';
import 'image_viewer_screen.dart';

/// Add / edit a product. [productId] == null means "add".
class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.productId});

  final String? productId;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _purchasePrice = TextEditingController();
  final _sellingPrice = TextEditingController();
  final _quantity = TextEditingController(text: '1');
  final _length = TextEditingController();
  final _width = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();

  late final AppServices _services;
  Product? _existing;
  String? _category; // category id
  ProductCondition _condition = ProductCondition.good;

  /// Stored image file names; the first one is the main image.
  List<String> _images = [];
  Set<String> _originalImages = {};

  bool _saving = false;
  bool _saved = false;

  bool get _isEdit => widget.productId != null;

  @override
  void initState() {
    super.initState();
    _services = AppScope.of(context);

    final id = widget.productId;
    final product = id == null ? null : _services.products.byId(id);
    if (product != null) {
      _existing = product;
      _name.text = product.name;
      _description.text = product.description;
      // A category that no longer exists must be chosen again.
      _category = _services.categories.byId(product.categoryId) == null
          ? null
          : product.categoryId;
      _condition = product.condition;
      _purchasePrice.text = product.purchasePrice == 0
          ? ''
          : MeasureFormatter.number(product.purchasePrice);
      _sellingPrice.text = MeasureFormatter.number(product.sellingPrice);
      _quantity.text = '${product.quantity}';
      _length.text = _measureText(product.length);
      _width.text = _measureText(product.width);
      _height.text = _measureText(product.height);
      _weight.text = _measureText(product.weight);
      _images = List.of(product.images);
      _originalImages = product.images.toSet();
    }
  }

  @override
  void dispose() {
    // Leaving without saving: discard pictures added during this session.
    if (!_saved) {
      final added =
          _images.where((n) => !_originalImages.contains(n)).toList();
      _services.images.deleteAll(added);
    }
    for (final c in [
      _name,
      _description,
      _purchasePrice,
      _sellingPrice,
      _quantity,
      _length,
      _width,
      _height,
      _weight,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String _measureText(double? v) => v == null ? '' : MeasureFormatter.number(v);

  /// Optional numeric field: empty / zero / invalid -> null.
  double? _optional(TextEditingController c) {
    final v = Validators.parseNumber(c.text);
    return (v == null || v <= 0) ? null : v;
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ---------------------------------------------------------------- images

  Future<void> _addFromCamera() => _pick(() async {
        final name = await _services.images.takePhoto();
        return name == null ? <String>[] : [name];
      });

  Future<void> _addFromGallery() => _pick(_services.images.pickFromGallery);

  Future<void> _pick(Future<List<String>> Function() picker) async {
    try {
      final names = await picker();
      if (!mounted) {
        await _services.images.deleteAll(names);
        return;
      }
      if (names.isNotEmpty) setState(() => _images.addAll(names));
    } on Exception {
      if (mounted) {
        _snack('تعذر الوصول إلى الكاميرا أو الصور. تحقق من أذونات التطبيق.');
      }
    }
  }

  void _removeImage(int index) {
    final name = _images[index];
    setState(() => _images.removeAt(index));
    // Pictures added in this session can be deleted right away; original
    // ones are only deleted when the product is saved.
    if (!_originalImages.contains(name)) _services.images.delete(name);
  }

  void _makeMain(int index) {
    setState(() {
      final name = _images.removeAt(index);
      _images.insert(0, name);
    });
  }

  void _preview(int index) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            ImageViewerScreen(images: List.of(_images), initialIndex: index),
      ),
    );
  }

  Future<void> _addCategory() async {
    final created = await showCategoryDialog(context);
    if (created != null && mounted) setState(() => _category = created.id);
  }

  // ----------------------------------------------------------------- save

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final existing = _existing;

      final product = Product(
        id: existing?.id ?? IdGenerator.next(),
        name: _name.text.trim(),
        description: _description.text.trim(),
        categoryId: _category!,
        condition: _condition,
        purchasePrice: Validators.parseNumber(_purchasePrice.text) ?? 0,
        sellingPrice: Validators.parseNumber(_sellingPrice.text) ?? 0,
        quantity: Validators.parseInt(_quantity.text) ?? 0,
        length: _optional(_length),
        width: _optional(_width),
        height: _optional(_height),
        weight: _optional(_weight),
        images: List.of(_images),
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
        isActive: existing?.isActive ?? true,
      );

      if (existing == null) {
        await _services.products.add(product);
      } else {
        await _services.products.update(product);
        await _services.images.deleteAll(
          _originalImages.where((n) => !_images.contains(n)),
        );
      }

      _saved = true;
      if (!mounted) return;
      _snack(existing == null
          ? 'تمت إضافة المنتج بنجاح'
          : 'تم تحديث المنتج بنجاح');
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('تعذر حفظ المنتج، حاول مرة أخرى');
    }
  }

  // ------------------------------------------------------------------ UI

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    String? suffix,
    String? helper,
    bool decimal = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_saving,
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
    if (_isEdit && _existing == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تعديل منتج')),
        body: const EmptyState(
          icon: Icons.search_off_rounded,
          title: 'المنتج غير موجود',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'تعديل منتج' : 'إضافة منتج')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            _Section(
              title: 'الصور',
              child: _buildImages(context),
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'المعلومات الأساسية',
              child: Column(
                children: [
                  TextFormField(
                    controller: _name,
                    enabled: !_saving,
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
                    onChanged:
                        _saving ? null : (v) => setState(() => _category = v),
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: _saving ? null : _addCategory,
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
                    onChanged: _saving
                        ? null
                        : (v) {
                            if (v != null) setState(() => _condition = v);
                          },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _description,
                    enabled: !_saving,
                    minLines: 3,
                    maxLines: 5,
                    textInputAction: TextInputAction.newline,
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(
                      labelText: 'الوصف',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'الأسعار والكمية',
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _numberField(
                          controller: _purchasePrice,
                          label: 'سعر الشراء',
                          suffix: 'د.ت',
                          validator: Validators.optionalNumber,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _numberField(
                          controller: _sellingPrice,
                          label: 'سعر البيع',
                          suffix: 'د.ت',
                          validator: Validators.sellingPrice,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _numberField(
                    controller: _quantity,
                    label: 'الكمية',
                    helper: 'عدد القطع',
                    decimal: false,
                    validator: Validators.quantity,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'الأبعاد والوزن',
              subtitle:
                  'معلومات اختيارية للوصف فقط، ولا تؤثر على الكمية أو السعر.',
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _numberField(
                          controller: _length,
                          label: 'الطول — اختياري',
                          suffix: 'سم',
                          validator: Validators.optionalNumber,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _numberField(
                          controller: _width,
                          label: 'العرض — اختياري',
                          suffix: 'سم',
                          validator: Validators.optionalNumber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _numberField(
                          controller: _height,
                          label: 'الارتفاع — اختياري',
                          suffix: 'سم',
                          validator: Validators.optionalNumber,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _numberField(
                          controller: _weight,
                          label: 'الوزن — اختياري',
                          suffix: 'كغ',
                          validator: Validators.optionalNumber,
                        ),
                      ),
                    ],
                  ),
                ],
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
                  : const Text('حفظ المنتج'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImages(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_images.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'لم تتم إضافة صور بعد (اختياري)',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          )
        else ...[
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) => Stack(
                children: [
                  GestureDetector(
                    onTap: () => _preview(i),
                    child: ProductImage(fileName: _images[i], size: 100),
                  ),
                  if (i == 0)
                    PositionedDirectional(
                      top: 4,
                      start: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'الرئيسية',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  PositionedDirectional(
                    bottom: 4,
                    end: 4,
                    child: Row(
                      children: [
                        if (i != 0)
                          _RoundIconButton(
                            icon: Icons.star_outline_rounded,
                            tooltip: 'تعيين كصورة رئيسية',
                            onPressed: _saving ? null : () => _makeMain(i),
                          ),
                        const SizedBox(width: 4),
                        _RoundIconButton(
                          icon: Icons.delete_outline,
                          tooltip: 'حذف الصورة',
                          onPressed: _saving ? null : () => _removeImage(i),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        OutlinedButton.icon(
          onPressed: _saving ? null : _addFromCamera,
          icon: const Icon(Icons.photo_camera_outlined),
          label: const Text('إضافة صورة من الكاميرا'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _saving ? null : _addFromGallery,
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text('اختيار صورة من الهاتف'),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black54,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
