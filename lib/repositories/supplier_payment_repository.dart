import 'package:flutter/foundation.dart';

import '../models/enums.dart';
import '../models/supplier_payment.dart';
import '../services/local_storage_service.dart';
import '../utils/currency_formatter.dart';
import 'activity_repository.dart';

/// Payments made to suppliers against the shop's debt to them.
class SupplierPaymentRepository extends ChangeNotifier {
  SupplierPaymentRepository(this._storage, this._activities) {
    for (final map
        in _storage.getAll(LocalStorageService.supplierPaymentsBox)) {
      try {
        final payment = SupplierPayment.fromMap(map);
        _items[payment.id] = payment;
      } catch (_) {
        // Skip a corrupted record.
      }
    }
  }

  final LocalStorageService _storage;
  final ActivityRepository _activities;
  final Map<String, SupplierPayment> _items = {};

  /// Newest first.
  List<SupplierPayment> get all => _items.values.toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<SupplierPayment> forSupplier(String supplierId) =>
      all.where((p) => p.supplierId == supplierId).toList();

  double totalFor(String supplierId) => _items.values
      .where((p) => p.supplierId == supplierId)
      .fold(0.0, (sum, p) => sum + p.amount);

  double get total => _items.values.fold(0.0, (sum, p) => sum + p.amount);

  Future<void> add(SupplierPayment payment, {required String supplierName}) async {
    await _storage.put(
        LocalStorageService.supplierPaymentsBox, payment.id, payment.toMap());
    _items[payment.id] = payment;
    await _activities.log(
      ActivityType.paymentRecorded,
      'دفعة للمورد $supplierName • ${CurrencyFormatter.format(payment.amount)}',
    );
    notifyListeners();
  }

  /// Removes a wrongly entered payment: the debt to the supplier goes up.
  Future<void> delete(String id) async {
    if (_items.remove(id) == null) return;
    await _storage.delete(LocalStorageService.supplierPaymentsBox, id);
    notifyListeners();
  }
}
