import 'package:flutter/foundation.dart';

import '../models/product_category.dart';
import '../services/local_storage_service.dart';
import '../utils/id_generator.dart';
import 'product_repository.dart';

/// Thrown when deleting a category that still has products.
class CategoryInUseException implements Exception {
  const CategoryInUseException(this.name, this.productCount);

  final String name;
  final int productCount;
}

/// Product categories (add / rename / delete / list), stored locally.
class CategoryRepository extends ChangeNotifier {
  CategoryRepository(this._storage, this._products) {
    for (final map in _storage.getAll(LocalStorageService.categoriesBox)) {
      try {
        final category = ProductCategory.fromMap(map);
        _items[category.id] = category;
      } catch (_) {
        // Skip a corrupted record.
      }
    }
  }

  /// Shown for a product whose category no longer exists.
  static const String unknownName = 'بدون تصنيف';

  /// Marker stored INSIDE the categories box (so it travels with backups):
  /// the default categories were already created once.
  static const String _seededKey = '__seeded';

  static const int maxNameLength = 40;

  final LocalStorageService _storage;
  final ProductRepository _products;
  final Map<String, ProductCategory> _items = {};

  /// Creates the default categories the first time only. A restored old
  /// backup (without categories) is seeded again on the next start.
  Future<void> seedDefaultsIfNeeded() async {
    final box = _storage.box(LocalStorageService.categoriesBox);
    if (box.get(_seededKey) == true) return;

    if (_items.isEmpty) {
      final base = DateTime(2020);
      for (var i = 0; i < ProductCategory.defaults.length; i++) {
        final (id, name) = ProductCategory.defaults[i];
        final category = ProductCategory(
          id: id,
          name: name,
          createdAt: base.add(Duration(minutes: i)),
        );
        await _storage.put(
            LocalStorageService.categoriesBox, id, category.toMap());
        _items[id] = category;
      }
    }
    await box.put(_seededKey, true);
    notifyListeners();
  }

  /// In creation order (defaults first, then the user's own).
  List<ProductCategory> get all => _items.values.toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  ProductCategory? byId(String? id) => id == null ? null : _items[id];

  String nameOf(String? id) => byId(id)?.name ?? unknownName;

  int productCount(String id) => _products.countInCategory(id);

  static String _clean(String name) => name.trim().replaceAll(RegExp(r'\s+'), ' ');

  /// True when another category already has this name.
  bool nameExists(String name, {String? exceptId}) {
    final wanted = _clean(name);
    return _items.values
        .any((c) => c.id != exceptId && _clean(c.name) == wanted);
  }

  Future<ProductCategory> add(String name) async {
    final category = ProductCategory(
      id: IdGenerator.next(),
      name: _clean(name),
      createdAt: DateTime.now(),
    );
    await _storage.put(
        LocalStorageService.categoriesBox, category.id, category.toMap());
    _items[category.id] = category;
    notifyListeners();
    return category;
  }

  Future<ProductCategory> rename(String id, String name) async {
    final existing = _items[id];
    if (existing == null) throw StateError('Category not found: $id');
    final updated = existing.copyWith(name: _clean(name));
    await _storage.put(
        LocalStorageService.categoriesBox, id, updated.toMap());
    _items[id] = updated;
    notifyListeners();
    return updated;
  }

  /// Throws [CategoryInUseException] while products still use the category.
  Future<void> delete(String id) async {
    final existing = _items[id];
    if (existing == null) return;
    final count = productCount(id);
    if (count > 0) throw CategoryInUseException(existing.name, count);
    await _storage.delete(LocalStorageService.categoriesBox, id);
    _items.remove(id);
    notifyListeners();
  }
}
