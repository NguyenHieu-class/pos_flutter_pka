import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils.dart';
import '../../../widgets/app_list_tile.dart';
import '../controllers/tables_controller.dart';

class TablesPage extends ConsumerWidget {
  const TablesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tables = ref.watch(tablesControllerProvider).tables;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tables'),
        actions: [
          IconButton(
            onPressed: () => AppUtils.showNotImplementedSnackBar(context),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: tables.isEmpty
          ? const Center(
              child: Text('No tables available'),
            )
          : ListView.builder(
              itemCount: tables.length,
              itemBuilder: (context, index) {
                final table = tables[index];
                return AppListTile(
                  title: table.name,
                  subtitle: 'Capacity: ${table.capacity}',
                  trailing: Icon(
                    table.isOccupied ? Icons.person : Icons.person_outline,
                  ),
                  onTap: () => AppUtils.showNotImplementedSnackBar(context),
                );
              },
            ),
    );
  }
}
