import 'package:flutter/foundation.dart';

import '../models/enums.dart';
import '../models/payment.dart';
import '../services/local_storage_service.dart';
import '../utils/currency_formatter.dart';
import 'activity_repository.dart';

/// Payments received from customers against their debts.
class PaymentRepository extends ChangeNotifier {
  PaymentRepository(this._storage, this._activities) {
    for (final map in _storage.getAll(LocalStorageService.paymentsBox)) {
      try {
        final payment = Payment.fromMap(map);
        _items[payment.id] = payment;
      } catch (_) {
        // Skip a corrupted record.
      }
    }
  }

  final LocalStorageService _storage;
  final ActivityRepository _activities;
  final Map<String, Payment> _items = {};

  /// Newest first.
  List<Payment> get all => _items.values.toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<Payment> forCustomer(String customerId) =>
      all.where((p) => p.customerId == customerId).toList();

  double totalFor(String customerId) => _items.values
      .where((p) => p.customerId == customerId)
      .fold(0.0, (sum, p) => sum + p.amount);

  /// Sum of every payment received.
  double get total => _items.values.fold(0.0, (sum, p) => sum + p.amount);

  Future<void> add(Payment payment, {required String customerName}) async {
    await _storage.put(
        LocalStorageService.paymentsBox, payment.id, payment.toMap());
    _items[payment.id] = payment;
    await _activities.log(
      ActivityType.paymentRecorded,
      '$customerName • ${CurrencyFormatter.format(payment.amount)}',
    );
    notifyListeners();
  }

  /// Removes a payment (wrongly entered): the customer's debt goes back up.
  Future<void> delete(String id) async {
    if (_items.remove(id) == null) return;
    await _storage.delete(LocalStorageService.paymentsBox, id);
    notifyListeners();
  }
}
