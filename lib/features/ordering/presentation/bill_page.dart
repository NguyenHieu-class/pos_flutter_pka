import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/currency.dart';
import '../../../core/utils.dart';
import '../controllers/order_controller.dart';

class BillPage extends ConsumerWidget {
  const BillPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderControllerProvider).activeOrder;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill'),
      ),
      body: order.items.isEmpty
          ? const Center(
              child: Text('No active bill'),
            )
          : ListView.separated(
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
                  title: Text(item.item.name),
                  subtitle: Text('x${item.quantity}'),
                  trailing: Text(formatVND(item.total)),
                );
              },
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
