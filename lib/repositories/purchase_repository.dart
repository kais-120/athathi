import 'package:flutter/foundation.dart';

import '../models/enums.dart';
import '../models/product.dart';
import '../models/purchase.dart';
import '../models/supplier.dart';
import '../services/local_storage_service.dart';
import '../utils/id_generator.dart';
import 'activity_repository.dart';
import 'product_repository.dart';

/// A product that does not exist yet and is created by the purchase.
class NewProductDraft {
  const NewProductDraft({
    required this.name,
    required this.categoryId,
    required this.condition,
    required this.sellingPrice,
  });

  final String name;
  final String categoryId;
  final ProductCondition condition;
  final double sellingPrice;
}

/// One line being prepared for a purchase: either an existing [product]
/// (its stock increases) or a [draft] (a new product is created).
class PurchaseDraftLine {
  const PurchaseDraftLine({
    this.product,
    this.draft,
    required this.quantity,
    required this.unitCost,
  }) : assert((product == null) != (draft == null),
            'A line needs either an existing product or a new product draft');

  final Product? product;
  final NewProductDraft? draft;
  final int quantity;
  final double unitCost;

  String get name => product?.name ?? draft!.name;
  bool get isNewProduct => draft != null;
  double get total => unitCost * quantity;
}

/// Purchases of furniture from suppliers. Confirming a purchase adds the
/// pieces to the stock (creating the product when it is new).
class PurchaseRepository extends ChangeNotifier {
  PurchaseRepository(this._storage, this._products, this._activities) {
    for (final map in _storage.getAll(LocalStorageService.purchasesBox)) {
      try {
        final purchase = Purchase.fromMap(map);
        _items[purchase.id] = purchase;
      } catch (_) {
        // Skip a corrupted record.
      }
    }
  }

  final LocalStorageService _storage;
  final ProductRepository _products;
  final ActivityRepository _activities;
  final Map<String, Purchase> _items = {};

  static double _round3(double v) => (v * 1000).round() / 1000;

  /// Newest first.
  List<Purchase> get all => _items.values.toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Purchase? byId(String id) => _items[id];

  List<Purchase> forSupplier(String supplierId) =>
      all.where((p) => p.supplierId == supplierId).toList();

  /// Unpaid rest of the purchases of one supplier (before later payments).
  double remainingFor(String supplierId) => _items.values
      .where((p) => p.supplierId == supplierId)
      .fold(0.0, (sum, p) => sum + p.remaining);

  /// Unpaid rest of all purchases.
  double get totalRemaining =>
      _items.values.fold(0.0, (sum, p) => sum + p.remaining);

  Future<Purchase> create({
    required List<PurchaseDraftLine> lines,
    Supplier? supplier,
    required double paid,
    String notes = '',
  }) async {
    if (lines.isEmpty) throw ArgumentError('A purchase needs at least one line');

    final items = <PurchaseItem>[];
    for (final line in lines) {
      final String productId;
      final existing = line.product;
      if (existing != null) {
        await _products.receiveStock(existing.id, line.quantity, line.unitCost);
        productId = existing.id;
      } else {
        final draft = line.draft!;
        final product = Product(
          id: IdGenerator.next(),
          name: draft.name,
          categoryId: draft.categoryId,
          condition: draft.condition,
          purchasePrice: line.unitCost,
          sellingPrice: draft.sellingPrice,
          quantity: line.quantity,
        );
        await _products.add(product);
        productId = product.id;
      }
      items.add(PurchaseItem(
        name: line.name,
        quantity: line.quantity,
        unitCost: line.unitCost,
        productId: productId,
      ));
    }

    final purchase = Purchase(
      id: IdGenerator.next(),
      supplierId: supplier?.id,
      supplierName: supplier?.name,
      items: items,
      total: _round3(items.fold(0.0, (sum, i) => sum + i.lineTotal)),
      paid: _round3(paid),
      notes: notes,
      createdAt: DateTime.now(),
    );

    await _storage.put(
        LocalStorageService.purchasesBox, purchase.id, purchase.toMap());
    _items[purchase.id] = purchase;
    await _activities.log(ActivityType.purchaseMade, purchase.displaySupplier);
    notifyListeners();
    return purchase;
  }
}
