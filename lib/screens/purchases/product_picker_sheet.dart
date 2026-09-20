import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../models/product.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/product_image.dart';
import '../../widgets/search_field.dart';

/// Bottom sheet to choose an existing product (stock will be added to it).
/// Returns null if dismissed.
Future<Product?> showProductPicker(BuildContext context) {
  return showModalBottomSheet<Product>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const FractionallySizedBox(
      heightFactor: 0.85,
      child: _ProductSheet(),
    ),
  );
}

class _ProductSheet extends StatefulWidget {
  const _ProductSheet();

  @override
  State<_ProductSheet> createState() => _ProductSheetState();
}

class _ProductSheetState extends State<_ProductSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _query.trim().toLowerCase();
    final services = AppScope.of(context);
    final products = services.products.all.where((p) {
      return query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          services.categories.nameOf(p.categoryId).contains(query);
    }).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('اختيار منتج',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                SearchField(onChanged: (v) => setState(() => _query = v)),
              ],
            ),
          ),
          Expanded(
            child: products.isEmpty
                ? const EmptyState(
                    icon: Icons.chair_outlined,
                    title: 'لا توجد منتجات مطابقة',
                    message: 'يمكنك إنشاء منتج جديد مباشرة من سطر الشراء',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: products.length,
                    itemBuilder: (context, i) {
                      final p = products[i];
                      return ListTile(
                        leading: ProductImage(fileName: p.mainImage, size: 48),
                        title: Text(p.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                            'في المخزون: ${p.quantity} • شراء: ${CurrencyFormatter.format(p.purchasePrice)}'),
                        onTap: () => Navigator.pop(context, p),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
