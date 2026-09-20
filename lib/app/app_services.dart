import '../repositories/accounts_repository.dart';
import '../repositories/activity_repository.dart';
import '../repositories/category_repository.dart';
import '../repositories/customer_repository.dart';
import '../repositories/dashboard_repository.dart';
import '../repositories/expense_repository.dart';
import '../repositories/payment_repository.dart';
import '../repositories/product_repository.dart';
import '../repositories/purchase_repository.dart';
import '../repositories/reports_repository.dart';
import '../repositories/sale_repository.dart';
import '../repositories/settings_repository.dart';
import '../repositories/supplier_payment_repository.dart';
import '../repositories/supplier_repository.dart';
import '../services/auth_service.dart';
import '../services/backup_service.dart';
import '../services/biometric_service.dart';
import '../services/drive_service.dart';
import '../services/image_service.dart';
import '../services/local_storage_service.dart';

/// Composition root: creates every service/repository once at startup.
/// Later parts add their repositories here.
class AppServices {
  AppServices._({
    required this.storage,
    required this.auth,
    required this.biometric,
    required this.images,
    required this.settings,
    required this.activities,
    required this.products,
    required this.categories,
    required this.sales,
    required this.payments,
    required this.customers,
    required this.purchases,
    required this.supplierPayments,
    required this.suppliers,
    required this.expenses,
    required this.accounts,
    required this.dashboard,
    required this.reports,
    required this.backup,
  });

  final LocalStorageService storage;
  final AuthService auth;
  final BiometricService biometric;
  final ImageService images;
  final SettingsRepository settings;
  final ActivityRepository activities;
  final ProductRepository products;
  final CategoryRepository categories;
  final SaleRepository sales;
  final PaymentRepository payments;
  final CustomerRepository customers;
  final PurchaseRepository purchases;
  final SupplierPaymentRepository supplierPayments;
  final SupplierRepository suppliers;
  final ExpenseRepository expenses;
  final AccountsRepository accounts;
  final DashboardRepository dashboard;
  final ReportsRepository reports;
  final BackupService backup;

  /// [previous]: when the services are rebuilt after a restore, the open
  /// database and the Google session are reused.
  static Future<AppServices> init({AppServices? previous}) async {
    final storage = previous?.storage ?? LocalStorageService();
    await storage.init();

    final auth = AuthService(storage);
    await auth.ensureDefaultUser();

    final images = ImageService();
    await images.init();

    final settings = SettingsRepository(storage);
    final activities = ActivityRepository(storage);
    final products = ProductRepository(storage, images, activities);
    final categories = CategoryRepository(storage, products);
    await categories.seedDefaultsIfNeeded();
    final sales = SaleRepository(storage, products, activities);
    final payments = PaymentRepository(storage, activities);
    final customers = CustomerRepository(storage, activities, sales, payments);
    final purchases = PurchaseRepository(storage, products, activities);
    final supplierPayments = SupplierPaymentRepository(storage, activities);
    final suppliers = SupplierRepository(storage, purchases, supplierPayments);
    final expenses = ExpenseRepository(storage, activities);
    final accounts = AccountsRepository(
      sales: sales,
      payments: payments,
      customers: customers,
      purchases: purchases,
      supplierPayments: supplierPayments,
      suppliers: suppliers,
      expenses: expenses,
      settings: settings,
    );

    return AppServices._(
      storage: storage,
      auth: auth,
      biometric: BiometricService(),
      images: images,
      settings: settings,
      activities: activities,
      products: products,
      categories: categories,
      sales: sales,
      payments: payments,
      customers: customers,
      purchases: purchases,
      supplierPayments: supplierPayments,
      suppliers: suppliers,
      expenses: expenses,
      accounts: accounts,
      dashboard: DashboardRepository(
        products: products,
        sales: sales,
        customers: customers,
        activities: activities,
        settings: settings,
      ),
      reports: ReportsRepository(
        sales: sales,
        purchases: purchases,
        expenses: expenses,
        products: products,
        categories: categories,
        customers: customers,
        suppliers: suppliers,
        settings: settings,
      ),
      backup: BackupService(
        storage: storage,
        images: images,
        settings: settings,
        activities: activities,
        drive: previous?.backup.drive ?? DriveService(),
      ),
    );
  }
}
