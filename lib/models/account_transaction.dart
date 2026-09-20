/// Kinds of money movements shown in الحسابات.
enum TransactionKind {
  saleIncome('مبيعات'),
  customerPayment('دفعة حريف'),
  purchase('مشتريات'),
  supplierPayment('دفعة لمورد'),
  expense('مصروف');

  const TransactionKind(this.label);
  final String label;
}

/// One line of the account ledger. Derived from sales, payments, purchases
/// and expenses (never stored), so it always matches the real records.
class AccountTransaction {
  const AccountTransaction({
    required this.id,
    required this.kind,
    required this.title,
    this.subtitle = '',
    required this.amount,
    required this.date,
    required this.refId,
  });

  final String id;
  final TransactionKind kind;
  final String title;
  final String subtitle;

  /// Always positive; the direction comes from [isIncome].
  final double amount;
  final DateTime date;

  /// Id of the sale / customer / purchase / supplier / expense behind it.
  final String refId;

  bool get isIncome =>
      kind == TransactionKind.saleIncome ||
      kind == TransactionKind.customerPayment;
}
