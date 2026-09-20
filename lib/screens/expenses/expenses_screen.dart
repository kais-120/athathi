import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/expense.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';
import '../../utils/period.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';

/// Expenses list with a period filter and the total of the period.
class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  late final AppServices _services;
  Period _period = Period.month;

  @override
  void initState() {
    super.initState();
    _services = AppScope.of(context);
  }

  void _add() => Navigator.pushNamed(context, AppRoutes.expenseForm);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('المصاريف')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('إضافة مصروف'),
      ),
      body: ListenableBuilder(
        listenable: _services.expenses,
        builder: (context, _) {
          final all = _services.expenses.all;
          if (all.isEmpty) {
            return EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'لا توجد مصاريف مسجلة',
              message: 'سجّل مصاريف المحل (نقل، كراء، إصلاح...) لمعرفة أرباحك الحقيقية',
              actionLabel: 'إضافة مصروف',
              onAction: _add,
            );
          }

          final range = _period.range();
          final expenses =
              all.where((e) => Period.contains(range, e.createdAt)).toList();
          final total = expenses.fold(0.0, (sum, Expense e) => sum + e.amount);

          return Column(
            children: [
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('إجمالي المصاريف',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant)),
                              const SizedBox(height: 2),
                              Text(
                                CurrencyFormatter.format(total),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.danger,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text('${expenses.length} مصروف',
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: expenses.isEmpty
                    ? const EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'لا توجد مصاريف في هذه الفترة',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                        itemCount: expenses.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final e = expenses[i];
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.expenseForm,
                                arguments: e.id,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AppColors.danger
                                          .withValues(alpha: 0.12),
                                      foregroundColor: AppColors.danger,
                                      child: const Icon(
                                          Icons.receipt_long_outlined),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(e.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.titleSmall
                                                  ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700)),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              if (e.category.isNotEmpty) ...[
                                                StatusBadge(
                                                  label: e.category,
                                                  color: AppColors.info,
                                                ),
                                                const SizedBox(width: 8),
                                              ],
                                              Text(
                                                DateFormatter.date(e.createdAt),
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                        color: theme.colorScheme
                                                            .onSurfaceVariant),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      CurrencyFormatter.format(e.amount),
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.danger),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
