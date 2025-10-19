import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/currency.dart';
import '../../../core/utils.dart';
import '../../../widgets/app_list_tile.dart';
import '../controllers/menu_controller.dart';

class MenuPage extends ConsumerWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(menuControllerProvider).items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        actions: [
          IconButton(
            onPressed: () => AppUtils.showNotImplementedSnackBar(context),
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: items.isEmpty
          ? const Center(
              child: Text('No menu items'),
            )
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return AppListTile(
                  title: item.name,
                  subtitle: item.category,
                  trailing: Text(formatVND(item.price)),
                  onTap: () => AppUtils.showNotImplementedSnackBar(context),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AppUtils.showNotImplementedSnackBar(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
