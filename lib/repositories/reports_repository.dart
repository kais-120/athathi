import 'package:flutter/material.dart' show DateTimeRange;

import '../models/report_data.dart';
import '../utils/report_calculator.dart';
import 'category_repository.dart';
import 'customer_repository.dart';
import 'expense_repository.dart';
import 'product_repository.dart';
import 'purchase_repository.dart';
import 'sale_repository.dart';
import 'settings_repository.dart';
import 'supplier_repository.dart';

/// التقارير: reads the other repositories and hands their data to the pure
/// [ReportCalculator]. Nothing is stored — every report is computed on demand.
///
/// Widgets should listen to all the source repositories to refresh.
class ReportsRepository {
  ReportsRepository({
    required SaleRepository sales,
    required PurchaseRepository purchases,
    required ExpenseRepository expenses,
    required ProductRepository products,
    required CategoryRepository categories,
    required CustomerRepository customers,
    required SupplierRepository suppliers,
    required SettingsRepository settings,
  })  : _sales = sales,
        _purchases = purchases,
        _expenses = expenses,
        _products = products,
        _categories = categories,
        _customers = customers,
        _suppliers = suppliers,
        _settings = settings;

  final SaleRepository _sales;
  final PurchaseRepository _purchases;
  final ExpenseRepository _expenses;
  final ProductRepository _products;
  final CategoryRepository _categories;
  final CustomerRepository _customers;
  final SupplierRepository _suppliers;
  final SettingsRepository _settings;

  SalesReport salesReport(DateTimeRange range) =>
      ReportCalculator.sales(_sales.all, range);

  ProfitReport profitReport(DateTimeRange range) =>
      ReportCalculator.profit(_sales.all, _expenses.all, range);

  PurchasesReport purchasesReport(DateTimeRange range) =>
      ReportCalculator.purchases(_purchases.all, range);

  ExpensesReport expensesReport(DateTimeRange range) =>
      ReportCalculator.expenses(_expenses.all, range);

  InventoryReport inventoryReport() => ReportCalculator.inventory(
        _products.all,
        _settings.current.lowStockThreshold,
        categoryName: _categories.nameOf,
      );

  /// What customers owe now (all time).
  DebtsReport customerDebts() => ReportCalculator.debts([
        for (final c in _customers.all)
          RankedItem(
            id: c.id,
            name: c.name,
            value: _customers.debtOf(c.id),
            note: c.phone,
          ),
      ]);

  /// What the shop owes suppliers now (all time).
  DebtsReport supplierDebts() => ReportCalculator.debts([
        for (final s in _suppliers.all)
          RankedItem(
            id: s.id,
            name: s.name,
            value: _suppliers.debtOf(s.id),
            note: s.phone,
          ),
      ]);

  bool productExists(String id) => _products.byId(id) != null;

  bool supplierExists(String id) => _suppliers.byId(id) != null;
}
