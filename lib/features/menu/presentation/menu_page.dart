import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/currency.dart';
import '../../../core/providers/documents_directory_provider.dart';
import '../../../domain/models/menu_item.dart';
import '../../../widgets/app_settings_button.dart';
import '../../../widgets/skeleton.dart';
import '../../ordering/controllers/order_controller.dart';
import '../../ordering/controllers/order_draft_controller.dart';
import '../controllers/menu_controller.dart' as menu;
import 'menu_admin_page.dart';

class MenuPage extends ConsumerWidget {
  const MenuPage({super.key, required this.orderArgs});

  final OrderControllerArgs orderArgs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(menu.menuControllerProvider);
    final menuController = ref.read(menu.menuControllerProvider.notifier);

    ref.listen<menu.MenuState>(menu.menuControllerProvider, (previous, next) {
      final message = next.errorMessage;
      if (message != null && message.isNotEmpty && message != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        menuController.clearError();
      }
    });

    ref.listen<OrderState>(orderControllerProvider(orderArgs), (previous, next) {
      final message = next.errorMessage;
      if (message != null && message.isNotEmpty && message != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        ref.read(orderControllerProvider(orderArgs).notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        actions: [
          IconButton(
            tooltip: 'Quản lý menu',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MenuAdminPage(),
                ),
              );
            },
            icon: const Icon(Icons.manage_accounts),
          ),
          const AppSettingsButton(),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MenuSearchBar(
              initialValue: state.query,
              onChanged: menuController.setQuery,
            ),
            const SizedBox(height: 12),
            _MenuFilters(state: state, controller: menuController),
            const SizedBox(height: 16),
            Expanded(
              child: Stack(
                children: [
                  _MenuGrid(state: state, orderArgs: orderArgs),
                  if (state.isLoading)
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

class _MenuFilters extends StatelessWidget {
  const _MenuFilters({required this.state, required this.controller});

  final menu.MenuState state;
  final menu.MenuController controller;

  @override
  Widget build(BuildContext context) {
    final categories = state.categories;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DropdownButtonFormField<String?>(
            value: state.selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: <DropdownMenuItem<String?>>[
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Tất cả'),
              ),
              ...categories.map(
                (category) => DropdownMenuItem<String?>(
                  value: category,
                  child: Text(category),
                ),
              ),
            ],
            onChanged: controller.setCategory,
          ),
        ),
        const SizedBox(width: 12),
        _OnlyActiveSwitch(
          value: state.onlyActive,
          onChanged: controller.toggleOnlyActive,
        ),
      ],
    );
  }
}

class _OnlyActiveSwitch extends StatelessWidget {
  const _OnlyActiveSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'Chỉ đang bán',
          style: theme.textTheme.labelLarge,
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _MenuSearchBar extends StatefulWidget {
  const _MenuSearchBar({required this.initialValue, required this.onChanged});

  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  State<_MenuSearchBar> createState() => _MenuSearchBarState();
}

class _MenuSearchBarState extends State<_MenuSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _MenuSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue &&
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      controller: _controller,
      leading: const Icon(Icons.search),
      hintText: 'Tìm món...',
      onChanged: widget.onChanged,
    );
  }
}

class _MenuGrid extends ConsumerWidget {
  const _MenuGrid({required this.state, required this.orderArgs});

  final menu.MenuState state;
  final OrderControllerArgs orderArgs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading && state.items.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final maxExtent = _resolveMenuMaxExtent(constraints.maxWidth);
          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: maxExtent,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 3 / 4,
            ),
            itemCount: 6,
            itemBuilder: (_, __) => const _MenuCardSkeleton(),
          );
        },
      );
    }

    if (state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.restaurant_menu,
                size: 80,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 12),
              Text(
                'Không tìm thấy món phù hợp. Thử đổi bộ lọc hoặc từ khoá.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxExtent = _resolveMenuMaxExtent(constraints.maxWidth);
        return GridView.builder(
          itemCount: state.items.length,
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: maxExtent,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 3 / 4,
          ),
          itemBuilder: (context, index) {
            final item = state.items[index];
            return _MenuCard(item: item, orderArgs: orderArgs);
          },
        );
      },
    );
  }
}

