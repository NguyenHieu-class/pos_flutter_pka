import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/cart_controller.dart';
import '../controllers/category_controller.dart';
import '../controllers/menu_controller.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final CategoryController categoryController = Get.find<CategoryController>();
  final MenuController menuController = Get.find<MenuController>();
  final CartController cartController = Get.find<CartController>();

  late final TextEditingController _searchController;
  late final TextEditingController _tableController;
  Worker? _tableWatcher;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: menuController.searchQuery.value);
    _tableController = TextEditingController(text: cartController.tableNumber.value);
    _tableWatcher = ever<String>(cartController.tableNumber, (value) {
      if (_tableController.text != value) {
        _tableController.text = value;
      }
    });
    menuController.loadMenuItems();
  }

  @override
  void dispose() {
    _tableWatcher?.dispose();
    _searchController.dispose();
    _tableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('POS Gọi món'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Danh mục',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: Obx(() {
                      if (categoryController.isLoading.value) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final categories = categoryController.categories;
                      if (categories.isEmpty) {
                        return const Center(child: Text('Không có danh mục.'));
                      }
                      final selected = categoryController.selectedCategory.value;
                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final isSelected = selected?.id == category.id;
                          return ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            tileColor: isSelected ? theme.colorScheme.primary.withOpacity(0.12) : null,
                            title: Text(category.name),
                            onTap: () {
                              categoryController.selectCategory(category);
                            },
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemCount: categories.length,
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: menuController.setSearchQuery,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Tìm kiếm món ăn',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                Expanded(
                  child: Obx(() {
                    if (menuController.isLoading.value) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final items = menuController.menuItems;
                    if (items.isEmpty) {
                      return const Center(child: Text('Không có món ăn.'));
                    }
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth ~/ 220 > 2
                            ? constraints.maxWidth ~/ 220
                            : 2;
                        return GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 4 / 5,
                          ),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return _MenuCard(
                              item: item,
                              onAdd: () => cartController.addToCart(item),
                            );
                          },
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Giỏ hàng',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _tableController,
                          decoration: InputDecoration(
                            labelText: 'Số bàn',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onChanged: cartController.setTableNumber,
                        ),
                        const SizedBox(height: 12),
                        Obx(() {
                          final orderType = cartController.orderType.value;
                          return Wrap(
                            spacing: 12,
                            children: [
                              ChoiceChip(
                                label: const Text('Tại bàn'),
                                selected: orderType == 'dine-in',
                                onSelected: (_) => cartController.setOrderType('dine-in'),
                              ),
                              ChoiceChip(
                                label: const Text('Mang đi'),
                                selected: orderType == 'takeaway',
                                onSelected: (_) => cartController.setOrderType('takeaway'),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Obx(() {
                      final cartItems = cartController.cartItems;
                      if (cartItems.isEmpty) {
                        return const Center(child: Text('Chưa có món nào trong giỏ.'));
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemBuilder: (context, index) {
                          final item = cartItems[index];
                          return _CartItemTile(
                            item: item,
                            onIncrease: () => cartController.incrementQuantity(item),
                            onDecrease: () => cartController.decrementQuantity(item),
                            onRemove: () => cartController.removeItem(item),
                            onNoteChanged: (note) => cartController.setNoteForItem(item, note),
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemCount: cartItems.length,
                      );
                    }),
                  ),
                  Container(
                    color: Colors.grey.shade100,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Obx(() {
                          return Text(
                            'Tổng: ${cartController.totalAmount.toStringAsFixed(0)}đ',
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          );
                        }),
                        const SizedBox(height: 12),
                        Obx(() {
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              ElevatedButton.icon(
                                onPressed: cartController.isSubmitting.value
                                    ? null
                                    : () {
                                        cartController.submitOrder();
                                      },
                                icon: cartController.isSubmitting.value
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.send),
                                label: const Text('Gửi đơn hàng'),
                              ),
                              OutlinedButton.icon(
                                onPressed: cartController.cartItems.isEmpty
                                    ? null
                                    : cartController.printTemporaryBill,
                                icon: const Icon(Icons.print),
                                label: const Text('In tạm tính'),
                              ),
                              FilledButton.icon(
                                onPressed: cartController.isMarkingPaid.value
                                    ? null
                                    : cartController.markOrderPaid,
                                icon: cartController.isMarkingPaid.value
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.check_circle_outline),
                                label: const Text('Thanh toán'),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.item, required this.onAdd});

  final MenuItem item;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onAdd,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: _MenuImage(imagePath: item.imagePath), 
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${item.price.toStringAsFixed(0)}đ',
                    style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),
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

class _MenuImage extends StatelessWidget {
  const _MenuImage({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    if (imagePath.isEmpty) {
      return _placeholder();
    }

    final file = File(imagePath);
    if (!file.existsSync()) {
      return _placeholder();
    }

    return Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey.shade300,
      child: const Center(child: Icon(Icons.image_not_supported, size: 48)),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
    required this.onNoteChanged,
  });

  final CartItem item;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;
  final ValueChanged<String> onNoteChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.menuItem.name,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: onDecrease,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('${item.quantity}'),
              IconButton(
                onPressed: onIncrease,
                icon: const Icon(Icons.add_circle_outline),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Giá: ${item.menuItem.price.toStringAsFixed(0)}đ'),
          const SizedBox(height: 4),
          Text('Thành tiền: ${item.totalPrice.toStringAsFixed(0)}đ'),
          const SizedBox(height: 8),
          TextFormField(
            key: ValueKey('${item.menuItem.id}-${item.quantity}-${item.note.hashCode}'),
            initialValue: item.note,
            onChanged: onNoteChanged,
            decoration: const InputDecoration(
              labelText: 'Ghi chú',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
