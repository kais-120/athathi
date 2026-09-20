import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../models/enums.dart';

/// Active filters of the product list.
class ProductFilter {
  const ProductFilter({this.categoryId, this.condition, this.stock});

  /// Id of a category.
  final String? categoryId;
  final ProductCondition? condition;
  final StockStatus? stock;

  int get count =>
      (categoryId != null ? 1 : 0) +
      (condition != null ? 1 : 0) +
      (stock != null ? 1 : 0);

  bool get isActive => count > 0;

  ProductFilter withoutCategory() =>
      ProductFilter(condition: condition, stock: stock);

  ProductFilter withoutCondition() =>
      ProductFilter(categoryId: categoryId, stock: stock);

  ProductFilter withoutStock() =>
      ProductFilter(categoryId: categoryId, condition: condition);
}

/// Bottom sheet with the three filters: التصنيف / الحالة / حالة المخزون.
/// Returns the new filter, or null if dismissed.
Future<ProductFilter?> showProductFilterSheet(
  BuildContext context,
  ProductFilter current,
) {
  return showModalBottomSheet<ProductFilter>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _FilterSheet(initial: current),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});

  final ProductFilter initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? _category = widget.initial.categoryId;
  late ProductCondition? _condition = widget.initial.condition;
  late StockStatus? _stock = widget.initial.stock;

  Widget _group<T>({
    required String title,
    required List<T> values,
    required String Function(T) label,
    required T? selected,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in values)
              ChoiceChip(
                label: Text(label(value)),
                selected: value == selected,
                onSelected: (isSelected) =>
                    onChanged(isSelected ? value : null),
              ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = AppScope.of(context).categories;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('تصفية المنتجات',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _group<String>(
              title: 'التصنيف',
              values: [for (final c in categories.all) c.id],
              label: categories.nameOf,
              selected: _category,
              onChanged: (v) => setState(() => _category = v),
            ),
            _group<ProductCondition>(
              title: 'الحالة',
              values: ProductCondition.values,
              label: (v) => v.label,
              selected: _condition,
              onChanged: (v) => setState(() => _condition = v),
            ),
            _group<StockStatus>(
              title: 'حالة المخزون',
              values: StockStatus.values,
              label: (v) => v.label,
              selected: _stock,
              onChanged: (v) => setState(() => _stock = v),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.pop(context, const ProductFilter()),
                    child: const Text('إعادة تعيين'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(
                      context,
                      ProductFilter(
                        categoryId: _category,
                        condition: _condition,
                        stock: _stock,
                      ),
                    ),
                    child: const Text('تطبيق'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
