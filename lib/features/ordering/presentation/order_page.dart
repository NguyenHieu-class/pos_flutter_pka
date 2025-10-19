import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/currency.dart';
import '../../../domain/models/bill_item.dart';
import '../../../domain/models/order.dart';
import '../../../domain/models/table.dart';
import '../controllers/order_controller.dart';
import 'bill_page.dart';

class OrderPage extends ConsumerStatefulWidget {
  const OrderPage({
    super.key,
    required this.orderId,
    required this.table,
  });

  final int orderId;
  final PosTable table;

  @override
  ConsumerState<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends ConsumerState<OrderPage> {
  late final TextEditingController _discountController;
  late final FocusNode _discountFocusNode;

  OrderControllerArgs get _args => OrderControllerArgs(
        orderId: widget.orderId.toString(),
        tableId: widget.table.id,
      );

  @override
  void initState() {
    super.initState();
    _discountController = TextEditingController();
    _discountFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _discountController.dispose();
    _discountFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderControllerProvider(_args));
    final controller = ref.read(orderControllerProvider(_args).notifier);
    final order = state.activeOrder;

    if (!_discountFocusNode.hasFocus) {
      final formatted = _formatDiscountValue(order.discountValue);
      if (_discountController.text != formatted) {
        _discountController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    }

    ref.listen<OrderState>(orderControllerProvider(_args), (previous, next) {
      final message = next.errorMessage;
      if (message != null && message.isNotEmpty && message != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        controller.clearError();
      }
    });

    final isReadOnly = order.status != OrderStatus.open;

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${widget.orderId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => BillPage(
                    args: _args,
                    tableName: widget.table.name,
                  ),
                ),
              );
            },
            tooltip: 'Xem bill',
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(32),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              widget.table.name,
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
          Column(
            children: [
              Expanded(
                child: state.billItems.isEmpty
                    ? const _EmptyOrderView()
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final item = state.billItems[index];
                          return _OrderItemTile(
                            item: item,
                            readOnly: state.isLoading || isReadOnly,
                            onIncrease: () => controller.updateQuantity(item.id, item.quantity + 1),
                            onDecrease: () => controller.updateQuantity(item.id, item.quantity - 1),
                            onRemove: () => controller.removeItem(item.id),
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemCount: state.billItems.length,
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: _SummaryCard(
                  order: order,
                  controller: _discountController,
                  focusNode: _discountFocusNode,
                  isProcessing: state.isLoading || isReadOnly,
                  onApply: (type) => _submitDiscount(controller, type),
                ),
              ),
            ],
          ),
          if (state.isLoading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(minHeight: 3),
            ),
          if (order.status == OrderStatus.paid)
            Positioned(
              top: 24,
              left: 24,
              right: 24,
              child: Card(
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Đơn đã thanh toán'),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: FilledButton(
            onPressed: !state.canPay || state.isLoading
                ? null
                : () async {
                    final success = await controller.pay();
                    if (!mounted) return;
                    if (success) {
                      Navigator.of(context).pop(true);
                    }
                  },
            child: const Text('Thanh toán'),
          ),
        ),
      ),
    );
  }

  void _submitDiscount(OrderController controller, DiscountType type) {
    final raw = _discountController.text.trim().replaceAll(',', '.');
    final value = double.tryParse(raw) ?? 0;
    controller.applyDiscount(value, type);
    _discountFocusNode.unfocus();
  }

  String _formatDiscountValue(double value) {
    if (value == 0) {
      return '';
    }
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }
}

class _OrderItemTile extends StatelessWidget {
  const _OrderItemTile({
    required this.item,
    required this.readOnly,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
  });

  final BillItem item;
  final bool readOnly;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dismissible(
      key: ValueKey(item.id),
      direction: readOnly ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: theme.colorScheme.error.withOpacity(0.1),
        child: Icon(Icons.delete, color: theme.colorScheme.error),
      ),
      onDismissed: (_) {
        if (!readOnly) {
          onRemove();
        }
      },
      child: Material(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatVND(item.unitPrice),
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              _QuantityControl(
                quantity: item.quantity,
                onIncrease: readOnly ? null : onIncrease,
                onDecrease: readOnly ? null : onDecrease,
              ),
              const SizedBox(width: 16),
              Text(
                formatVND(item.amount),
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({
    required this.quantity,
    this.onIncrease,
    this.onDecrease,
  });

  final int quantity;
  final VoidCallback? onIncrease;
  final VoidCallback? onDecrease;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onDecrease,
          icon: const Icon(Icons.remove_circle_outline),
          color: theme.colorScheme.primary,
        ),
        Text(
          '$quantity',
          style: theme.textTheme.titleMedium,
        ),
        IconButton(
          onPressed: onIncrease,
          icon: const Icon(Icons.add_circle_outline),
          color: theme.colorScheme.primary,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.order,
    required this.controller,
    required this.focusNode,
    required this.isProcessing,
    required this.onApply,
  });

  final Order order;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isProcessing;
  final void Function(DiscountType type) onApply;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Giảm giá',
                suffixText: order.discountType == DiscountType.percent ? '%' : 'đ',
              ),
              onSubmitted: (_) => onApply(order.discountType),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<DiscountType>(
              value: order.discountType,
              decoration: const InputDecoration(labelText: 'Loại giảm giá'),
              items: DiscountType.values
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.label),
                      ))
                  .toList(),
              onChanged: isProcessing
                  ? null
                  : (type) {
                      if (type != null) {
                        onApply(type);
                      }
                    },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed:
                    isProcessing ? null : () => onApply(order.discountType),
                child: const Text('Áp dụng'),
              ),
            ),
            const Divider(height: 32),
            _SummaryRow(label: 'Tạm tính', value: formatVND(order.subtotal)),
            _SummaryRow(
              label: 'Giảm giá',
              value: order.discountAmount == 0
                  ? formatVND(0)
                  : '-${formatVND(order.discountAmount)}',
            ),
            const SizedBox(height: 8),
            Text(
              'Tổng thanh toán',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              formatVND(order.total),
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
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
          Text(label, style: theme.textTheme.bodyLarge),
          Text(value, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _EmptyOrderView extends StatelessWidget {
  const _EmptyOrderView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long,
            size: 72,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          const Text('Chưa có món trong đơn hàng'),
        ],
      ),
    );
  }
}
