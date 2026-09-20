import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../app/routes.dart';
import '../../models/product.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/product_image.dart';
import '../../widgets/quantity_stepper.dart';
import '../../widgets/search_field.dart';
import 'cart_controller.dart';
import 'checkout_screen.dart';

/// POS step 1: search products and fill the cart.
/// [initialProductId] pre-fills the cart (used by the "بيع" button of the
/// product details screen).
class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key, this.initialProductId});

  final String? initialProductId;

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  final CartController _cart = CartController();
  late final AppServices _services;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _services = AppScope.of(context);
    final id = widget.initialProductId;
    final product = id == null ? null : _services.products.byId(id);
    if (product != null) _cart.add(product);
  }

  @override
  void dispose() {
    _cart.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _add(Product product) {
    if (!_cart.add(product)) _snack('وصلت إلى الكمية المتوفرة في المخزون');
  }

  Future<bool?> _confirmDiscard() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إلغاء عملية البيع'),
        content: const Text('السلة تحتوي على منتجات. هل تريد إلغاء العملية؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('متابعة البيع'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              minimumSize: const Size(100, 44),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('إلغاء العملية'),
          ),
        ],
      ),
    );
  }

  List<Product> _available() {
    final query = _query.trim().toLowerCase();
    return _services.products.all.where((p) {
      if (p.quantity < 1) return false;
      if (query.isEmpty) return true;
      return p.name.toLowerCase().contains(query) ||
          _services.categories.nameOf(p.categoryId).contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_services.products, _cart]),
      builder: (context, _) {
        final products = _available();
        final hasAnyStock = _services.products.all.any((p) => p.quantity > 0);

        return PopScope(
          canPop: _cart.isEmpty,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            final leave = await _confirmDiscard();
            if (leave == true && context.mounted) Navigator.pop(context);
          },
          child: Scaffold(
            appBar: AppBar(title: const Text('بيع جديد')),
            body: !hasAnyStock
                ? EmptyState(
                    icon: Icons.chair_outlined,
                    title: 'لا توجد منتجات متوفرة للبيع',
                    message: 'أضف منتجات إلى المخزون أولًا',
                    actionLabel: 'إضافة منتج',
                    onAction: () =>
                        Navigator.pushNamed(context, AppRoutes.productForm),
                  )
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: SearchField(
                          onChanged: (v) => setState(() => _query = v),
                        ),
                      ),
                      Expanded(
                        child: products.isEmpty
                            ? const EmptyState(
                                icon: Icons.search_off_rounded,
                                title: 'لا توجد نتائج مطابقة',
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                itemCount: products.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, i) => _PosProductTile(
                                  product: products[i],
                                  inCart: _cart.quantityOf(products[i].id),
                                  onAdd: () => _add(products[i]),
                                  onQuantity: (q) =>
                                      _cart.setQuantity(products[i].id, q),
                                ),
                              ),
                      ),
                    ],
                  ),
            bottomNavigationBar: _cart.isEmpty
                ? null
                : _CartBar(
                    cart: _cart,
                    onContinue: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => CheckoutScreen(cart: _cart),
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }
}

class _PosProductTile extends StatelessWidget {
  const _PosProductTile({
    required this.product,
    required this.inCart,
    required this.onAdd,
    required this.onQuantity,
  });

  final Product product;
  final int inCart;
  final VoidCallback onAdd;
  final ValueChanged<int> onQuantity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ProductImage(fileName: product.mainImage, size: 64),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyFormatter.format(product.sellingPrice),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'المتوفر: ${product.quantity}',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (inCart == 0)
              FilledButton.tonal(
                style: FilledButton.styleFrom(minimumSize: const Size(72, 40)),
                onPressed: onAdd,
                child: const Text('إضافة'),
              )
            else
              QuantityStepper(
                quantity: inCart,
                max: product.quantity,
                onChanged: onQuantity,
              ),
          ],
        ),
      ),
    );
  }
}

class _CartBar extends StatelessWidget {
  const _CartBar({required this.cart, required this.onContinue});

  final CartController cart;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.white,
      elevation: 8,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Icon(Icons.shopping_cart_outlined,
                  color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('السلة: ${cart.pieces} قطعة',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                    Text(
                      CurrencyFormatter.format(cart.total),
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(130, 48)),
                onPressed: onContinue,
                child: const Text('متابعة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