double _resolveMenuMaxExtent(double width) {
  if (width >= 1400) {
    return 340;
  }
  if (width >= 1100) {
    return 300;
  }
  if (width >= 800) {
    return 260;
  }
  if (width >= 600) {
    return 240;
  }
  return width.clamp(200, 240);
}

class _MenuCardSkeleton extends StatelessWidget {
  const _MenuCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Expanded(
              child: SkeletonBox(),
            ),
            SizedBox(height: 12),
            SkeletonBox(width: 180, height: 18),
            SizedBox(height: 6),
            SkeletonBox(width: 120, height: 14),
            SizedBox(height: 10),
            SkeletonBox(width: 100, height: 18),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends ConsumerWidget {
  const _MenuCard({required this.item, required this.orderArgs});

  final MenuItem item;
  final OrderControllerArgs orderArgs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          if (!item.isActive) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('"${item.name}" hiện không bán.')),
            );
            return;
          }
          await _showAddToOrderSheet(context, item, orderArgs);
        },
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.isActive
                  ? colorScheme.outlineVariant
                  : colorScheme.error.withOpacity(0.4),
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    color: colorScheme.surfaceVariant,
                    alignment: Alignment.center,
                    child: _MenuItemImage(item: item),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                item.name,
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                item.category,
                style: textTheme.bodySmall?.copyWith(color: colorScheme.outline),
              ),
              const SizedBox(height: 8),
              Text(
                formatVND(item.price),
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!item.isActive) ...[
                const SizedBox(height: 8),
                Text(
                  'Ngưng bán',
                  style: textTheme.labelMedium?.copyWith(color: colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItemImage extends ConsumerWidget {
  const _MenuItemImage({required this.item});

  final MenuItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final imagePath = item.imagePath;
    if (imagePath == null || imagePath.isEmpty) {
      return Icon(
        Icons.restaurant,
        size: 40,
        color: colorScheme.outline,
      );
    }

    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.restaurant,
            size: 40,
            color: colorScheme.outline,
          );
        },
      );
    }

    final documentsDirectory = ref.watch(documentsDirectoryProvider);
    return documentsDirectory.when(
      data: (dir) {
        final file = File(p.join(dir, imagePath));
        if (!file.existsSync()) {
          return Icon(
            Icons.broken_image_outlined,
            size: 40,
            color: colorScheme.outline,
          );
        }
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.restaurant,
              size: 40,
              color: colorScheme.outline,
            );
          },
        );
      },
      loading: () => const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (error, stackTrace) => Icon(
        Icons.broken_image_outlined,
        size: 40,
        color: colorScheme.error,
      ),
    );
  }
}

Future<void> _showAddToOrderSheet(
  BuildContext context,
  MenuItem item,
  OrderControllerArgs orderArgs,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Consumer(
          builder: (context, ref, _) {
            final draftState = ref.watch(orderDraftControllerProvider);
            final draft = draftState[item.id] ?? const OrderDraftLine();
            final draftController = ref.read(orderDraftControllerProvider.notifier);
            final orderController =
                ref.read(orderControllerProvider(orderArgs).notifier);

            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(formatVND(item.price)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        IconButton(
                          onPressed: draft.quantity > 1
                              ? () => draftController
                                  .setQuantity(item.id, draft.quantity - 1)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text(
                          '${draft.quantity}',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          onPressed: () =>
                              draftController.setQuantity(item.id, draft.quantity + 1),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                        const Spacer(),
                        Text(
                          formatVND(item.price * draft.quantity),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: draft.note ?? '',
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú',
                        border: OutlineInputBorder(),
                      ),
                      minLines: 1,
                      maxLines: 3,
                      onChanged: (value) => draftController.setNote(item.id, value),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          final success = await orderController.addItem(
                            item.id,
                            draft.quantity,
                            note: draft.note,
                          );
                          if (!sheetContext.mounted) {
                            return;
                          }
                          if (success) {
                            draftController.clear(item.id);
                            Navigator.of(sheetContext).pop();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Đã thêm ${item.name} vào đơn.')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('Thêm vào đơn'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    },
  );
}
