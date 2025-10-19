import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/repositories/fake_order_repo.dart';
import 'data/repositories/order_repo.dart';
import 'features/diagnostics/presentation/diagnostics_page.dart';
import 'features/menu/presentation/menu_page.dart';
import 'features/ordering/controllers/order_controller.dart';
import 'features/ordering/presentation/bill_page.dart';
import 'features/tables/presentation/tables_page.dart';

final navigationIndexProvider = StateProvider<int>((ref) => 0);

class POSApp extends ConsumerWidget {
  const POSApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorSeed = Colors.deepOrange;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'POS Flutter PKA',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: colorSeed),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: colorSeed,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: const AppShell(),
    );
  }
}

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(navigationIndexProvider);
    final orderRepository = ref.watch(orderRepositoryProvider);
    String defaultOrderId = 'demo-order';
    if (orderRepository is FakeOrderRepository) {
      defaultOrderId = orderRepository.defaultOrderId;
    }
    final defaultOrderArgs = OrderControllerArgs(orderId: defaultOrderId);

    final pages = <Widget>[
      const TablesPage(),
      MenuPage(orderArgs: defaultOrderArgs),
      BillPage(args: defaultOrderArgs),
      const DiagnosticsPage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) {
          ref.read(navigationIndexProvider.notifier).state = value;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.table_bar_outlined),
            selectedIcon: Icon(Icons.table_bar),
            label: 'Tables',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: 'Menu',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Bill',
          ),
          NavigationDestination(
            icon: Icon(Icons.monitor_heart_outlined),
            selectedIcon: Icon(Icons.monitor_heart),
            label: 'Diagnostics',
          ),
        ],
      ),
    );
  }
}
