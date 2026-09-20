import 'package:flutter/material.dart';

import '../screens/backup/backup_screen.dart';
import '../screens/categories/categories_screen.dart';
import '../screens/customers/customer_details_screen.dart';
import '../screens/customers/customer_form_screen.dart';
import '../screens/dashboard/main_shell.dart';
import '../screens/expenses/expense_form_screen.dart';
import '../screens/expenses/expenses_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/products/product_details_screen.dart';
import '../screens/products/product_form_screen.dart';
import '../screens/purchases/new_purchase_screen.dart';
import '../screens/purchases/purchase_details_screen.dart';
import '../screens/purchases/purchases_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/sales/new_sale_screen.dart';
import '../screens/sales/sale_details_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/suppliers/supplier_details_screen.dart';
import '../screens/suppliers/supplier_form_screen.dart';
import '../screens/suppliers/suppliers_screen.dart';

/// Named routes.
class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String settings = '/settings';

  /// arguments: `String?` product id (null = add a new product).
  static const String productForm = '/products/form';

  /// arguments: `String` product id.
  static const String productDetails = '/products/details';

  /// arguments: `String?` product id to put in the cart first.
  static const String newSale = '/sales/new';

  /// arguments: `String` sale id.
  static const String saleDetails = '/sales/details';

  /// arguments: `String?` customer id (null = add a new customer).
  static const String customerForm = '/customers/form';

  /// arguments: `String` customer id.
  static const String customerDetails = '/customers/details';

  static const String purchases = '/purchases';
  static const String purchaseNew = '/purchases/new';

  /// arguments: `String` purchase id.
  static const String purchaseDetails = '/purchases/details';

  static const String suppliers = '/suppliers';

  /// arguments: `String?` supplier id (null = add a new supplier).
  static const String supplierForm = '/suppliers/form';

  /// arguments: `String` supplier id.
  static const String supplierDetails = '/suppliers/details';

  static const String expenses = '/expenses';

  /// arguments: `String?` expense id (null = add a new expense).
  static const String expenseForm = '/expenses/form';

  static const String categories = '/categories';
  static const String reports = '/reports';
  static const String backup = '/backup';

  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    final Widget page = switch (routeSettings.name) {
      AppRoutes.login => const LoginScreen(),
      AppRoutes.dashboard => const MainShell(),
      AppRoutes.settings => const SettingsScreen(),
      AppRoutes.productForm =>
        ProductFormScreen(productId: routeSettings.arguments as String?),
      AppRoutes.productDetails =>
        ProductDetailsScreen(productId: routeSettings.arguments as String),
      AppRoutes.newSale =>
        NewSaleScreen(initialProductId: routeSettings.arguments as String?),
      AppRoutes.saleDetails =>
        SaleDetailsScreen(saleId: routeSettings.arguments as String),
      AppRoutes.customerForm =>
        CustomerFormScreen(customerId: routeSettings.arguments as String?),
      AppRoutes.customerDetails =>
        CustomerDetailsScreen(customerId: routeSettings.arguments as String),
      AppRoutes.purchases => const PurchasesScreen(),
      AppRoutes.purchaseNew => const NewPurchaseScreen(),
      AppRoutes.purchaseDetails =>
        PurchaseDetailsScreen(purchaseId: routeSettings.arguments as String),
      AppRoutes.suppliers => const SuppliersScreen(),
      AppRoutes.supplierForm =>
        SupplierFormScreen(supplierId: routeSettings.arguments as String?),
      AppRoutes.supplierDetails =>
        SupplierDetailsScreen(supplierId: routeSettings.arguments as String),
      AppRoutes.expenses => const ExpensesScreen(),
      AppRoutes.expenseForm =>
        ExpenseFormScreen(expenseId: routeSettings.arguments as String?),
      AppRoutes.categories => const CategoriesScreen(),
      AppRoutes.reports => const ReportsScreen(),
      AppRoutes.backup => const BackupScreen(),
      _ => const LoginScreen(),
    };
    return MaterialPageRoute<void>(settings: routeSettings, builder: (_) => page);
  }
}
