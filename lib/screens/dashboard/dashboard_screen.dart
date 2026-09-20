import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/app_services.dart';
import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../models/activity_item.dart';
import '../../models/enums.dart';
import '../../repositories/dashboard_repository.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/product_card.dart';
import '../../widgets/sale_tile.dart';
import '../../widgets/section_header.dart';
import '../../widgets/statistic_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final AppServices _services;
  DashboardData? _data;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _services = AppScope.of(context);
    // Figures are live: reload when products, sales, payments or customers change.
    _services.products.addListener(_load);
    _services.sales.addListener(_load);
    _services.payments.addListener(_load);
    _services.customers.addListener(_load);
    _services.expenses.addListener(_load);
    _services.purchases.addListener(_load);
    _services.supplierPayments.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    _services.products.removeListener(_load);
    _services.sales.removeListener(_load);
    _services.payments.removeListener(_load);
    _services.customers.removeListener(_load);
    _services.expenses.removeListener(_load);
    _services.purchases.removeListener(_load);
    _services.supplierPayments.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await _services.dashboard.load();
      if (!mounted) return;
      setState(() {
        _data = data;
        _failed = false;
      });
    } catch (_) {
      if (!mounted) return;
      if (_data == null) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = _services.settings.current;
    final data = _data;

    final Widget body;
    if (data != null) {
      body = RefreshIndicator(
        onRefresh: _load,
        child: _DashboardContent(
          data: data,
          businessName: settings.businessName,
          businessSubtitle: settings.businessSubtitle,
          lowStockThreshold: settings.lowStockThreshold,
        ),
      );
    } else if (_failed) {
      body = EmptyState(
        icon: Icons.error_outline,
        title: 'تعذر تحميل البيانات',
        actionLabel: 'إعادة المحاولة',
        onAction: () {
          setState(() => _failed = false);
          _load();
        },
      );
    } else {
      body = const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(settings.businessName),
        actions: [
          IconButton(
            tooltip: 'الإعدادات',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
      ),
      body: body,
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.data,
    required this.businessName,
    required this.businessSubtitle,
    required this.lowStockThreshold,
  });

  final DashboardData data;
  final String businessName;
  final String businessSubtitle;
  final int lowStockThreshold;

  @override
  Widget build(BuildContext context) {
    final stats = <_Stat>[
      _Stat('مبيعات اليوم', CurrencyFormatter.format(data.todaySales),
          Icons.payments_outlined, AppColors.success),
      _Stat('عدد المبيعات', '${data.salesCount}', Icons.receipt_long_outlined,
          AppColors.info),
      _Stat('أرباح اليوم', CurrencyFormatter.format(data.todayProfit),
          Icons.trending_up_rounded, AppColors.lightGreen),
      _Stat('قيمة المخزون', CurrencyFormatter.format(data.inventoryValue),
          Icons.warehouse_outlined, AppColors.seed),
      _Stat('ديون الحرفاء', CurrencyFormatter.format(data.customerDebts),
          Icons.account_balance_wallet_outlined, AppColors.danger),
      _Stat('عدد المنتجات', '${data.productsCount}', Icons.chair_outlined,
          AppColors.warning),
    ];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        _WelcomeCard(title: businessName, subtitle: businessSubtitle),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 12.0;
            final width = (constraints.maxWidth - gap) / 2;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final s in stats)
                  SizedBox(
                    width: width,
                    child: StatisticCard(
                      label: s.label,
                      value: s.value,
                      icon: s.icon,
                      color: s.color,
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        const SectionHeader(title: 'الأقسام'),
        const SizedBox(height: 8),
        const _QuickAccess(),
        const SizedBox(height: 24),
        const SectionHeader(title: 'آخر المبيعات'),
        const SizedBox(height: 8),
        if (data.recentSales.isEmpty)
          const _InlineEmpty('لا توجد مبيعات حتى الآن')
        else
          for (final sale in data.recentSales) ...[
            SaleTile(
              sale: sale,
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.saleDetails,
                arguments: sale.id,
              ),
            ),
            const SizedBox(height: 8),
          ],
        const SizedBox(height: 16),
        const SectionHeader(title: 'المخزون المنخفض'),
        const SizedBox(height: 8),
        if (data.lowStock.isEmpty)
          const _InlineEmpty('لا توجد منتجات بكمية منخفضة')
        else
          for (final product in data.lowStock) ...[
            ProductCard(
              product: product,
              compact: true,
              lowStockThreshold: lowStockThreshold,
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.productDetails,
                arguments: product.id,
              ),
            ),
            const SizedBox(height: 8),
          ],
        const SizedBox(height: 16),
        const SectionHeader(title: 'آخر النشاطات'),
        const SizedBox(height: 8),
        if (data.recentActivity.isEmpty)
          const _InlineEmpty('لا توجد نشاطات حتى الآن')
        else
          Card(
            child: Column(
              children: [
                for (var i = 0; i < data.recentActivity.length; i++) ...[
                  if (i > 0) const Divider(indent: 16, endIndent: 16),
                  _ActivityTile(item: data.recentActivity[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _Stat {
  const _Stat(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [scheme.primary, scheme.primary.withValues(alpha: 0.78)],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مرحبًا بك في $title',
                  style: textTheme.titleLarge?.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onPrimary.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 16, color: scheme.onPrimary),
                    const SizedBox(width: 6),
                    Text(
                      DateFormatter.dayHeader(DateTime.now()),
                      style: textTheme.bodyMedium
                          ?.copyWith(color: scheme.onPrimary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.chair_alt_rounded,
              size: 56, color: scheme.onPrimary.withValues(alpha: 0.85)),
        ],
      ),
    );
  }
}

class _QuickAccess extends StatelessWidget {
  const _QuickAccess();

  static const List<(String, IconData, String)> _items = [
    ('المشتريات', Icons.shopping_bag_outlined, AppRoutes.purchases),
    ('الموردون', Icons.local_shipping_outlined, AppRoutes.suppliers),
    ('المصاريف', Icons.receipt_long_outlined, AppRoutes.expenses),
    ('التصنيفات', Icons.category_outlined, AppRoutes.categories),
    ('التقارير', Icons.bar_chart_rounded, AppRoutes.reports),
    ('النسخ الاحتياطي', Icons.cloud_upload_outlined, AppRoutes.backup),
    ('الإعدادات', Icons.settings_outlined, AppRoutes.settings),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final width = (constraints.maxWidth - gap * 2) / 3;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final (label, icon, route) in _items)
              SizedBox(
                width: width,
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.pushNamed(context, route),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 6),
                      child: Column(
                        children: [
                          Icon(icon, color: theme.colorScheme.primary),
                          const SizedBox(height: 8),
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.item});

  final ActivityItem item;

  static IconData _icon(ActivityType type) => switch (type) {
        ActivityType.productAdded => Icons.add_box_outlined,
        ActivityType.saleMade => Icons.point_of_sale_outlined,
        ActivityType.customerAdded => Icons.person_add_alt_outlined,
        ActivityType.paymentRecorded => Icons.payments_outlined,
        ActivityType.expenseAdded => Icons.receipt_long_outlined,
        ActivityType.purchaseMade => Icons.shopping_bag_outlined,
        ActivityType.backupCreated => Icons.cloud_done_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.primary,
        child: Icon(_icon(item.type), size: 20),
      ),
      title: Text(item.type.label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      subtitle: item.detail.isEmpty ? null : Text(item.detail),
      trailing: Text(
        DateFormatter.relative(item.createdAt),
        style: theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            message,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}
