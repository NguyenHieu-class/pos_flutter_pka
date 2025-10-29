import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/category.dart';
import '../models/item.dart';
import '../models/modifier.dart';
import '../models/order.dart';
import '../services/api_service.dart';
import '../services/order_service.dart';
import '../widgets/item_card.dart';
import '../widgets/order_tile.dart';
import '../utils/json_utils.dart';

/// Screen showing order details and enabling cashiers to add dishes and checkout.
class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId, required this.tableName});

  final int orderId;
  final String tableName;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _orderService = OrderService.instance;
  late Future<Order> _orderFuture;
  late Future<List<MenuItem>> _menuFuture;
  List<Category> _categories = const [];
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _orderFuture = _orderService.fetchOrderDetail(widget.orderId);
    _menuFuture = _orderService.fetchItems();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _orderService.fetchCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
      });
    } catch (error) {
      debugPrint('Không thể tải danh mục: $error');
    }
  }

  Future<void> _refreshOrder() async {
    setState(() {
      _orderFuture = _orderService.fetchOrderDetail(widget.orderId);
    });
    await _orderFuture;
  }

  void _selectCategory(int? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _menuFuture = _orderService.fetchItems(categoryId: categoryId);
    });
  }

  Future<void> _addItem(MenuItem item) async {
    try {
      final modifiers = await _orderService.fetchItemModifiers(item.id);
      final noteController = TextEditingController();
      int quantity = 1;
      final selectedModifiers = <int>{};
      final confirmed = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 24,
            ),
            child: StatefulBuilder(
              builder: (context, setStateBottomSheet) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          onPressed: quantity > 1
                              ? () => setStateBottomSheet(() {
                                    quantity--;
                                  })
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text('$quantity', style: const TextStyle(fontSize: 18)),
                        IconButton(
                          onPressed: () => setStateBottomSheet(() {
                                quantity++;
                              }),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                        const Spacer(),
                        Text(
                          NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
                              .format(item.price * quantity),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    if (modifiers.isNotEmpty) ...[
                      const Divider(),
                      Text('Chọn topping',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: modifiers
                            .map(
                              (modifier) => FilterChip(
                                label: Text('${modifier.name} '
                                    '+${modifier.price != null ? NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(modifier.price) : ''}'),
                                selected: selectedModifiers.contains(modifier.id),
                                onSelected: (value) {
                                  setStateBottomSheet(() {
                                    if (value) {
                                      selectedModifiers.add(modifier.id);
                                    } else {
                                      selectedModifiers.remove(modifier.id);
                                    }
                                  });
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const Divider(),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(labelText: 'Ghi chú'),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Thêm vào order'),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          );
        },
      );
      if (confirmed != true) {
        noteController.dispose();
        return;
      }
      final noteText = noteController.text.trim();
      noteController.dispose();
      await _orderService.addItemToOrder(
        orderId: widget.orderId,
        itemId: item.id,
        quantity: quantity,
        modifiers: selectedModifiers.isEmpty
            ? null
            : selectedModifiers.toList(),
        note: noteText.isEmpty ? null : noteText,
      );
      if (!mounted) return;
      await _refreshOrder();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã thêm ${item.name} vào order')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể thêm món: $error')),
      );
    }
  }

  Future<void> _checkout() async {
    try {
      final result = await _orderService.checkoutOrder(widget.orderId);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Thanh toán thành công'),
            content: Text('Tổng tiền: '
                '${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(parseDouble(result['total']) ?? 0)}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          );
        },
      );
      if (!mounted) return;
      Navigator.pop(context);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Không thể thanh toán: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    Widget buildMenuSection(bool wideLayout) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 64,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              scrollDirection: Axis.horizontal,
              children: [
                ChoiceChip(
                  label: const Text('Tất cả'),
                  selected: _selectedCategoryId == null,
                  onSelected: (_) => _selectCategory(null),
                ),
                ..._categories.map(
                  (category) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(category.name),
                      selected: _selectedCategoryId == category.id,
                      onSelected: (_) => _selectCategory(category.id),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<MenuItem>>(
              future: _menuFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return const Center(child: Text('Không có món.'));
                }
                final crossAxisCount = wideLayout ? 3 : 2;
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 4 / 5,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ItemCard(
                      item: item,
                      onTap: () => _addItem(item),
                    );
                  },
                );
              },
            ),
          ),
        ],
      );
    }

    Widget buildOrderSection() {
      return FutureBuilder<Order>(
        future: _orderFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }
          final order = snapshot.data;
          if (order == null) {
            return const Center(child: Text('Không tìm thấy order.'));
          }
          final total = order.total ?? order.items.fold<double>(
              0,
              (sum, item) =>
                  sum + (item.lineTotal ?? (item.unitPrice ?? 0) * item.quantity));
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Text('Bàn ${order.tableName ?? widget.tableName}'),
                subtitle: Text('Order #${order.id} • Khách: ${order.customerName ?? '---'}'),
                trailing: Text(
                  NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(total),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Divider(),
              Expanded(
                child: order.items.isEmpty
                    ? const Center(child: Text('Chưa có món trong order.'))
                    : ListView.builder(
                        itemCount: order.items.length,
                        itemBuilder: (context, index) {
                          final item = order.items[index];
                          return OrderTile(
                            title: item.name,
                            quantity: item.quantity,
                            note: item.note,
                            modifiers: item.modifiers,
                            subtitle: item.kitchenStatus ?? '',
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: order.items.isEmpty ? null : _checkout,
                  child: const Text('Thanh toán & In hoá đơn'),
                ),
              ),
            ],
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Order bàn ${widget.tableName}')),
      body: isWide
          ? Row(
              children: [
                Expanded(flex: 2, child: buildMenuSection(true)),
                Expanded(child: buildOrderSection()),
              ],
            )
          : Column(
              children: [
                Expanded(child: buildMenuSection(false)),
                SizedBox(height: 360, child: buildOrderSection()),
              ],
            ),
    );
  }
}
