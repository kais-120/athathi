import 'package:flutter/foundation.dart';

import '../models/enums.dart';
import '../models/expense.dart';
import '../services/local_storage_service.dart';
import 'activity_repository.dart';

/// Shop expenses (transport, rent, repairs...).
class ExpenseRepository extends ChangeNotifier {
  ExpenseRepository(this._storage, this._activities) {
    for (final map in _storage.getAll(LocalStorageService.expensesBox)) {
      try {
        final expense = Expense.fromMap(map);
        _items[expense.id] = expense;
      } catch (_) {
        // Skip a corrupted record.
      }
    }
  }

  final LocalStorageService _storage;
  final ActivityRepository _activities;
  final Map<String, Expense> _items = {};

  /// Newest first.
  List<Expense> get all => _items.values.toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  Expense? byId(String id) => _items[id];

  Future<void> add(Expense expense) async {
    await _storage.put(
        LocalStorageService.expensesBox, expense.id, expense.toMap());
    _items[expense.id] = expense;
    await _activities.log(ActivityType.expenseAdded, expense.title);
    notifyListeners();
  }

  Future<void> update(Expense expense) async {
    await _storage.put(
        LocalStorageService.expensesBox, expense.id, expense.toMap());
    _items[expense.id] = expense;
    notifyListeners();
  }

  Future<void> delete(String id) async {
    if (_items.remove(id) == null) return;
    await _storage.delete(LocalStorageService.expensesBox, id);
    notifyListeners();
  }
}
