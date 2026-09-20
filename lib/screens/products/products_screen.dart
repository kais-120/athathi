import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../app/routes.dart';
import '../../models/product.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/product_card.dart';
import '../../widgets/search_field.dart';
import 'product_actions.dart';
import 'product_filter.dart';

/// Product management: search, filters, list with عرض / تعديل / حذف.
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late final AppServices _services;
  String _query = '';
  ProductFilter _filter = const ProductFilter();

  @override
  void initState() {
    super.initState();
    _services = AppScope.of(context);
  }

  void _openForm([String? productId]) =>
      Navigator.pushNamed(context, AppRoutes.productForm, arguments: productId);

  void _openDetails(String productId) => Navigator.pushNamed(
      context, AppRoutes.productDetails,
      arguments: productId);

  Future<void> _chooseFilter() async {
    final result = await showProductFilterSheet(context, _filter);
    if (result != null && mounted) setState(() => _filter = result);
  }

  List<Product> _apply(List<Product> all) {
    final threshold = _services.settings.current.lowStockThreshold;
    final query = _query.trim().toLowerCase();

    return all.where((p) {
      if (_filter.categoryId != null && p.categoryId != _filter.categoryId) {
        return false;
      }
      if (_filter.condition != null && p.condition != _filter.condition) {
        return false;
      }
      if (_filter.stock != null && p.stockStatus(threshold) != _filter.stock) {
        return false;
      }
      if (query.isEmpty) return true;
      return p.name.toLowerCase().contains(query) ||
          p.description.toLowerCase().contains(query) ||
          _services.categories.nameOf(p.categoryId).contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المنتجات'),
        actions: [
          IconButton(
            tooltip: 'التصنيفات',
            icon: const Icon(Icons.category_outlined),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.categories),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add),
        label: const Text('إضافة منتج'),
      ),
      body: ListenableBuilder(
        listenable:
            Listenable.merge([_services.products, _services.categories]),
        builder: (context, _) {
          final all = _services.products.all;
          if (all.isEmpty) {
            return EmptyState(
              icon: Icons.chair_outlined,
              title: 'لا توجد منتجات مسجلة',
              message: 'ابدأ بإضافة أول قطعة أثاث إلى المخزون',
              actionLabel: 'إضافة منتج',
              onAction: _openForm,
            );
          }

          final products = _apply(all);
          final threshold = _services.settings.current.lowStockThreshold;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: SearchField(
                        onChanged: (value) => setState(() => _query = value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: IconButton.filledTonal(
                        tooltip: 'تصفية',
                        onPressed: _chooseFilter,
                        icon: Badge(
                          isLabelVisible: _filter.isActive,
                          label: Text('${_filter.count}'),
                          child: const Icon(Icons.tune_rounded),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_filter.isActive)
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      if (_filter.categoryId != null)
                        _filterChip(
                            _services.categories.nameOf(_filter.categoryId), () {
                          setState(() => _filter = _filter.withoutCategory());
                        }),
                      if (_filter.condition != null)
                        _filterChip(_filter.condition!.label, () {
                          setState(() => _filter = _filter.withoutCondition());
                        }),
                      if (_filter.stock != null)
                        _filterChip(_filter.stock!.label, () {
                          setState(() => _filter = _filter.withoutStock());
                        }),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    'عدد المنتجات: ${products.length}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ),
              Expanded(
                child: products.isEmpty
                    ? const EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'لا توجد نتائج مطابقة',
                        message: 'جرّب تغيير كلمات البحث أو إزالة التصفية',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                        itemCount: products.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return ProductCard(
                            product: product,
                            lowStockThreshold: threshold,
                            categoryName:
                                _services.categories.nameOf(product.categoryId),
                            onView: () => _openDetails(product.id),
                            onEdit: () => _openForm(product.id),
                            onDelete: () => confirmAndDeleteProduct(
                                context, _services, product),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _filterChip(String label, VoidCallback onDeleted) => Padding(
        padding: const EdgeInsetsDirectional.only(end: 8),
        child: InputChip(
          label: Text(label),
          onDeleted: onDeleted,
          deleteButtonTooltipMessage: 'إزالة',
        ),
      );
}
