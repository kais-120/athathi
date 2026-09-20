import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/supplier.dart';
import '../services/local_storage_service.dart';
import 'purchase_repository.dart';
import 'supplier_payment_repository.dart';

/// Thrown when deleting a supplier the shop still owes money to.
class SupplierHasDebtException implements Exception {
  const SupplierHasDebtException(this.debt);
  final double debt;
}

/// Suppliers (الموردون) + what the shop owes them.
///
/// debt = unpaid rest of the purchases from the supplier − payments made to
/// him later. Computed on demand, so it never goes out of sync.
class SupplierRepository extends ChangeNotifier {
  SupplierRepository(this._storage, this._purchases, this._payments) {
    for (final map in _storage.getAll(LocalStorageService.suppliersBox)) {
      try {
        final supplier = Supplier.fromMap(map);
        _items[supplier.id] = supplier;
      } catch (_) {
        // Skip a corrupted record.
      }
    }
  }

  final LocalStorageService _storage;
  final PurchaseRepository _purchases;
  final SupplierPaymentRepository _payments;
  final Map<String, Supplier> _items = {};

  static double _round3(double v) => (v * 1000).round() / 1000;

  /// Sorted by name.
  List<Supplier> get all => _items.values.toList()
    ..sort((a, b) => a.name.compareTo(b.name));

  int get count => _items.length;

  Supplier? byId(String id) => _items[id];

  List<Supplier> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where((s) => s.name.toLowerCase().contains(q) || s.phone.contains(q))
        .toList();
  }

  double debtOf(String supplierId) => _round3(max(
      0.0, _purchases.remainingFor(supplierId) - _payments.totalFor(supplierId)));

  double get totalDebts =>
      _round3(max(0.0, _purchases.totalRemaining - _payments.total));

  int get debtorsCount => all.where((s) => debtOf(s.id) > 0).length;

  Future<void> add(Supplier supplier) async {
    await _storage.put(
        LocalStorageService.suppliersBox, supplier.id, supplier.toMap());
    _items[supplier.id] = supplier;
    notifyListeners();
  }

  Future<void> update(Supplier supplier) async {
    await _storage.put(
        LocalStorageService.suppliersBox, supplier.id, supplier.toMap());
    _items[supplier.id] = supplier;
    notifyListeners();
  }

  /// Past purchases keep the supplier's name. Throws
  /// [SupplierHasDebtException] while the shop still owes him money.
  Future<void> delete(String id) async {
    final debt = debtOf(id);
    if (debt > 0) throw SupplierHasDebtException(debt);
    if (_items.remove(id) == null) return;
    await _storage.delete(LocalStorageService.suppliersBox, id);
    notifyListeners();
  }
}
