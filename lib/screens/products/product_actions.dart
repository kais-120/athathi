import 'package:flutter/material.dart';

import '../../app/app_services.dart';
import '../../models/product.dart';

/// Asks for confirmation, then deletes the product (and its images).
/// Returns true if the product was deleted.
Future<bool> confirmAndDeleteProduct(
  BuildContext context,
  AppServices services,
  Product product,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final scheme = Theme.of(dialogContext).colorScheme;
      return AlertDialog(
        icon: Icon(Icons.delete_outline, color: scheme.error, size: 36),
        title: const Text('حذف المنتج'),
        content: Text(
          'هل تريد حذف "${product.name}" وجميع صوره؟ لا يمكن التراجع عن هذا الإجراء.',
        ),
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
  if (confirmed != true) return false;

  await services.products.delete(product.id);
  if (context.mounted) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('تم حذف المنتج')));
  }
  return true;
}
