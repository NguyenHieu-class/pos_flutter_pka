import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/currency.dart';
import '../../../core/exceptions.dart';
import '../../../domain/models/bill_item.dart';
import '../../../domain/models/order.dart';
import '../../../widgets/app_settings_button.dart';
import '../../../widgets/skeleton.dart';
import '../controllers/orders_log_controller.dart';

class OrderLogDetailPage extends ConsumerWidget {
  const OrderLogDetailPage({
    super.key,
    required this.orderId,
  });

  final int orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(orderLogDetailProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #$orderId'),
        actions: const [AppSettingsButton()],
      ),
      body: detailAsync.when(
        data: (detail) {
          final order = detail.order;
          final items = order.items.map(BillItem.fromOrderItem).toList(growable: false);
          final createdAt = order.createdAt;
          final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detail.tableName,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(label: 'Trạng thái', value: order.status.label),
                      _InfoRow(
                        label: 'Tạo lúc',
                        value: createdAt != null ? dateFormat.format(createdAt) : '-',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: items.isEmpty
                      ? const Center(child: Text('Hoá đơn không có món.'))
                      : Column(
                          children: [
                            ...items.map(
                              (item) => Column(
                                children: [
                                  _BillItemTile(item: item),
                                  if (item != items.last) const Divider(),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _SummarySection(order: order),
                ),
              ),
            ],
          );
        },
        loading: () => const _OrderDetailSkeleton(),
        error: (error, stackTrace) {
          final message = error is AppException
              ? error.message
              : 'Không thể tải chi tiết hoá đơn. Vui lòng thử lại.';
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                message,
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OrderDetailSkeleton extends StatelessWidget {
  const _OrderDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 180, height: 18),
                SizedBox(height: 12),
                SkeletonBox(width: 140, height: 14),
                SizedBox(height: 8),
                SkeletonBox(width: 160, height: 14),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                SkeletonBox(width: double.infinity, height: 20),
                SizedBox(height: 12),
                SkeletonBox(width: double.infinity, height: 20),
                SizedBox(height: 12),
                SkeletonBox(width: double.infinity, height: 20),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 120, height: 16),
                SizedBox(height: 12),
                SkeletonBox(width: 200, height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _BillItemTile extends StatelessWidget {
  const _BillItemTile({required this.item});

  final BillItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        item.name,
        style: theme.textTheme.titleMedium,
      ),
      subtitle: Text('x${item.quantity} • ${formatVND(item.unitPrice)}'),
      trailing: Text(
        formatVND(item.amount),
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SummaryRow(label: 'Tạm tính', value: formatVND(order.subtotal)),
        _SummaryRow(
          label: 'Giảm giá',
          value: order.discountAmount == 0
              ? formatVND(0)
              : '-${formatVND(order.discountAmount)}',
        ),
        const Divider(height: 24),
        Text(
          'Tổng thanh toán',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          formatVND(order.total),
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
