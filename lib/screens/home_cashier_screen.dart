import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'kitchen_queue_screen.dart';
import 'login_screen.dart';
import 'order_list_screen.dart';
import 'receipts_screen.dart';
import 'table_select_screen.dart';

/// Landing screen for cashier role showing quick actions for ordering flow.
class HomeCashierScreen extends StatelessWidget {
  const HomeCashierScreen({super.key});

  void _logout(BuildContext context) async {
    await AuthService.instance.logout();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thu ngân - POS gọi món'),
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width > 800 ? 3 : 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _CashierActionCard(
              title: 'Chọn bàn & Order',
              icon: Icons.table_bar,
              color: colorScheme.primary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TableSelectScreen(),
                ),
              ),
            ),
            _CashierActionCard(
              title: 'Danh sách order',
              icon: Icons.receipt_long_outlined,
              color: colorScheme.primary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OrderListScreen(),
                ),
              ),
            ),
            _CashierActionCard(
              title: 'Hàng đợi bếp',
              icon: Icons.kitchen_outlined,
              color: colorScheme.primary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const KitchenQueueScreen(),
                ),
              ),
            ),
            _CashierActionCard(
              title: 'Hóa đơn gần đây',
              icon: Icons.receipt_long,
              color: colorScheme.primary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ReceiptsScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CashierActionCard extends StatelessWidget {
  const _CashierActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
