import 'package:athathi/models/enums.dart';
import 'package:athathi/models/expense.dart';
import 'package:athathi/models/product.dart';
import 'package:athathi/models/purchase.dart';
import 'package:athathi/models/report_data.dart';
import 'package:athathi/models/sale.dart';
import 'package:athathi/models/sale_item.dart';
import 'package:athathi/utils/report_calculator.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_test/flutter_test.dart';

// September 2026
final _month =
    DateTimeRange(start: DateTime(2026, 9, 1), end: DateTime(2026, 10, 1));

Sale _sale(
  int number,
  DateTime at, {
  required List<SaleItem> items,
  double? paid,
  PaymentMethod method = PaymentMethod.cash,
}) {
  final total = items.fold(0.0, (sum, i) => sum + i.lineTotal);
  return Sale(
    id: 's$number',
    number: number,
    items: items,
    total: total,
    paid: paid ?? total,
    method: method,
    createdAt: at,
  );
}

SaleItem _item(String id, double price, double cost, int qty) => SaleItem(
      productId: id,
      productName: 'منتج $id',
      unitPrice: price,
      unitCost: cost,
      quantity: qty,
    );

void main() {
  group('buckets', () {
    test('one day = 8 blocks of 3 hours', () {
      final b = ReportCalculator.buckets(DateTimeRange(
          start: DateTime(2026, 9, 19), end: DateTime(2026, 9, 20)));
      expect(b.length, 8);
      expect(b.first.label, '00:00');
      expect(b[3].start, DateTime(2026, 9, 19, 9));
      expect(b.last.end, DateTime(2026, 9, 20));
    });

    test('a week = 7 days with dd/MM labels', () {
      final b = ReportCalculator.buckets(DateTimeRange(
          start: DateTime(2026, 9, 14), end: DateTime(2026, 9, 21)));
      expect(b.length, 7);
      expect(b.first.label, '14/09');
      expect(b.last.label, '20/09');
    });

    test('a month = one bucket per day with dd labels', () {
      final b = ReportCalculator.buckets(_month);
      expect(b.length, 30);
      expect(b.first.label, '01');
      expect(b.last.label, '30');
    });

    test('a long custom range is grouped by month', () {
      final b = ReportCalculator.buckets(DateTimeRange(
          start: DateTime(2026, 7, 15), end: DateTime(2026, 10, 2)));
      expect(b.length, 4);
      expect(b.first.label, '07/26');
      expect(b.first.fullLabel, 'جويلية 2026');
      expect(b.last.fullLabel, 'أكتوبر 2026');
    });
  });

  group('sales report', () {
    final sales = [
      _sale(1, DateTime(2026, 9, 2, 10),
          items: [_item('a', 100, 60, 2)]), // total 200, profit 80
      _sale(2, DateTime(2026, 9, 2, 16),
          items: [_item('a', 90, 60, 1), _item('b', 50, 30, 2)],
          paid: 100,
          method: PaymentMethod.credit), // total 190, profit 30 + 40
      _sale(3, DateTime(2026, 9, 20, 9),
          items: [_item('b', 55, 30, 1)]),
      _sale(4, DateTime(2026, 8, 31, 23, 59), items: [_item('a', 100, 60, 1)]),
      _sale(5, DateTime(2026, 10, 1), items: [_item('a', 100, 60, 1)]),
    ];

    test('only the period is counted (end is exclusive)', () {
      final r = ReportCalculator.sales(sales, _month);
      expect(r.count, 3);
      expect(r.total, 445);
      expect(r.pieces, 6);
      expect(r.collected, 355);
      expect(r.remaining, 90);
      expect(r.average, closeTo(148.333, 0.001));
    });

    test('chart series match the total and land in the right day', () {
      final r = ReportCalculator.sales(sales, _month);
      expect(r.totals.length, r.buckets.length);
      expect(r.totals.fold(0.0, (a, b) => a + b), 445);
      expect(r.totals[1], 390); // 2 September
      expect(r.totals[19], 55); // 20 September
    });

    test('payment methods and top products', () {
      final r = ReportCalculator.sales(sales, _month);
      expect(r.byMethod.keys.toSet(),
          {PaymentMethod.cash, PaymentMethod.credit});
      expect(r.byMethod[PaymentMethod.cash]!.count, 2);
      expect(r.byMethod[PaymentMethod.cash]!.total, 255);
      expect(r.byMethod[PaymentMethod.credit]!.total, 190);

      expect(r.topProducts.first.id, 'a');
      expect(r.topProducts.first.value, 290); // 200 + 90
      expect(r.topProducts.first.note, '3 قطعة');
      expect(r.topProducts[1].value, 155); // 100 + 55
    });

    test('empty period', () {
      final r = ReportCalculator.sales(
          sales,
          DateTimeRange(
              start: DateTime(2025, 1, 1), end: DateTime(2025, 2, 1)));
      expect(r.isEmpty, isTrue);
      expect(r.average, 0);
    });
  });

  group('profit report', () {
    final sales = [
      _sale(1, DateTime(2026, 9, 2, 10), items: [_item('a', 100, 60, 2)]),
      _sale(2, DateTime(2026, 9, 3, 10),
          items: [_item('b', 50, 30, 2)], paid: 0, method: PaymentMethod.credit),
      _sale(3, DateTime(2026, 9, 4, 10), items: [_item('c', 40, 0, 1)]),
    ];
    final expenses = [
      Expense(
          id: 'e1',
          title: 'نقل',
          amount: 30,
          createdAt: DateTime(2026, 9, 3)),
      Expense(
          id: 'e2',
          title: 'كراء',
          amount: 500,
          createdAt: DateTime(2026, 8, 3)), // other month
    ];

    test('gross = Σ (price − cost) × qty, net = gross − expenses', () {
      final r = ReportCalculator.profit(sales, expenses, _month);
      expect(r.revenue, 340);
      expect(r.gross, 160); // 80 + 40 + 40
      expect(r.costOfGoods, 180);
      expect(r.expenses, 30);
      expect(r.net, 130);
      expect(r.margin, closeTo(47.06, 0.01));
    });

    test('unpaid sales still count (accrual)', () {
      final r = ReportCalculator.profit(sales, expenses, _month);
      expect(r.grossSeries[2], 40); // 3 September, sold on credit
    });

    test('lines without cost are flagged', () {
      final r = ReportCalculator.profit(sales, expenses, _month);
      expect(r.itemsWithoutCost, 1);
    });

    test('net can be negative', () {
      final r = ReportCalculator.profit([], expenses, _month);
      expect(r.isEmpty, isFalse);
      expect(r.net, -30);
    });
  });

  group('purchases and expenses', () {
    test('purchases totals, paid and remaining', () {
      final purchases = [
        Purchase(
          id: 'p1',
          supplierId: 's1',
          supplierName: 'علي',
          items: const [PurchaseItem(name: 'خزانة', quantity: 2, unitCost: 100)],
          total: 200,
          paid: 150,
          createdAt: DateTime(2026, 9, 5),
        ),
        Purchase(
          id: 'p2',
          supplierId: 's1',
          supplierName: 'علي',
          items: const [PurchaseItem(name: 'كرسي', quantity: 4, unitCost: 25)],
          total: 100,
          paid: 100,
          createdAt: DateTime(2026, 9, 6),
        ),
        Purchase(
          id: 'p3',
          items: const [PurchaseItem(name: 'طاولة', quantity: 1, unitCost: 80)],
          total: 80,
          paid: 80,
          createdAt: DateTime(2026, 9, 7),
        ),
      ];
      final r = ReportCalculator.purchases(purchases, _month);
      expect(r.count, 3);
      expect(r.total, 380);
      expect(r.paid, 330);
      expect(r.remaining, 50);
      expect(r.pieces, 7);
      expect(r.topSuppliers.first.name, 'علي');
      expect(r.topSuppliers.first.value, 300);
      expect(r.topSuppliers.first.note, '2 عملية');
      expect(r.topSuppliers[1].id, isNull);
    });

    test('expenses grouped by category, empty category is named', () {
      final expenses = [
        Expense(
            id: '1',
            title: 'بنزين',
            category: 'نقل',
            amount: 20,
            createdAt: DateTime(2026, 9, 2)),
        Expense(
            id: '2',
            title: 'شاحنة',
            category: 'نقل',
            amount: 60,
            createdAt: DateTime(2026, 9, 9)),
        Expense(
            id: '3',
            title: 'متفرقات',
            amount: 10,
            createdAt: DateTime(2026, 9, 9)),
      ];
      final r = ReportCalculator.expenses(expenses, _month);
      expect(r.total, 90);
      expect(r.count, 3);
      expect(r.average, 30);
      expect(r.byCategory.first.name, 'نقل');
      expect(r.byCategory.first.value, 80);
      expect(r.byCategory.last.name, ReportCalculator.uncategorized);
      expect(r.totals.fold(0.0, (a, b) => a + b), 90);
    });
  });

  group('inventory report', () {
    Product p(String id, String categoryId, int qty,
            {double cost = 0, double price = 0, bool active = true}) =>
        Product(
          id: id,
          name: 'منتج $id',
          categoryId: categoryId,
          condition: ProductCondition.good,
          purchasePrice: cost,
          sellingPrice: price,
          quantity: qty,
          isActive: active,
        );

    const names = {'chairs': 'الكراسي', 'tables': 'الطاولات', 'desks': 'المكاتب'};

    test('values, stock status counts and categories', () {
      final r = ReportCalculator.inventory([
        p('1', 'chairs', 10, cost: 20, price: 35),
        p('2', 'chairs', 2, cost: 30, price: 50),
        p('3', 'tables', 0, cost: 100, price: 150),
        p('4', 'tables', 5, cost: 100, price: 160),
        p('5', 'desks', 4, cost: 10, price: 10, active: false),
      ], 3, categoryName: (id) => names[id] ?? id);

      expect(r.productsCount, 4); // inactive ignored
      expect(r.pieces, 17);
      expect(r.costValue, 760); // 200 + 60 + 0 + 500
      expect(r.sellingValue, 1250); // 350 + 100 + 0 + 800
      expect(r.expectedProfit, 490);
      expect(r.lowCount, 1);
      expect(r.outCount, 1);

      expect(r.byCategory.first.name, 'الطاولات');
      expect(r.byCategory.first.value, 500);
      expect(r.byCategory.first.note, '5 قطعة');
      expect(r.byCategory.length, 2); // out-of-stock product adds no category

      expect([for (final x in r.attention) x.id], ['3', '2']);
    });

    test('empty stock', () {
      expect(ReportCalculator.inventory([], 3).isEmpty, isTrue);
    });
  });

  group('debts report', () {
    test('drops settled parties and sorts by amount', () {
      final r = ReportCalculator.debts(const [
        RankedItem(id: 'a', name: 'أحمد', value: 50),
        RankedItem(id: 'b', name: 'سالم', value: 0),
        RankedItem(id: 'c', name: 'منى', value: 120.5),
      ]);
      expect(r.count, 2);
      expect(r.items.first.name, 'منى');
      expect(r.total, 170.5);
    });

    test('nobody owes anything', () {
      expect(ReportCalculator.debts(const []).isEmpty, isTrue);
    });
  });
}
