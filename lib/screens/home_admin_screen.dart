import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/auth_service.dart';
import '../services/order_service.dart';
import '../utils/json_utils.dart';
import 'admin_users_screen.dart';
import 'categories_screen.dart';
import 'items_screen.dart';
import 'login_screen.dart';
import 'receipts_screen.dart';
import 'areas_screen.dart';
import 'tables_screen.dart';

/// Home screen for the admin role with access to reports and management modules.
class HomeAdminScreen extends StatefulWidget {
  const HomeAdminScreen({super.key});

  @override
  State<HomeAdminScreen> createState() => _HomeAdminScreenState();
}

class _HomeAdminScreenState extends State<HomeAdminScreen> {
  final _orderService = OrderService.instance;
  late Future<List<Map<String, dynamic>>> _receiptsFuture;

  @override
  void initState() {
    super.initState();
    _receiptsFuture = _loadReceipts();
  }

  Future<List<Map<String, dynamic>>> _loadReceipts() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final formatter = DateFormat('yyyy-MM-dd');
    return _orderService.fetchReceipts(
      from: formatter.format(start),
      to: formatter.format(now),
    );
  }

  void _logout() async {
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng điều khiển Admin'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _receiptsFuture = _loadReceipts();
          });
          await _receiptsFuture;
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _AdminActionCard(
                    title: 'Danh mục',
                    icon: Icons.category_outlined,
                    color: colorScheme.primary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CategoriesScreen(),
                      ),
                    ),
                  ),
                  _AdminActionCard(
                    title: 'Món ăn',
                    icon: Icons.restaurant_menu,
                    color: colorScheme.secondary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ItemsScreen(),
                      ),
                    ),
                  ),
                  _AdminActionCard(
                    title: 'Khu bàn',
                    icon: Icons.layers_outlined,
                    color: colorScheme.tertiary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AreasScreen(),
                      ),
                    ),
                  ),
                  _AdminActionCard(
                    title: 'Bàn ăn',
                    icon: Icons.table_bar,
                    color: colorScheme.secondaryContainer,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TablesScreen(),
                      ),
                    ),
                  ),
                  _AdminActionCard(
                    title: 'Nhân viên',
                    icon: Icons.group_outlined,
                    color: colorScheme.primary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminUsersScreen(),
                      ),
                    ),
                  ),
                  _AdminActionCard(
                    title: 'Hóa đơn',
                    icon: Icons.receipt_long,
                    color: colorScheme.tertiary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ReceiptsScreen(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Doanh thu gần đây',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _receiptsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _ErrorState(
                      message: snapshot.error.toString(),
                      onRetry: () {
                        setState(() {
                          _receiptsFuture = _loadReceipts();
                        });
                      },
                    );
                  }
                  final receipts = snapshot.data ?? [];
                  final totalRevenue = receipts.fold<double>(
                    0,
                    (sum, item) =>
                        sum +
                        (parseDouble(item['total']) ??
                            parseDouble(item['grand_total']) ??
                            0),
                  );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tổng doanh thu: '
                        '${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(totalRevenue)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      ...receipts.take(5).map(
                        (receipt) => ListTile(
                          leading: const Icon(Icons.receipt_outlined),
                          title: Text(receipt['receipt_no'] != null
                              ? 'Hoá đơn ${receipt['receipt_no']}'
                              : 'Hoá đơn #${parseInt(receipt['id']) ?? receipt['id']}'),
                          subtitle: Text([
                            if ((receipt['area_code'] ?? receipt['area']) != null)
                              'Khu ${receipt['area_code'] ?? receipt['area']}',
                            if ((receipt['table_code'] ?? receipt['table']) != null)
                              'Bàn ${receipt['table_code'] ?? receipt['table']}',
                            'Tổng: ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(parseDouble(receipt['total']) ?? 0)}',
                          ].join(' • ')),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminActionCard extends StatelessWidget {
  const _AdminActionCard({
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
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        width: 180,
        height: 140,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        const SizedBox(height: 8),
        FilledButton.tonal(onPressed: onRetry, child: const Text('Thử lại')),
      ],
    );
  }
}
