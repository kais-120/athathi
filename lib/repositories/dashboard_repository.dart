import '../models/activity_item.dart';
import '../models/product.dart';
import '../models/sale.dart';
import 'activity_repository.dart';
import 'customer_repository.dart';
import 'product_repository.dart';
import 'sale_repository.dart';
import 'settings_repository.dart';

/// Everything the dashboard displays.
class DashboardData {
  const DashboardData({
    required this.todaySales,
    required this.salesCount,
    required this.todayProfit,
    required this.inventoryValue,
    required this.customerDebts,
    required this.productsCount,
    required this.recentSales,
    required this.lowStock,
    required this.recentActivity,
  });

  final double todaySales;
  final int salesCount;
  final double todayProfit;
  final double inventoryValue;
  final double customerDebts;
  final int productsCount;
  final List<Sale> recentSales;
  final List<Product> lowStock;
  final List<ActivityItem> recentActivity;
}

/// Every figure is read from the local database.
/// `customerDebts` = unpaid rest of all sales minus the payments received.
class DashboardRepository {
  DashboardRepository({
    required this.products,
    required this.sales,
    required this.customers,
    required this.activities,
    required this.settings,
  });

  final ProductRepository products;
  final SaleRepository sales;
  final CustomerRepository customers;
  final ActivityRepository activities;
  final SettingsRepository settings;

  Future<DashboardData> load() async {
    return DashboardData(
      todaySales: sales.todayTotal,
      salesCount: sales.todayCount,
      todayProfit: sales.todayProfit,
      inventoryValue: products.inventoryValue,
      customerDebts: customers.totalDebts,
      productsCount: products.count,
      recentSales: sales.recent(4),
      lowStock: products.lowStock(settings.current.lowStockThreshold),
      recentActivity: activities.recent(),
    );
  }
}
