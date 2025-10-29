import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/item.dart';
import '../services/order_service.dart';
import '../widgets/item_card.dart';

/// Screen displaying menu items and allowing filtering by category.
class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  final _orderService = OrderService.instance;
  late Future<List<MenuItem>> _itemsFuture;
  List<Category> _categories = const [];
  Category? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  void _loadInitial() {
    _itemsFuture = _orderService.fetchItems();
    _orderService.fetchCategories().then((value) {
      setState(() {
        _categories = value;
      });
    });
  }

  Future<void> _onCategorySelected(Category? category) async {
    setState(() {
      _selectedCategory = category;
      _itemsFuture = _orderService.fetchItems(categoryId: category?.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;
    final crossAxisCount = isWide ? 3 : 2;
    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách món ăn')),
      body: Column(
        children: [
          SizedBox(
            height: 64,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              scrollDirection: Axis.horizontal,
              children: [
                ChoiceChip(
                  label: const Text('Tất cả'),
                  selected: _selectedCategory == null,
                  onSelected: (_) => _onCategorySelected(null),
                ),
                ..._categories.map(
                  (category) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(category.name),
                      selected: _selectedCategory?.id == category.id,
                      onSelected: (_) => _onCategorySelected(category),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _itemsFuture =
                      _orderService.fetchItems(categoryId: _selectedCategory?.id);
                });
                await _itemsFuture;
              },
              child: FutureBuilder<List<MenuItem>>(
                future: _itemsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text('Lỗi: ${snapshot.error}'),
                        ),
                      ],
                    );
                  }
                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 48),
                        Center(child: Text('Không có món ăn.')),
                      ],
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 4 / 5,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ItemCard(item: item);
                    },
                    itemCount: items.length,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
