import 'package:flutter/material.dart' show DateTimeRange;

import '../models/account_transaction.dart';
import '../utils/period.dart';
import 'customer_repository.dart';
import 'expense_repository.dart';
import 'payment_repository.dart';
import 'purchase_repository.dart';
import 'sale_repository.dart';
import 'settings_repository.dart';
import 'supplier_payment_repository.dart';
import 'supplier_repository.dart';

/// Income / outflow totals of a period.
class AccountSummary {
  const AccountSummary({required this.income, required this.outflow});

  final double income;
  final double outflow;
  double get net => income - outflow;
}

/// الحسابات: the money ledger, computed from the other repositories.
///
/// * Income  = amounts paid at sale time + payments received from customers.
/// * Outflow = amounts paid on purchases + payments to suppliers + expenses.
/// * Cash drawer = opening balance + income − outflow.
///
/// Widgets should listen to all the source repositories to refresh.
class AccountsRepository {
  AccountsRepository({
    required this.sales,
    required this.payments,
    required this.customers,
    required this.purchases,
    required this.supplierPayments,
    required this.suppliers,
    required this.expenses,
    required this.settings,
  });

  final SaleRepository sales;
  final PaymentRepository payments;
  final CustomerRepository customers;
  final PurchaseRepository purchases;
  final SupplierPaymentRepository supplierPayments;
  final SupplierRepository suppliers;
  final ExpenseRepository expenses;
  final SettingsRepository settings;

  /// Ledger lines of [range] (all time when null), newest first.
  List<AccountTransaction> transactions({DateTimeRange? range}) {
    final list = <AccountTransaction>[];

    for (final sale in sales.all) {
      if (sale.paid > 0 && Period.contains(range, sale.createdAt)) {
        list.add(AccountTransaction(
          id: 'sale_${sale.id}',
          kind: TransactionKind.saleIncome,
          title: 'بيع #${sale.number}',
          subtitle: '${sale.displayCustomer} • ${sale.method.label}',
          amount: sale.paid,
          date: sale.createdAt,
          refId: sale.id,
        ));
      }
    }

    for (final payment in payments.all) {
      if (Period.contains(range, payment.createdAt)) {
        final name = customers.byId(payment.customerId)?.name ?? 'حريف محذوف';
        list.add(AccountTransaction(
          id: 'cpay_${payment.id}',
          kind: TransactionKind.customerPayment,
          title: 'دفعة من $name',
          subtitle: payment.method.label,
          amount: payment.amount,
          date: payment.createdAt,
          refId: payment.customerId,
        ));
      }
    }

    for (final purchase in purchases.all) {
      if (purchase.paid > 0 && Period.contains(range, purchase.createdAt)) {
        list.add(AccountTransaction(
          id: 'purchase_${purchase.id}',
          kind: TransactionKind.purchase,
          title: 'شراء من ${purchase.displaySupplier}',
          subtitle: '${purchase.pieces} قطعة',
          amount: purchase.paid,
          date: purchase.createdAt,
          refId: purchase.id,
        ));
      }
    }

    for (final payment in supplierPayments.all) {
      if (Period.contains(range, payment.createdAt)) {
        final name = suppliers.byId(payment.supplierId)?.name ?? 'مورد محذوف';
        list.add(AccountTransaction(
          id: 'spay_${payment.id}',
          kind: TransactionKind.supplierPayment,
          title: 'دفعة للمورد $name',
          subtitle: payment.note,
          amount: payment.amount,
          date: payment.createdAt,
          refId: payment.supplierId,
        ));
      }
    }

    for (final expense in expenses.all) {
      if (Period.contains(range, expense.createdAt)) {
        list.add(AccountTransaction(
          id: 'expense_${expense.id}',
          kind: TransactionKind.expense,
          title: expense.title,
          subtitle: expense.category,
          amount: expense.amount,
          date: expense.createdAt,
          refId: expense.id,
        ));
      }
    }

    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  AccountSummary summary(List<AccountTransaction> transactions) {
    var income = 0.0;
    var outflow = 0.0;
    for (final t in transactions) {
      if (t.isIncome) {
        income += t.amount;
      } else {
        outflow += t.amount;
      }
    }
    return AccountSummary(income: income, outflow: outflow);
  }

  /// Money currently in the cash drawer (all time).
  double get cashBalance {
    var balance = settings.current.openingBalance;
    for (final t in transactions()) {
      if (t.isIncome) {
        balance += t.amount;
      } else {
        balance -= t.amount;
      }
    }
    return balance;
  }
}
