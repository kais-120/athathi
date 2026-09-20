import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/customer.dart';
import '../models/enums.dart';
import '../services/local_storage_service.dart';
import 'activity_repository.dart';
import 'payment_repository.dart';
import 'sale_repository.dart';

/// Thrown when deleting a customer who still owes money.
class CustomerHasDebtException implements Exception {
  const CustomerHasDebtException(this.debt);
  final double debt;
}

/// Customers (الحرفاء) + their debt balance.
///
/// debt = unpaid rest of the customer's sales − payments he made later.
/// Balances are computed on demand from sales and payments, so they can never
/// go out of sync. Widgets showing a debt should also listen to the sales and
/// payments repositories.
class CustomerRepository extends ChangeNotifier {
  CustomerRepository(
    this._storage,
    this._activities,
    this._sales,
    this._payments,
  ) {
    for (final map in _storage.getAll(LocalStorageService.customersBox)) {
      try {
        final customer = Customer.fromMap(map);
        _items[customer.id] = customer;
      } catch (_) {
        // Skip a corrupted record.
      }
    }
  }

  final LocalStorageService _storage;
  final ActivityRepository _activities;
  final SaleRepository _sales;
  final PaymentRepository _payments;
  final Map<String, Customer> _items = {};

  static double _round3(double v) => (v * 1000).round() / 1000;

  /// Sorted by name.
  List<Customer> get all => _items.values.toList()
    ..sort((a, b) => a.name.compareTo(b.name));

  int get count => _items.length;

  Customer? byId(String id) => _items[id];

  List<Customer> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where((c) => c.name.toLowerCase().contains(q) || c.phone.contains(q))
        .toList();
  }

  // ------------------------------------------------------------------ debts

  /// What the customer still owes (never negative).
  double debtOf(String customerId) => _round3(max(
      0.0, _sales.remainingFor(customerId) - _payments.totalFor(customerId)));

  /// What all customers owe together.
  double get totalDebts =>
      _round3(max(0.0, _sales.totalRemaining - _payments.total));

  int get debtorsCount => all.where((c) => debtOf(c.id) > 0).length;

  // ------------------------------------------------------------------- CRUD

  Future<void> add(Customer customer) async {
    await _storage.put(
        LocalStorageService.customersBox, customer.id, customer.toMap());
    _items[customer.id] = customer;
    await _activities.log(ActivityType.customerAdded, customer.name);
    notifyListeners();
  }

  Future<void> update(Customer customer) async {
    await _storage.put(
        LocalStorageService.customersBox, customer.id, customer.toMap());
    _items[customer.id] = customer;
    notifyListeners();
  }

  /// Deletes the customer. Past sales keep his name in the sales history.
  /// Throws [CustomerHasDebtException] if he still owes money.
  Future<void> delete(String id) async {
    final debt = debtOf(id);
    if (debt > 0) throw CustomerHasDebtException(debt);
    if (_items.remove(id) == null) return;
    await _storage.delete(LocalStorageService.customersBox, id);
    notifyListeners();
  }
}
