import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/currency.dart';
import '../../../domain/models/order.dart';
import '../../../domain/models/order_log.dart';
import '../controllers/orders_log_controller.dart';
import 'order_log_detail_page.dart';

class OrdersLogPage extends ConsumerStatefulWidget {
  const OrdersLogPage({super.key});

  @override
  ConsumerState<OrdersLogPage> createState() => _OrdersLogPageState();
}

class _OrdersLogPageState extends ConsumerState<OrdersLogPage> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    ref.listen<OrdersLogState>(ordersLogControllerProvider, (previous, next) {
      final message = next.errorMessage;
      if (!mounted || message == null || message.isEmpty || message == previous?.errorMessage) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      ref.read(ordersLogControllerProvider.notifier).clearError();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ordersLogControllerProvider);
    final controller = ref.read(ordersLogControllerProvider.notifier);

    if (!_searchFocusNode.hasFocus && _searchController.text != state.query) {
      _searchController.value = TextEditingValue(
        text: state.query,
        selection: TextSelection.collapsed(offset: state.query.length),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders Log'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FilterBar(state: state, onFilterSelected: _onFilterSelected),
            if (state.filter == OrdersLogDateFilter.custom && state.customRange != null) ...[
              const SizedBox(height: 8),
              Text(
                _formatRange(state.customRange!),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Tìm kiếm theo mã đơn hoặc tên bàn',
                border: OutlineInputBorder(),
              ),
              onChanged: controller.setQuery,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: controller.refresh,
                    child: _OrdersList(
                      orders: state.orders,
                      isLoading: state.isLoading,
                    ),
                  ),
                  if (state.isLoading && state.orders.isEmpty)
                    const Center(child: CircularProgressIndicator()),
                  if (state.isLoading && state.orders.isNotEmpty)
                    const Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(minHeight: 3),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onFilterSelected(OrdersLogDateFilter filter) async {
    final controller = ref.read(ordersLogControllerProvider.notifier);
    if (filter == OrdersLogDateFilter.custom) {
      final state = ref.read(ordersLogControllerProvider);
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final initialRange = state.customRange ??
          DateTimeRange(
            start: startOfDay,
            end: startOfDay.add(const Duration(days: 1)),
          );

      final range = await showDateRangePicker(
        context: context,
        initialDateRange: initialRange,
        firstDate: DateTime(now.year - 5),
        lastDate: DateTime(now.year + 1, 12, 31),
        helpText: 'Chọn khoảng thời gian',
      );

      if (range != null) {
        controller.setCustomRange(range);
      }
      return;
    }

    controller.setFilter(filter);
  }

  String _formatRange(DateTimeRange range) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final startDate = DateTime(range.start.year, range.start.month, range.start.day);
    final endDate = DateTime(range.end.year, range.end.month, range.end.day);
    final start = dateFormat.format(startDate);
    final end = dateFormat.format(endDate);
    if (start == end) {
      return 'Ngày: $start';
    }
    return 'Khoảng: $start - $end';
  }
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar({
    required this.state,
    required this.onFilterSelected,
  });

  final OrdersLogState state;
  final Future<void> Function(OrdersLogDateFilter filter) onFilterSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SegmentedButton<OrdersLogDateFilter>(
      segments: OrdersLogDateFilter.values
          .map(
            (filter) => ButtonSegment<OrdersLogDateFilter>(
              value: filter,
              label: Text(filter.label),
            ),
          )
          .toList(growable: false),
      selected: {state.filter},
      onSelectionChanged: (selection) {
        if (selection.isEmpty) {
          return;
        }
        onFilterSelected(selection.first);
      },
    );
  }
}

class _OrdersList extends ConsumerWidget {
  const _OrdersList({
    required this.orders,
    required this.isLoading,
  });

  final List<OrderLogEntry> orders;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (orders.isEmpty && !isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(child: Text('Không tìm thấy đơn nào.')),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final order = orders[index];
        return _OrderTile(order: order);
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: orders.length,
    );
  }
}

class _OrderTile extends ConsumerWidget {
  const _OrderTile({required this.order});

  final OrderLogEntry order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final subtitleStyle = theme.textTheme.bodyMedium;
    final statusColor = _statusColor(order.status, theme.colorScheme);

    return Card(
      child: ListTile(
        onTap: order.status == OrderStatus.paid
            ? () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => OrderLogDetailPage(orderId: order.id),
                  ),
                );
              }
            : null,
        title: Text('Order #${order.id}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(order.tableName, style: subtitleStyle),
            Text(dateFormat.format(order.createdAt), style: subtitleStyle),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatVND(order.total),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            _StatusChip(status: order.status, color: statusColor),
          ],
        ),
      ),
    );
  }

  Color _statusColor(OrderStatus status, ColorScheme colorScheme) {
    return switch (status) {
      OrderStatus.paid => Colors.green,
      OrderStatus.cancelled => colorScheme.error,
      OrderStatus.open => colorScheme.primary,
    };
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.color});

  final OrderStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
