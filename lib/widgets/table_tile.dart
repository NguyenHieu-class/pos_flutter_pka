import 'package:flutter/material.dart';

import '../models/table.dart';

/// Card representing a dining table selection item.
class TableTile extends StatelessWidget {
  const TableTile({super.key, required this.table, this.onTap});

  final DiningTable table;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFree = table.status == null || table.status == 'free';
    return InkWell(
      onTap: isFree ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          color: isFree
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.table_bar,
                size: 48,
                color: isFree
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.outline,
              ),
              const SizedBox(height: 12),
              Text(
                table.name,
                style: theme.textTheme.titleMedium,
              ),
              if (table.capacity != null)
                Text('Sức chứa: ${table.capacity}',
                    style: theme.textTheme.bodySmall),
              if (!isFree)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Đang sử dụng',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
