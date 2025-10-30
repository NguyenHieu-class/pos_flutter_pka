import 'package:flutter/material.dart';

import '../models/table.dart';

/// Card representing a dining table selection item.
class TableTile extends StatelessWidget {
  const TableTile({
    super.key,
    required this.table,
    this.onTap,
    this.onLongPress,
    this.statusLabel,
    this.statusColor,
    this.trailing,
  });

  final DiningTable table;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? statusLabel;
  final Color? statusColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = statusColor?.withOpacity(0.12) ??
        theme.colorScheme.primaryContainer;
    final iconColor = statusColor ?? theme.colorScheme.onPrimaryContainer;
    final textStyle = theme.textTheme.bodySmall;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.table_bar,
                      size: 48,
                      color: iconColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      table.name,
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    if (table.capacity != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Sức chứa: ${table.capacity}',
                          style: textStyle,
                        ),
                      ),
                    if (table.openOrderId != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Order #${table.openOrderId}',
                          style: textStyle,
                        ),
                      ),
                  ],
                ),
              ),
              if (statusLabel != null)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor ?? theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusLabel!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              if (trailing != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: trailing!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
