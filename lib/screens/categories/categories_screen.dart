import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../models/product_category.dart';
import '../../repositories/category_repository.dart';
import '../../widgets/empty_state.dart';
import 'category_dialog.dart';

/// التصنيفات: list, add, rename and delete product categories.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late final AppServices _services;

  @override
  void initState() {
    super.initState();
    _services = AppScope.of(context);
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _add() async {
    final saved = await showCategoryDialog(context);
    if (saved != null && mounted) _snack('تمت إضافة التصنيف «${saved.name}»');
  }

  Future<void> _edit(ProductCategory category) async {
    final saved = await showCategoryDialog(context, existing: category);
    if (saved != null && mounted) _snack('تم تعديل التصنيف');
  }

  Future<void> _delete(ProductCategory category) async {
    final count = _services.categories.productCount(category.id);
    if (count > 0) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('لا يمكن حذف التصنيف'),
          content: Text(
            'التصنيف «${category.name}» مستعمل في $count منتج.\n'
            'غيّر تصنيف هذه المنتجات أولًا ثم أعد المحاولة.',
            style: const TextStyle(height: 1.6),
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('حسنًا'),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف التصنيف'),
        content: Text('هل تريد حذف التصنيف «${category.name}»؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              minimumSize: const Size(100, 44),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _services.categories.delete(category.id);
      if (mounted) _snack('تم حذف التصنيف');
    } on CategoryInUseException {
      if (mounted) _snack('لا يمكن حذف تصنيف مستعمل في منتجات');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('التصنيفات')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('إضافة تصنيف'),
      ),
      body: ListenableBuilder(
        listenable:
            Listenable.merge([_services.categories, _services.products]),
        builder: (context, _) {
          final categories = _services.categories.all;
          if (categories.isEmpty) {
            return EmptyState(
              icon: Icons.category_outlined,
              title: 'لا توجد تصنيفات',
              message: 'أضف تصنيفات لتنظيم منتجاتك',
              actionLabel: 'إضافة تصنيف',
              onAction: _add,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final category = categories[index];
              final count = _services.categories.productCount(category.id);
              return Card(
                child: ListTile(
                  onTap: () => _edit(category),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.primary,
                    child: const Icon(Icons.category_outlined),
                  ),
                  title: Text(category.name,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle:
                      Text(count == 0 ? 'لا توجد منتجات' : '$count منتج'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'تعديل',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _edit(category),
                      ),
                      IconButton(
                        tooltip: 'حذف',
                        icon: Icon(Icons.delete_outline,
                            color: theme.colorScheme.error),
                        onPressed: () => _delete(category),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
