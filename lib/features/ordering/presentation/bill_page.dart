import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/currency.dart';
import '../../../core/utils.dart';
import '../controllers/order_controller.dart';

class BillPage extends ConsumerWidget {
  const BillPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(orderControllerProvider);
    final order = state.activeOrder;

    ref.listen<OrderState>(orderControllerProvider, (previous, next) {
      final message = next.errorMessage;
      if (message != null && message.isNotEmpty && message != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        ref.read(orderControllerProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill'),
      ),
      body: Stack(
        children: [
          if (order.items.isEmpty)
            const Center(
              child: Text('No active bill'),
            )
          else
            ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: order.items.length + 1,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                if (index == order.items.length) {
                  return ListTile(
                    title: const Text(
                      'Total',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: Text(
                      formatVND(order.total),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }
                final item = order.items[index];
                return ListTile(
                  title: Text(item.name),
                  subtitle: Text('x${item.quantity}${item.note != null ? ' • ${item.note}' : ''}'),
                  trailing: Text(formatVND(item.total)),
                );
              },
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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: () => AppUtils.showNotImplementedSnackBar(context),
          icon: const Icon(Icons.print),
          label: const Text('Finalize Bill'),
        ),
      ),
    );
  }
}
