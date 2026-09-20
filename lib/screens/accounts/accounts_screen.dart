import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/account_transaction.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/measure_formatter.dart';
import '../../utils/period.dart';
import '../../utils/validators.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_header.dart';
import '../../widgets/statistic_card.dart';
import '../../widgets/transaction_tile.dart';

enum _Direction { all, income, outflow }

/// الحسابات: cash balance, debts, and the ledger of every money movement.
class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  late final AppServices _services;
  Period _period = Period.month;
  _Direction _direction = _Direction.all;

  @override
  void initState() {
    super.initState();
    _services = AppScope.of(context);
  }

  Future<void> _editOpeningBalance() async {
    final value = await showDialog<double>(
      context: context,
      builder: (_) => _OpeningBalanceDialog(
        current: _services.settings.current.openingBalance,
      ),
    );
    if (value == null) return;
    await _services.settings.setOpeningBalance(value);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('تم تحديث الرصيد الافتتاحي')));
  }

  void _open(AccountTransaction t) {
    switch (t.kind) {
      case TransactionKind.saleIncome:
        Navigator.pushNamed(context, AppRoutes.saleDetails, arguments: t.refId);
      case TransactionKind.customerPayment:
        if (_services.customers.byId(t.refId) != null) {
          Navigator.pushNamed(context, AppRoutes.customerDetails,
              arguments: t.refId);
        }
      case TransactionKind.purchase:
        Navigator.pushNamed(context, AppRoutes.purchaseDetails,
            arguments: t.refId);
      case TransactionKind.supplierPayment:
        if (_services.suppliers.byId(t.refId) != null) {
          Navigator.pushNamed(context, AppRoutes.supplierDetails,
              arguments: t.refId);
        }
      case TransactionKind.expense:
        Navigator.pushNamed(context, AppRoutes.expenseForm, arguments: t.refId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الحسابات')),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          _services.sales,
          _services.payments,
          _services.customers,
          _services.purchases,
          _services.supplierPayments,
          _services.suppliers,
          _services.expenses,
          _services.settings,
        ]),
        builder: (context, _) => _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final accounts = _services.accounts;
    final settings = _services.settings.current;

    final inPeriod = accounts.transactions(range: _period.range());
    final summary = accounts.summary(inPeriod);
    final transactions = inPeriod.where((t) {
      switch (_direction) {
        case _Direction.all:
          return true;
        case _Direction.income:
          return t.isIncome;
        case _Direction.outflow:
          return !t.isIncome;
      }
    }).toList();

    final balance = accounts.cashBalance;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- cash drawer
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withValues(alpha: 0.78),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_balance_wallet_outlined,
                              color: theme.colorScheme.onPrimary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'رصيد الصندوق (نقدًا)',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onPrimary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          CurrencyFormatter.format(balance),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'الرصيد الافتتاحي: ${CurrencyFormatter.format(settings.openingBalance)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onPrimary
                                      .withValues(alpha: 0.9),
                                  height: 1.6),
                            ),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                                foregroundColor: theme.colorScheme.onPrimary),
                            onPressed: _editOpeningBalance,
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('تعديل الافتتاحي'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ---- debts
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: StatisticCard(
                        label: 'لنا عند الحرفاء',
                        value: CurrencyFormatter.format(
                            _services.customers.totalDebts),
                        icon: Icons.call_received_rounded,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatisticCard(
                        label: 'علينا للموردين',
                        value: CurrencyFormatter.format(
                            _services.suppliers.totalDebts),
                        icon: Icons.call_made_rounded,
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ---- shortcuts
                _Shortcuts(),
                const SizedBox(height: 24),

                // ---- period summary
                const SectionHeader(title: 'الحركة المالية'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final p in Period.values)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 8),
                          child: ChoiceChip(
                            label: Text(p.label),
                            selected: _period == p,
                            onSelected: (_) => setState(() => _period = p),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        _SummaryCell('المقبوضات',
                            CurrencyFormatter.format(summary.income),
                            AppColors.success),
                        _SummaryCell('المدفوعات',
                            CurrencyFormatter.format(summary.outflow),
                            AppColors.danger),
                        _SummaryCell(
                            'الصافي',
                            CurrencyFormatter.format(summary.net),
                            summary.net >= 0
                                ? AppColors.success
                                : AppColors.danger),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final entry in const {
                        _Direction.all: 'الكل',
                        _Direction.income: 'مقبوضات',
                        _Direction.outflow: 'مدفوعات',
                      }.entries)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(end: 8),
                          child: ChoiceChip(
                            label: Text(entry.value),
                            selected: _direction == entry.key,
                            onSelected: (_) =>
                                setState(() => _direction = entry.key),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
        if (transactions.isEmpty)
          const SliverToBoxAdapter(
            child: SizedBox(
              height: 240,
              child: EmptyState(
                icon: Icons.swap_vert_rounded,
                title: 'لا توجد حركات مالية في هذه الفترة',
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            sliver: SliverList.separated(
              itemCount: transactions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) => TransactionTile(
                transaction: transactions[i],
                onTap: () => _open(transactions[i]),
              ),
            ),
          ),
      ],
    );
  }
}

class _Shortcuts extends StatelessWidget {
  static const List<(String, IconData, String)> _items = [
    ('المشتريات', Icons.shopping_bag_outlined, AppRoutes.purchases),
    ('الموردون', Icons.local_shipping_outlined, AppRoutes.suppliers),
    ('المصاريف', Icons.receipt_long_outlined, AppRoutes.expenses),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        for (var i = 0; i < _items.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.pushNamed(context, _items[i].$3),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    children: [
                      Icon(_items[i].$2, color: theme.colorScheme.primary),
                      const SizedBox(height: 8),
                      Text(_items[i].$1,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(value,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700, color: color)),
          ),
        ],
      ),
    );
  }
}

class _OpeningBalanceDialog extends StatefulWidget {
  const _OpeningBalanceDialog({required this.current});

  final double current;

  @override
  State<_OpeningBalanceDialog> createState() => _OpeningBalanceDialogState();
}

class _OpeningBalanceDialogState extends State<_OpeningBalanceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller = TextEditingController(
      text: widget.current == 0 ? '' : MeasureFormatter.number(widget.current));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final value = Validators.parseNumber(_controller.text) ?? 0;
    Navigator.pop(context, (value * 1000).round() / 1000);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('الرصيد الافتتاحي'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'المبلغ النقدي الموجود في الصندوق عند بدء استعمال التطبيق.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              validator: Validators.optionalNumber,
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'المبلغ',
                suffixText: 'د.ت',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
          onPressed: _submit,
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}
