import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/table.dart';
import '../../ordering/presentation/order_page.dart';
import '../controllers/tables_controller.dart';
import '../../../widgets/app_settings_button.dart';
import '../../../widgets/skeleton.dart';

class TablesPage extends ConsumerWidget {
  const TablesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tablesControllerProvider);
    final controller = ref.read(tablesControllerProvider.notifier);

    ref.listen<TablesState>(tablesControllerProvider, (previous, next) {
      final message = next.errorMessage;
      if (message != null && message.isNotEmpty && message != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        controller.clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tables'),
        actions: const [AppSettingsButton()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SearchField(
              initialValue: state.query,
              onChanged: controller.setQuery,
            ),
            const SizedBox(height: 12),
            _StatusFilter(
              selected: state.filter,
              onSelected: controller.setFilter,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Stack(
                children: [
                  _TablesGrid(state: state, controller: controller),
                  if (state.isLoading && state.tables.isNotEmpty)
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
}

class _TablesGrid extends StatelessWidget {
  const _TablesGrid({required this.state, required this.controller});

  final TablesState state;
  final TablesController controller;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.tables.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final maxExtent = _resolveTableMaxExtent(constraints.maxWidth);
          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: maxExtent,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 16 / 9,
            ),
            itemBuilder: (_, __) => const SkeletonBox(),
          );
        },
      );
    }

    if (state.tables.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.table_bar,
                size: 80,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 12),
              Text(
                'Chưa có bàn phù hợp với bộ lọc hiện tại.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxExtent = _resolveTableMaxExtent(constraints.maxWidth);
        return GridView.builder(
          itemCount: state.tables.length,
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: maxExtent,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 16 / 9,
          ),
          itemBuilder: (context, index) {
            final table = state.tables[index];
            return _TableTile(
              table: table,
              onTap: () async {
                final orderId = await controller.openOrContinueOrder(table);
                if (orderId == null || !context.mounted) {
                  return;
                }
                final updated = await Navigator.of(context).push(
                  MaterialPageRoute<bool?>(
                    builder: (_) => OrderPage(orderId: orderId, table: table),
                  ),
                );
                if (!context.mounted) {
                  return;
                }
                if (updated == true) {
                  await controller.loadTables();
                }
              },
            );
          },
        );
      },
    );
  }
}

double _resolveTableMaxExtent(double width) {
  if (width >= 1400) {
    return 360;
  }
  if (width >= 1100) {
    return 320;
  }
  if (width >= 800) {
    return 280;
  }
  if (width >= 600) {
    return 240;
  }
  return width.clamp(200, 260);
}

class _TableTile extends StatelessWidget {
  const _TableTile({required this.table, required this.onTap});

  final PosTable table;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = _statusColor(table.status, colorScheme);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: statusColor.withOpacity(0.6), width: 1.5),
            color: statusColor.withOpacity(0.08),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      table.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    _statusIcon(table.status),
                    color: statusColor,
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      table.status.label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Capacity: ${table.capacity}')
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField({required this.initialValue, required this.onChanged});

  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant _SearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.search),
        labelText: 'Search tables',
        border: OutlineInputBorder(),
      ),
    );
  }
}

class _StatusFilter extends StatelessWidget {
  const _StatusFilter({required this.selected, required this.onSelected});

  final TableStatusFilter selected;
  final ValueChanged<TableStatusFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<TableStatusFilter>(
      segments: TableStatusFilter.values
          .map(
            (filter) => ButtonSegment<TableStatusFilter>(
              value: filter,
              label: Text(filter.label),
            ),
          )
          .toList(),
      selected: <TableStatusFilter>{selected},
      onSelectionChanged: (value) {
        if (value.isNotEmpty) {
          onSelected(value.first);
        }
      },
    );
  }
}

Color _statusColor(TableStatus status, ColorScheme colorScheme) {
  switch (status) {
    case TableStatus.available:
      return Colors.green.shade600;
    case TableStatus.occupied:
      return colorScheme.error;
    case TableStatus.reserved:
      return Colors.orange.shade700;
  }
}

IconData _statusIcon(TableStatus status) {
  switch (status) {
    case TableStatus.available:
      return Icons.event_available;
    case TableStatus.occupied:
      return Icons.person;
    case TableStatus.reserved:
      return Icons.event_busy;
  }
}
