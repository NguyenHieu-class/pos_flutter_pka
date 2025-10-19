import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/menu_item.dart';
import 'menu_repo.dart';

class FakeMenuRepository extends MenuRepository {
  FakeMenuRepository();

  final List<MenuItem> _items = <MenuItem>[
    const MenuItem(
      id: 'CFE1',
      name: 'Cà phê sữa đá',
      category: 'Cà phê',
      price: 28000,
      imagePath: null,
    ),
    const MenuItem(
      id: 'CFE2',
      name: 'Bạc xỉu',
      category: 'Cà phê',
      price: 30000,
      imagePath: null,
    ),
    const MenuItem(
      id: 'TEA1',
      name: 'Trà đào cam sả',
      category: 'Trà trái cây',
      price: 45000,
      imagePath: null,
    ),
    const MenuItem(
      id: 'TEA2',
      name: 'Trà vải hoa hồng',
      category: 'Trà trái cây',
      price: 48000,
      imagePath: null,
    ),
    const MenuItem(
      id: 'SNK1',
      name: 'Bánh croissant bơ',
      category: 'Bánh ngọt',
      price: 38000,
      imagePath: null,
    ),
    const MenuItem(
      id: 'SNK2',
      name: 'Bánh tiramisu',
      category: 'Bánh ngọt',
      price: 52000,
      imagePath: null,
      isActive: false,
    ),
    const MenuItem(
      id: 'JCE1',
      name: 'Nước ép cam',
      category: 'Nước ép',
      price: 42000,
      imagePath: null,
    ),
    const MenuItem(
      id: 'JCE2',
      name: 'Sinh tố bơ',
      category: 'Sinh tố',
      price: 55000,
      imagePath: null,
    ),
  ];

  @override
  Future<List<MenuItem>> listMenu({
    String? query,
    String? category,
    bool? isActive,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    Iterable<MenuItem> result = _items;

    if (category != null && category.isNotEmpty) {
      result = result.where((item) => item.category == category);
    }

    if (query != null && query.trim().isNotEmpty) {
      final normalized = query.trim().toLowerCase();
      result = result.where(
        (item) => item.name.toLowerCase().contains(normalized),
      );
    }

    if (isActive != null) {
      result = result.where((item) => item.isActive == isActive);
    }

    return List<MenuItem>.unmodifiable(result);
  }

  @override
  Future<double> getItemPrice(String itemId) async {
    final item = _items.firstWhere(
      (element) => element.id == itemId,
      orElse: () =>
          throw StateError('Menu item with id $itemId could not be found'),
    );
    return item.price;
  }

  @override
  Future<MenuItem> create(MenuItem item) async {
    final newItem = item;
    _items.add(newItem);
    return newItem;
  }

  @override
  Future<MenuItem> update(MenuItem item) async {
    final index = _items.indexWhere((element) => element.id == item.id);
    if (index == -1) {
      throw StateError('Menu item with id ${item.id} could not be found');
    }
    _items[index] = item;
    return item;
  }

  @override
  Future<MenuItem> toggleActive(String itemId, bool isActive) async {
    final index = _items.indexWhere((element) => element.id == itemId);
    if (index == -1) {
      throw StateError('Menu item with id $itemId could not be found');
    }
    final updated = _items[index].copyWith(isActive: isActive);
    _items[index] = updated;
    return updated;
  }
}

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  return FakeMenuRepository();
});
