import 'dart:io';

import 'package:flutter/material.dart';

import '../app/app_scope.dart';

/// Product picture loaded from the app's local image folder, or a furniture
/// placeholder when the product has no image (or the file is missing).
///
/// [fileName] is the stored image name (see `ImageService`).
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    this.fileName,
    this.size = 72,
    this.borderRadius = 12,
  });

  final String? fileName;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = Container(
      width: size,
      height: size,
      color: scheme.primaryContainer.withValues(alpha: 0.5),
      child: Icon(Icons.chair_outlined, size: size * 0.45, color: scheme.primary),
    );

    final name = fileName;
    if (name == null || name.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: placeholder,
      );
    }

    final path = AppScope.of(context).images.pathOf(name);
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.file(
        File(path),
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: (size * pixelRatio).round(),
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }
}
