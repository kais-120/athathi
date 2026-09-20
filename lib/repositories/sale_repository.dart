import 'package:flutter/foundation.dart';

import '../models/customer.dart';
import '../models/enums.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';
import '../services/local_storage_service.dart';
import '../utils/id_generator.dart';
import 'activity_repository.dart';
import 'product_repository.dart';

/// Sales history + creation of new sales (which also reduces the stock).
class SaleRepository extends ChangeNotifier {
  SaleRepository(this._storage, this._products, this._activities) {
    for (final map in _storage.getAll(LocalStorageService.salesBox)) {
      try {
        final sale = Sale.fromMap(map);
        _items[sale.id] = sale;
      } catch (_) {
        // Skip a corrupted record.
      }
    }
  }

  final LocalStorageService _storage;
  final ProductRepository _products;
  final ActivityRepository _activities;
  final Map<String, Sale> _items = {};

  /// Newest first.
  List<Sale> get all => _items.values.toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Sale? byId(String id) => _items[id];

  List<Sale> recent(int limit) => all.take(limit).toList();

  int get nextNumber =>
      _items.values.fold<int>(0, (max, s) => s.number > max ? s.number : max) +
      1;

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  Iterable<Sale> get _today =>
      _items.values.where((s) => _isToday(s.createdAt));

  double get todayTotal => _today.fold(0.0, (sum, s) => sum + s.total);
  int get todayCount => _today.length;
  double get todayProfit => _today.fold(0.0, (sum, s) => sum + s.profit);

  /// Money customers still owe from all sales.
  /// (PART 4 subtracts the payments registered afterwards.)
  double get totalRemaining =>
      _items.values.fold(0.0, (sum, s) => sum + s.remaining);

  /// Sales of one customer, newest first.
  List<Sale> forCustomer(String customerId) =>
      all.where((s) => s.customerId == customerId).toList();

  /// Unpaid rest of the customer's sales (before his later payments).
  double remainingFor(String customerId) => _items.values
      .where((s) => s.customerId == customerId)
      .fold(0.0, (sum, s) => sum + s.remaining);

  /// Creates the sale and removes the sold pieces from stock.
  /// Throws [InsufficientStockException] if the stock is not enough.
  Future<Sale> create({
    required List<SaleItem> items,
    Customer? customer,
    required PaymentMethod method,
    required double paid,
    String notes = '',
  }) async {
    if (items.isEmpty) throw ArgumentError('A sale needs at least one item');

    final quantities = <String, int>{};
    for (final item in items) {
      quantities[item.productId] =
          (quantities[item.productId] ?? 0) + item.quantity;
    }
    _products.ensureStock(quantities);

    final total = _round3(items.fold(0.0, (sum, i) => sum + i.lineTotal));
    final sale = Sale(
      id: IdGenerator.next(),
      number: nextNumber,
      customerId: customer?.id,
      customerName: customer?.name,
      items: items,
      total: total,
      paid: _round3(paid),
      method: method,
      notes: notes,
      createdAt: DateTime.now(),
    );

    await _storage.put(LocalStorageService.salesBox, sale.id, sale.toMap());
    _items[sale.id] = sale;
    await _products.decreaseStock(quantities);
    await _activities.log(ActivityType.saleMade, 'عملية رقم ${sale.number}');
    notifyListeners();
    return sale;
  }

  static double _round3(double v) => (v * 1000).round() / 1000;
}
