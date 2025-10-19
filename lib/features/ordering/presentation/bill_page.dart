import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/currency.dart';
import '../../../core/settings/app_settings_controller.dart';
import '../../../domain/models/bill_item.dart';
import '../../../domain/models/order.dart';
import '../controllers/order_controller.dart';
import '../../../widgets/app_settings_button.dart';

class BillPage extends ConsumerStatefulWidget {
  const BillPage({
    super.key,
    required this.args,
    this.tableName,
  });

  final OrderControllerArgs args;
  final String? tableName;

  @override
  ConsumerState<BillPage> createState() => _BillPageState();
}

class _BillPageState extends ConsumerState<BillPage> {
  bool? _isKeepingAwake;

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  void _updateKeepAwake(bool shouldKeepAwake) {
    if (_isKeepingAwake == shouldKeepAwake) {
      return;
    }
    _isKeepingAwake = shouldKeepAwake;
    if (shouldKeepAwake) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderControllerProvider(widget.args));
    final order = state.activeOrder;
    final keepScreenAwake = ref.watch(
      appSettingsControllerProvider.select((value) => value.keepScreenAwakeOnBill),
    );
    _updateKeepAwake(keepScreenAwake);

    ref.listen<OrderState>(orderControllerProvider(widget.args), (previous, next) {
      final message = next.errorMessage;
      if (message != null && message.isNotEmpty && message != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        ref.read(orderControllerProvider(widget.args).notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Bill #${order.id}'),
        actions: const [AppSettingsButton()],
        bottom: widget.tableName == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(24),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    widget.tableName!,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: Theme.of(context).colorScheme.onPrimary),
                  ),
                ),
              ),
      ),
      body: Stack(
        children: [
          if (state.billItems.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 80,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Chưa có món trong hoá đơn. Thêm món từ trang Menu.',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...state.billItems.map(
                  (item) => Column(
                    children: [
                      _BillItemTile(item: item),
                      const Divider(),
                    ],
                  ),
                ),
                _SummarySection(order: order),
              ],
            ),
          if (state.isLoading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(minHeight: 3),
            ),
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
        const SizedBox(height: 8),
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
          Text(
            label,
            style: theme.textTheme.bodyLarge,
          ),
          Text(
            value,
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
