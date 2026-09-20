import 'package:flutter/material.dart';

import '../accounts/accounts_screen.dart';
import '../customers/customers_screen.dart';
import '../products/products_screen.dart';
import '../sales/sales_screen.dart';
import 'dashboard_screen.dart';

/// Main navigation: bottom NavigationBar with the 5 primary sections.
/// Tabs keep their state thanks to the IndexedStack.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const List<Widget> _tabs = [
    DashboardScreen(),
    ProductsScreen(),
    SalesScreen(),
    CustomersScreen(),
    AccountsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.chair_outlined),
            selectedIcon: Icon(Icons.chair),
            label: 'المنتجات',
          ),
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale),
            label: 'المبيعات',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'الحرفاء',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'الحسابات',
          ),
        ],
      ),
    );
  }
}
