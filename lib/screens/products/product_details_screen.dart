import 'dart:io';

import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/product.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';
import '../../utils/measure_formatter.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/statistic_card.dart';
import '../../widgets/status_badge.dart';
import 'image_viewer_screen.dart';
import 'product_actions.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key, required this.productId});

  final String productId;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  late final AppServices _services;

  @override
  void initState() {
    super.initState();
    _services = AppScope.of(context);
  }

  Future<void> _delete(Product product) async {
    final deleted = await confirmAndDeleteProduct(context, _services, product);
    if (deleted && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _services.products,
      builder: (context, _) {
        final product = _services.products.byId(widget.productId);
        if (product == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('تفاصيل المنتج')),
            body: const EmptyState(
              icon: Icons.search_off_rounded,
              title: 'المنتج غير موجود',
            ),
          );
        }
        return _buildDetails(context, product);
      },
    );
  }

  Widget _buildDetails(BuildContext context, Product product) {
    final theme = Theme.of(context);
    final threshold = _services.settings.current.lowStockThreshold;
    final profitColor =
        product.profitPerUnit >= 0 ? AppColors.success : AppColors.danger;

    final specs = <(String, String)>[
      if (product.length != null)
        ('الطول', MeasureFormatter.cm(product.length!)),
      if (product.width != null) ('العرض', MeasureFormatter.cm(product.width!)),
      if (product.height != null)
        ('الارتفاع', MeasureFormatter.cm(product.height!)),
      if (product.weight != null)
        ('الوزن', MeasureFormatter.kg(product.weight!)),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل المنتج')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _Gallery(images: product.images),
          const SizedBox(height: 16),
          Text(
            product.name,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            _services.categories.nameOf(product.categoryId),
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusBadge.condition(product.condition),
              StatusBadge.stock(product.stockStatus(threshold)),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 12.0;
              final width = (constraints.maxWidth - gap) / 2;
              Widget tile(StatisticCard card) =>
                  SizedBox(width: width, child: card);
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  tile(StatisticCard(
                    label: 'سعر الشراء',
                    value: CurrencyFormatter.format(product.purchasePrice),
                    icon: Icons.shopping_cart_outlined,
                    color: AppColors.info,
                  )),
                  tile(StatisticCard(
                    label: 'سعر البيع',
                    value: CurrencyFormatter.format(product.sellingPrice),
                    icon: Icons.sell_outlined,
                    color: AppColors.seed,
                  )),
                  tile(StatisticCard(
                    label: 'الكمية',
                    value: '${product.quantity} قطعة',
                    icon: Icons.inventory_2_outlined,
                    color: AppColors.warning,
                  )),
                  tile(StatisticCard(
                    label: 'الربح المتوقع للقطعة',
                    value: CurrencyFormatter.format(product.profitPerUnit),
                    icon: Icons.trending_up_rounded,
                    color: profitColor,
                  )),
                  SizedBox(
                    width: constraints.maxWidth,
                    child: StatisticCard(
                      label: 'إجمالي الربح المتوقع',
                      value: CurrencyFormatter.format(
                          product.totalEstimatedProfit),
                      icon: Icons.account_balance_wallet_outlined,
                      color: profitColor,
                    ),
                  ),
                ],
              );
            },
          ),
          if (product.description.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            _InfoCard(
              title: 'الوصف',
              child: Text(product.description,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.6)),
            ),
          ],
          if (specs.isNotEmpty) ...[
            const SizedBox(height: 16),
            _InfoCard(
              title: 'الأبعاد والوزن',
              child: Column(
                children: [
                  for (var i = 0; i < specs.length; i++) ...[
                    if (i > 0) const Divider(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Text(specs[i].$1,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                        ),
                        Text(specs[i].$2,
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'تاريخ الإضافة: ${DateFormatter.dateTime(product.createdAt)}\n'
            'آخر تعديل: ${DateFormatter.dateTime(product.updatedAt)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.productForm,
                    arguments: product.id,
                  ),
                  child: const Text('تعديل'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: product.quantity < 1
                      ? null
                      : () => Navigator.pushNamed(
                            context,
                            AppRoutes.newSale,
                            arguments: product.id,
                          ),
                  child: const Text('بيع'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(
                        color: theme.colorScheme.error.withValues(alpha: 0.5)),
                  ),
                  onPressed: () => _delete(product),
                  child: const Text('حذف'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Swipeable picture gallery with a counter; tap opens the full-screen viewer.
class _Gallery extends StatefulWidget {
  const _Gallery({required this.images});

  final List<String> images;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final images = AppScope.of(context).images;

    if (widget.images.isEmpty) {
      return AspectRatio(
        aspectRatio: 4 / 3,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chair_outlined,
                  size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 8),
              Text('لا توجد صور لهذا المنتج',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 4 / 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              itemCount: widget.images.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => ImageViewerScreen(
                      images: widget.images,
                      initialIndex: i,
                    ),
                  ),
                ),
                child: Image.file(
                  File(images.pathOf(widget.images[i])),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: theme.colorScheme.primaryContainer,
                    child: Icon(Icons.broken_image_outlined,
                        size: 48, color: theme.colorScheme.primary),
                  ),
                ),
              ),
            ),
            if (widget.images.length > 1)
              PositionedDirectional(
                bottom: 10,
                start: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_index + 1} / ${widget.images.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.child});

  final String title;
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
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
