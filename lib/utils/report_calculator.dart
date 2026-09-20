import 'package:flutter/material.dart' show DateTimeRange;

import '../models/enums.dart';
import '../models/expense.dart';
import '../models/product.dart';
import '../models/purchase.dart';
import '../models/report_data.dart';
import '../models/sale.dart';
import 'date_formatter.dart';
import 'period.dart';

/// Pure calculations behind PART 6 (no Hive, no widgets) so they can be unit
/// tested. Every period report takes a `[start, end)` range.
class ReportCalculator {
  ReportCalculator._();

  /// Tunisian month names.
  static const List<String> monthNames = [
    'جانفي',
    'فيفري',
    'مارس',
    'أفريل',
    'ماي',
    'جوان',
    'جويلية',
    'أوت',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  static const String uncategorized = 'بدون تصنيف';

  static double round3(double v) => (v * 1000).round() / 1000;

  static String _two(int n) => n.toString().padLeft(2, '0');

  // ---------------------------------------------------------------- buckets

  /// Time axis of [range]: 8 blocks of 3 hours for a single day, one bucket
  /// per day up to 31 days, one per month beyond that.
  static List<ReportBucket> buckets(DateTimeRange range) {
    final start = DateTime(range.start.year, range.start.month, range.start.day);
    var days = 0;
    var cursor = start;
    while (cursor.isBefore(range.end)) {
      cursor = DateTime(cursor.year, cursor.month, cursor.day + 1);
      days++;
    }
    if (days <= 1) return _hourBuckets(start);
    if (days <= 31) return _dayBuckets(start, days);
    return _monthBuckets(start, range.end);
  }

  static List<ReportBucket> _hourBuckets(DateTime day) {
    return [
      for (var i = 0; i < 8; i++)
        ReportBucket(
          start: DateTime(day.year, day.month, day.day, i * 3),
          end: DateTime(day.year, day.month, day.day, i * 3 + 3),
          label: '${_two(i * 3)}:00',
          fullLabel: '${_two(i * 3)}:00 – ${_two(i * 3 + 3)}:00',
        ),
    ];
  }

  static List<ReportBucket> _dayBuckets(DateTime first, int days) {
    return [
      for (var i = 0; i < days; i++)
        () {
          final s = DateTime(first.year, first.month, first.day + i);
          return ReportBucket(
            start: s,
            end: DateTime(s.year, s.month, s.day + 1),
            label: days <= 10 ? '${_two(s.day)}/${_two(s.month)}' : _two(s.day),
            fullLabel: DateFormatter.dayHeader(s),
          );
        }(),
    ];
  }

  static List<ReportBucket> _monthBuckets(DateTime first, DateTime end) {
    final lastInstant = end.subtract(const Duration(milliseconds: 1));
    final result = <ReportBucket>[];
    var month = DateTime(first.year, first.month);
    while (!month.isAfter(lastInstant)) {
      final next = DateTime(month.year, month.month + 1);
      result.add(ReportBucket(
        start: month,
        end: next,
        label: '${_two(month.month)}/${_two(month.year % 100)}',
        fullLabel: '${monthNames[month.month - 1]} ${month.year}',
      ));
      month = next;
    }
    return result;
  }

  /// Sums [valueOf] of [items] into [buckets] (items outside every bucket are
  /// ignored).
  static List<double> series<T>(
    List<ReportBucket> buckets,
    Iterable<T> items,
    DateTime Function(T) dateOf,
    double Function(T) valueOf,
  ) {
    final values = List<double>.filled(buckets.length, 0);
    for (final item in items) {
      final date = dateOf(item);
      for (var i = 0; i < buckets.length; i++) {
        if (buckets[i].contains(date)) {
          values[i] += valueOf(item);
          break;
        }
      }
    }
    return [for (final v in values) round3(v)];
  }

  static List<RankedItem> _ranked(Map<String, _Acc> map, String noteUnit,
      {int? limit}) {
    final list = map.values.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = limit == null ? list : list.take(limit).toList();
    return [
      for (final a in top)
        RankedItem(
          id: a.id,
          name: a.name,
          value: round3(a.value),
          note: '${a.count} $noteUnit',
        ),
    ];
  }

  // ------------------------------------------------------------------ sales

  static SalesReport sales(Iterable<Sale> allSales, DateTimeRange range) {
    final list =
        allSales.where((s) => Period.contains(range, s.createdAt)).toList();
    final buckets = ReportCalculator.buckets(range);

    var total = 0.0;
    var collected = 0.0;
    var remaining = 0.0;
    var pieces = 0;
    final counts = {for (final m in PaymentMethod.values) m: 0};
    final totals = {for (final m in PaymentMethod.values) m: 0.0};
    final products = <String, _Acc>{};

    for (final sale in list) {
      total += sale.total;
      collected += sale.paid;
      remaining += sale.remaining;
      counts[sale.method] = counts[sale.method]! + 1;
      totals[sale.method] = totals[sale.method]! + sale.total;
      for (final item in sale.items) {
        pieces += item.quantity;
        final key = item.productId.isEmpty ? item.productName : item.productId;
        final acc = products.putIfAbsent(
            key,
            () => _Acc(
                id: item.productId.isEmpty ? null : item.productId,
                name: item.productName));
        acc.value += item.lineTotal;
        acc.count += item.quantity;
      }
    }

    return SalesReport(
      buckets: buckets,
      totals: series<Sale>(buckets, list, (s) => s.createdAt, (s) => s.total),
      count: list.length,
      total: round3(total),
      collected: round3(collected),
      remaining: round3(remaining),
      pieces: pieces,
      byMethod: {
        for (final m in PaymentMethod.values)
          m: MethodStat(count: counts[m]!, total: round3(totals[m]!)),
      },
      topProducts: _ranked(products, 'قطعة', limit: 5),
    );
  }

  // ----------------------------------------------------------------- profit

  static ProfitReport profit(
    Iterable<Sale> allSales,
    Iterable<Expense> allExpenses,
    DateTimeRange range,
  ) {
    final sales =
        allSales.where((s) => Period.contains(range, s.createdAt)).toList();
    final expenses = allExpenses
        .where((e) => Period.contains(range, e.createdAt))
        .toList();
    final buckets = ReportCalculator.buckets(range);

    var revenue = 0.0;
    var gross = 0.0;
    var withoutCost = 0;
    final products = <String, _Acc>{};
    for (final sale in sales) {
      revenue += sale.total;
      gross += sale.profit;
      for (final item in sale.items) {
        if (item.unitCost <= 0) withoutCost++;
        final key = item.productId.isEmpty ? item.productName : item.productId;
        final acc = products.putIfAbsent(
            key,
            () => _Acc(
                id: item.productId.isEmpty ? null : item.productId,
                name: item.productName));
        acc.value += item.lineProfit;
        acc.count += item.quantity;
      }
    }

    return ProfitReport(
      buckets: buckets,
      grossSeries:
          series<Sale>(buckets, sales, (s) => s.createdAt, (s) => s.profit),
      expenseSeries: series<Expense>(
          buckets, expenses, (e) => e.createdAt, (e) => e.amount),
      salesCount: sales.length,
      revenue: round3(revenue),
      gross: round3(gross),
      expenses: round3(expenses.fold(0.0, (sum, e) => sum + e.amount)),
      itemsWithoutCost: withoutCost,
      topProducts: _ranked(products, 'قطعة', limit: 5),
    );
  }

  // -------------------------------------------------------------- purchases

  static PurchasesReport purchases(
      Iterable<Purchase> allPurchases, DateTimeRange range) {
    final list = allPurchases
        .where((p) => Period.contains(range, p.createdAt))
        .toList();
    final buckets = ReportCalculator.buckets(range);

    var total = 0.0;
    var paid = 0.0;
    var remaining = 0.0;
    var pieces = 0;
    final suppliers = <String, _Acc>{};
    for (final p in list) {
      total += p.total;
      paid += p.paid;
      remaining += p.remaining;
      pieces += p.pieces;
      final acc = suppliers.putIfAbsent(p.supplierId ?? '',
          () => _Acc(id: p.supplierId, name: p.displaySupplier));
      acc.value += p.total;
      acc.count += 1;
    }

    return PurchasesReport(
      buckets: buckets,
      totals:
          series<Purchase>(buckets, list, (p) => p.createdAt, (p) => p.total),
      count: list.length,
      total: round3(total),
      paid: round3(paid),
      remaining: round3(remaining),
      pieces: pieces,
      topSuppliers: _ranked(suppliers, 'عملية', limit: 5),
    );
  }

  // --------------------------------------------------------------- expenses

  static ExpensesReport expenses(
      Iterable<Expense> allExpenses, DateTimeRange range) {
    final list = allExpenses
        .where((e) => Period.contains(range, e.createdAt))
        .toList();
    final buckets = ReportCalculator.buckets(range);

    final categories = <String, _Acc>{};
    var total = 0.0;
    for (final e in list) {
      total += e.amount;
      final name = e.category.trim().isEmpty ? uncategorized : e.category.trim();
      final acc = categories.putIfAbsent(name, () => _Acc(name: name));
      acc.value += e.amount;
      acc.count += 1;
    }

    return ExpensesReport(
      buckets: buckets,
      totals:
          series<Expense>(buckets, list, (e) => e.createdAt, (e) => e.amount),
      count: list.length,
      total: round3(total),
      byCategory: _ranked(categories, 'مصروف'),
    );
  }

  // -------------------------------------------------------------- inventory

  /// Snapshot of the current stock (not filtered by a period).
  static InventoryReport inventory(
    Iterable<Product> products,
    int lowStockThreshold, {
    String Function(String categoryId)? categoryName,
  }) {
    final list = products.where((p) => p.isActive).toList();

    var pieces = 0;
    var cost = 0.0;
    var selling = 0.0;
    var low = 0;
    var out = 0;
    final categories = <String, _Acc>{};
    for (final p in list) {
      pieces += p.quantity;
      cost += p.stockValue;
      selling += p.sellingPrice * p.quantity;
      switch (p.stockStatus(lowStockThreshold)) {
        case StockStatus.low:
          low++;
        case StockStatus.out:
          out++;
        case StockStatus.inStock:
          break;
      }
      if (p.quantity > 0) {
        final acc = categories.putIfAbsent(
            p.categoryId,
            () => _Acc(name: categoryName?.call(p.categoryId) ?? p.categoryId));
        acc.value += p.stockValue;
        acc.count += p.quantity;
      }
    }

    final attention = list
        .where((p) => p.stockStatus(lowStockThreshold) != StockStatus.inStock)
        .toList()
      ..sort((a, b) => a.quantity.compareTo(b.quantity));

    final byCategory = categories.values.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return InventoryReport(
      productsCount: list.length,
      pieces: pieces,
      costValue: round3(cost),
      sellingValue: round3(selling),
      lowCount: low,
      outCount: out,
      byCategory: [
        for (final a in byCategory)
          RankedItem(
              name: a.name, value: round3(a.value), note: '${a.count} قطعة'),
      ],
      attention: attention.take(10).toList(),
    );
  }

  // ------------------------------------------------------------------ debts

  /// [entries] are the parties with their current debt in [RankedItem.value];
  /// the ones owing nothing are dropped.
  static DebtsReport debts(Iterable<RankedItem> entries) {
    final items = entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return DebtsReport(
      items: items,
      total: round3(items.fold(0.0, (sum, e) => sum + e.value)),
    );
  }
}

/// Mutable accumulator used while grouping.
class _Acc {
  _Acc({this.id, required this.name});

  final String? id;
  final String name;
  double value = 0;
  int count = 0;
}
