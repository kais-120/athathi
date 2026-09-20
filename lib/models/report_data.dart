import 'enums.dart';
import 'product.dart';

/// One slice of the time axis of a chart (a 3-hour block, a day or a month).
class ReportBucket {
  const ReportBucket({
    required this.start,
    required this.end,
    required this.label,
    required this.fullLabel,
  });

  final DateTime start;

  /// Exclusive.
  final DateTime end;

  /// Short label under the bar (e.g. `19/09`).
  final String label;

  /// Long label used in the details table (e.g. `السبت 19/09/2026`).
  final String fullLabel;

  bool contains(DateTime d) => !d.isBefore(start) && d.isBefore(end);
}

/// A name with a value, used for the ranked horizontal bars.
class RankedItem {
  const RankedItem({
    required this.name,
    required this.value,
    this.note = '',
    this.id,
  });

  final String name;
  final double value;
  final String note;

  /// Id of the product / customer / supplier when it can be opened.
  final String? id;
}

class MethodStat {
  const MethodStat({this.count = 0, this.total = 0});

  final int count;
  final double total;
}

class SalesReport {
  const SalesReport({
    required this.buckets,
    required this.totals,
    required this.count,
    required this.total,
    required this.collected,
    required this.remaining,
    required this.pieces,
    required this.byMethod,
    required this.topProducts,
  });

  final List<ReportBucket> buckets;

  /// Sales total per bucket.
  final List<double> totals;
  final int count;
  final double total;

  /// Paid at sale time.
  final double collected;

  /// Left unpaid at sale time (later customer payments are not deducted).
  final double remaining;
  final int pieces;
  final Map<PaymentMethod, MethodStat> byMethod;
  final List<RankedItem> topProducts;

  bool get isEmpty => count == 0;
  double get average => count == 0 ? 0 : total / count;
}

/// gross profit = Σ (unit price − unit cost) × quantity of the period's sales
/// net profit   = gross profit − expenses of the period
class ProfitReport {
  const ProfitReport({
    required this.buckets,
    required this.grossSeries,
    required this.expenseSeries,
    required this.salesCount,
    required this.revenue,
    required this.gross,
    required this.expenses,
    required this.itemsWithoutCost,
    required this.topProducts,
  });

  final List<ReportBucket> buckets;
  final List<double> grossSeries;
  final List<double> expenseSeries;
  final int salesCount;
  final double revenue;
  final double gross;
  final double expenses;

  /// Sold lines whose cost price was 0 (their profit may be overstated).
  final int itemsWithoutCost;
  final List<RankedItem> topProducts;

  bool get isEmpty => salesCount == 0 && expenses == 0;
  double get net => ((gross - expenses) * 1000).round() / 1000;
  double get costOfGoods => ((revenue - gross) * 1000).round() / 1000;

  /// Gross margin in percent.
  double get margin => revenue <= 0 ? 0 : gross / revenue * 100;
}

class PurchasesReport {
  const PurchasesReport({
    required this.buckets,
    required this.totals,
    required this.count,
    required this.total,
    required this.paid,
    required this.remaining,
    required this.pieces,
    required this.topSuppliers,
  });

  final List<ReportBucket> buckets;
  final List<double> totals;
  final int count;
  final double total;
  final double paid;
  final double remaining;
  final int pieces;
  final List<RankedItem> topSuppliers;

  bool get isEmpty => count == 0;
}

class ExpensesReport {
  const ExpensesReport({
    required this.buckets,
    required this.totals,
    required this.count,
    required this.total,
    required this.byCategory,
  });

  final List<ReportBucket> buckets;
  final List<double> totals;
  final int count;
  final double total;

  /// Biggest category first.
  final List<RankedItem> byCategory;

  bool get isEmpty => count == 0;
  double get average => count == 0 ? 0 : total / count;
}

class InventoryReport {
  const InventoryReport({
    required this.productsCount,
    required this.pieces,
    required this.costValue,
    required this.sellingValue,
    required this.lowCount,
    required this.outCount,
    required this.byCategory,
    required this.attention,
  });

  final int productsCount;
  final int pieces;

  /// Stock value at purchase price.
  final double costValue;

  /// Stock value at selling price.
  final double sellingValue;
  final int lowCount;
  final int outCount;

  /// Stock value (at cost) per category, biggest first.
  final List<RankedItem> byCategory;

  /// Low / out of stock products, emptiest first.
  final List<Product> attention;

  bool get isEmpty => productsCount == 0;
  double get expectedProfit => ((sellingValue - costValue) * 1000).round() / 1000;
}

class DebtsReport {
  const DebtsReport({required this.items, required this.total});

  /// Only parties that owe / are owed something, biggest first.
  final List<RankedItem> items;
  final double total;

  int get count => items.length;
  bool get isEmpty => items.isEmpty;
}
