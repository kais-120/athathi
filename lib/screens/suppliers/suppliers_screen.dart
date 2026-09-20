import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../app/routes.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/party_tile.dart';
import '../../widgets/search_field.dart';

/// Suppliers list: search, "we owe" filter, debt summary, add.
class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  late final AppServices _services;
  String _query = '';
  bool _onlyDebts = false;

  @override
  void initState() {
    super.initState();
    _services = AppScope.of(context);
  }

  void _add() => Navigator.pushNamed(context, AppRoutes.supplierForm);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الموردون')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add_business_outlined),
        label: const Text('إضافة مورد'),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          _services.suppliers,
          _services.purchases,
          _services.supplierPayments,
        ]),
        builder: (context, _) {
          final repo = _services.suppliers;
          if (repo.count == 0) {
            return EmptyState(
              icon: Icons.local_shipping_outlined,
              title: 'لا يوجد موردون مسجلون',
              message: 'أضف مورديك لتتبع مشترياتك وما عليك لهم',
              actionLabel: 'إضافة مورد',
              onAction: _add,
            );
          }

          var suppliers = repo.search(_query);
          final debts = {for (final s in suppliers) s.id: repo.debtOf(s.id)};
          if (_onlyDebts) {
            suppliers = suppliers.where((s) => debts[s.id]! > 0).toList()
              ..sort((a, b) => debts[b.id]!.compareTo(debts[a.id]!));
          }

          final theme = Theme.of(context);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(
                          child: _Cell('عدد الموردين', '${repo.count}', theme),
                        ),
                        Expanded(
                          child: _Cell('نحن مدينون لهم',
                              '${repo.debtorsCount}', theme),
                        ),
                        Expanded(
                          child: _Cell('إجمالي الديون',
                              CurrencyFormatter.format(repo.totalDebts), theme),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SearchField(
                  hintText: 'ابحث عن مورد...',
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: ChoiceChip(
                        label: const Text('الكل'),
                        selected: !_onlyDebts,
                        onSelected: (_) => setState(() => _onlyDebts = false),
                      ),
                    ),
                    ChoiceChip(
                      label: const Text('لهم مستحقات'),
                      selected: _onlyDebts,
                      onSelected: (_) => setState(() => _onlyDebts = true),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: suppliers.isEmpty
                    ? EmptyState(
                        icon: _onlyDebts
                            ? Icons.verified_outlined
                            : Icons.search_off_rounded,
                        title: _onlyDebts && _query.isEmpty
                            ? 'لا توجد مستحقات للموردين'
                            : 'لا توجد نتائج مطابقة',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                        itemCount: suppliers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final s = suppliers[i];
                          return PartyTile(
                            name: s.name,
                            phone: s.phone,
                            debt: debts[s.id] ?? 0,
                            debtPrefix: 'له',
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.supplierDetails,
                              arguments: s.id,
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

class _Cell extends StatelessWidget {
  const _Cell(this.label, this.value, this.theme);

  final String label;
  final String value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) => Column(
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
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ),
        ],
      );
}
