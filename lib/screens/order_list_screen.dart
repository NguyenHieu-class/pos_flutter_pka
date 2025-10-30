import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/order.dart';
import '../services/api_service.dart';
import '../services/order_service.dart';
import 'order_detail_screen.dart';

/// Display list of orders for cashier to review and open quickly.
class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  final _orderService = OrderService.instance;
  late Future<List<Order>> _ordersFuture;
  String _selectedStatus = 'open';

  static const _statusOptions = [
    ('open', 'Đang mở'),
    ('closed', 'Đã đóng'),
    ('cancelled', 'Đã huỷ'),
    ('all', 'Tất cả'),
  ];

  @override
  void initState() {
    super.initState();
    _ordersFuture = _loadOrders();
  }

  Future<List<Order>> _loadOrders() {
    final status = _selectedStatus == 'all' ? null : _selectedStatus;
    return _orderService.fetchOrders(status: status);
  }

  Future<void> _refresh() async {
    setState(() {
      _ordersFuture = _loadOrders();
    });
    await _ordersFuture;
  }

  void _openOrder(Order order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(
          orderId: order.id,
          tableName: order.tableName ?? order.tableCode ?? '---',
        ),
      ),
    );
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'open':
        return 'Đang mở';
      case 'closed':
        return 'Đã đóng';
      case 'cancelled':
        return 'Đã huỷ';
      default:
        return status ?? '---';
    }
  }

  Color _statusColor(String? status, ThemeData theme) {
    switch (status) {
      case 'open':
        return theme.colorScheme.primary;
      case 'closed':
        return theme.colorScheme.secondary;
      case 'cancelled':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách order'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                const Text('Trạng thái:'),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _selectedStatus,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedStatus = value;
                      _ordersFuture = _loadOrders();
                    });
                  },
                  items: _statusOptions
                      .map(
                        (option) => DropdownMenuItem<String>(
                          value: option.$1,
                          child: Text(option.$2),
                        ),
                      )
                      .toList(),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _ordersFuture = _loadOrders();
                    });
                  },
                  tooltip: 'Làm mới',
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<Order>>(
                future: _ordersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    final error = snapshot.error;
                    final message = error is ApiException
                        ? error.message
                        : 'Đã xảy ra lỗi không xác định';
                    return ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Không thể tải danh sách order',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(message),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _ordersFuture = _loadOrders();
                                  });
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Thử lại'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                  final orders = snapshot.data ?? const <Order>[];
                  if (orders.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 80),
                        Center(child: Text('Không có order nào.')),
                      ],
                    );
                  }
                  final timeFormat = DateFormat('dd/MM/yyyy HH:mm');
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      final openedAt = DateTime.tryParse(order.createdAt ?? '');
                      final closedAt = DateTime.tryParse(order.closedAt ?? '');
                      final areaLabel =
                          order.areaCode ?? order.areaName ?? '';
                      final tableLabel =
                          order.tableName ?? order.tableCode ?? '---';
                      final infoParts = <String>[
                        if (areaLabel.isNotEmpty) 'Khu $areaLabel',
                        if (order.customerName != null && order.customerName!.trim().isNotEmpty)
                          'KH: ${order.customerName}',
                        if (order.openedByName != null && order.openedByName!.trim().isNotEmpty)
                          'NV: ${order.openedByName}',
                        if (openedAt != null)
                          'Mở: ${timeFormat.format(openedAt)}',
                        if (closedAt != null && order.status == 'closed')
                          'Đóng: ${timeFormat.format(closedAt)}',
                      ];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            foregroundColor: theme.colorScheme.onPrimaryContainer,
                            child: const Icon(Icons.receipt_long),
                          ),
                          title: Text('Order #${order.id} • Bàn $tableLabel'),
                          subtitle: Text(infoParts.join(' • ')),
                          trailing: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                currency.format(order.total ?? 0),
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusColor(order.status, theme)
                                      .withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _statusLabel(order.status),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: _statusColor(order.status, theme),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          onTap: () => _openOrder(order),
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemCount: orders.length,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
