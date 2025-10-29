import 'package:flutter/material.dart';

import '../models/category.dart';
import '../services/order_service.dart';
import '../widgets/category_chip.dart';

/// Screen for admins to view available categories.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _orderService = OrderService.instance;
  late Future<List<Category>> _future;

  @override
  void initState() {
    super.initState();
    _future = _orderService.fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Danh mục món ăn')),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _future = _orderService.fetchCategories();
          });
          await _future;
        },
        child: FutureBuilder<List<Category>>(
          future: _future,
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
            final categories = snapshot.data ?? [];
            if (categories.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 48),
                  Center(child: Text('Chưa có danh mục.')),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final category = categories[index];
                return CategoryChip(category: category);
              },
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemCount: categories.length,
            );
          },
        ),
      ),
    );
  }
}
