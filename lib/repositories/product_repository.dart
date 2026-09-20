import 'package:flutter/foundation.dart';

import '../models/enums.dart';
import '../models/product.dart';
import '../services/image_service.dart';
import '../services/local_storage_service.dart';
import 'activity_repository.dart';

/// Thrown when a sale needs more pieces than are in stock.
class InsufficientStockException implements Exception {
  const InsufficientStockException(this.productName, this.available);

  final String productName;
  final int available;
}

/// Products (furniture) stored locally. Keeps them in memory and notifies
/// listeners on every change, so lists, details and the dashboard refresh.
class ProductRepository extends ChangeNotifier {
  ProductRepository(this._storage, this._images, this._activities) {
    for (final map in _storage.getAll(LocalStorageService.productsBox)) {
      try {
        final product = Product.fromMap(map);
        _items[product.id] = product;
      } catch (_) {
        // Skip a corrupted record instead of crashing the app.
      }
    }
  }

  final LocalStorageService _storage;
  final ImageService _images;
  final ActivityRepository _activities;
  final Map<String, Product> _items = {};

  /// Active products, most recently updated first.
  List<Product> get all => _items.values.where((p) => p.isActive).toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  Product? byId(String id) => _items[id];

  /// Products (active or not) that use this category.
  int countInCategory(String categoryId) =>
      _items.values.where((p) => p.categoryId == categoryId).length;

  int get count => _items.values.where((p) => p.isActive).length;

  /// Stock value at purchase price (piece price x pieces in stock).
  double get inventoryValue => _items.values
      .where((p) => p.isActive)
      .fold(0.0, (sum, p) => sum + p.stockValue);

  /// Products that are low or out of stock, emptiest first.
  List<Product> lowStock(int threshold, {int limit = 5}) {
    final items = all
        .where((p) => p.stockStatus(threshold) != StockStatus.inStock)
        .toList()
      ..sort((a, b) => a.quantity.compareTo(b.quantity));
    return items.take(limit).toList();
  }

  Future<void> add(Product product) async {
    await _storage.put(
        LocalStorageService.productsBox, product.id, product.toMap());
    _items[product.id] = product;
    await _activities.log(ActivityType.productAdded, product.name);
    notifyListeners();
  }

  Future<void> update(Product product) async {
    await _storage.put(
        LocalStorageService.productsBox, product.id, product.toMap());
    _items[product.id] = product;
    notifyListeners();
  }

  /// Throws [InsufficientStockException] if any product has fewer pieces than
  /// requested. [quantities] maps product id -> pieces.
  void ensureStock(Map<String, int> quantities) {
    for (final entry in quantities.entries) {
      final product = _items[entry.key];
      if (product == null) throw StateError('Product not found: ${entry.key}');
      if (product.quantity < entry.value) {
        throw InsufficientStockException(product.name, product.quantity);
      }
    }
  }

  /// Removes the sold pieces from stock (all or nothing).
  Future<void> decreaseStock(Map<String, int> quantities) async {
    ensureStock(quantities);
    final now = DateTime.now();
    for (final entry in quantities.entries) {
      final product = _items[entry.key]!;
      final updated =
          product.copyWithQuantity(product.quantity - entry.value, updatedAt: now);
      await _storage.put(
          LocalStorageService.productsBox, updated.id, updated.toMap());
      _items[updated.id] = updated;
    }
    notifyListeners();
  }

  /// Adds bought pieces to an existing product. The purchase price becomes
  /// the weighted average of the old stock and the new pieces.
  Future<void> receiveStock(String id, int quantity, double unitCost) async {
    final product = _items[id];
    if (product == null) throw StateError('Product not found: $id');

    final newQuantity = product.quantity + quantity;
    final average = newQuantity <= 0
        ? unitCost
        : (product.purchasePrice * product.quantity + unitCost * quantity) /
            newQuantity;
    final updated = product.copyWithQuantity(
      newQuantity,
      purchasePrice: (average * 1000).round() / 1000,
    );
    await _storage.put(
        LocalStorageService.productsBox, updated.id, updated.toMap());
    _items[updated.id] = updated;
    notifyListeners();
  }

  /// Deletes the product and its image files.
  Future<void> delete(String id) async {
    final product = _items[id];
    if (product == null) return;
    await _storage.delete(LocalStorageService.productsBox, id);
    _items.remove(id);
    await _images.deleteAll(product.images);
    notifyListeners();
  }
}
