import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/menu_item.dart';
import '../../domain/models/order.dart';
import '../../domain/models/order_item.dart';
import 'menu_repo.dart';
import 'order_repo.dart';

class FakeOrderRepository extends OrderRepository {
  FakeOrderRepository(this._menuRepository) {
    _orders[_defaultOrderId] = Order(
      id: _defaultOrderId,
      tableId: 'T1',
      items: const <OrderItem>[],
    );
  }

  final MenuRepository _menuRepository;
  final Map<String, Order> _orders = <String, Order>{};
  int _nextItemId = 1;

  static const _defaultOrderId = 'demo-order';

  @override
  Future<Order?> fetchOrder(String orderId) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return _orders[orderId];
  }

  @override
  Future<void> saveOrder(Order order) async {
    _orders[order.id] = order;
  }

  @override
  Future<void> closeOrder(String orderId) async {
    final order = _orders[orderId];
    if (order == null) {
      return;
    }
    _orders[orderId] = order.copyWith(isClosed: true);
  }

  @override
  Future<void> addItem(
    String orderId,
    String itemId,
    int quantity, {
    String? note,
  }) async {
    if (quantity <= 0) {
      throw ArgumentError.value(quantity, 'quantity', 'Must be greater than 0');
    }

    final items = await _menuRepository.listMenu();
    final menuItem = items.firstWhere(
      (item) => item.id == itemId,
      orElse: () =>
          throw StateError('Menu item with id $itemId could not be found'),
    );

    if (!menuItem.isActive) {
      throw StateError('Món ${menuItem.name} hiện không bán');
    }

    final unitPrice = await _menuRepository.getItemPrice(itemId);
    final existingOrder = _orders.putIfAbsent(
      orderId,
      () => Order(id: orderId, tableId: 'T1', items: const <OrderItem>[]),
    );

    final currentItems = List<OrderItem>.from(existingOrder.items);
    final index = currentItems.indexWhere(
      (item) =>
          item.itemId == itemId && (item.note ?? '') == (note ?? ''),
    );

    if (index != -1) {
      final existing = currentItems[index];
      currentItems[index] = existing.copyWith(
        quantity: existing.quantity + quantity,
      );
    } else {
      final orderItem = OrderItem(
        id: 'oi_${_nextItemId++}',
        itemId: itemId,
        name: menuItem.name,
        unitPrice: unitPrice,
        quantity: quantity,
        note: note?.trim().isEmpty == true ? null : note?.trim(),
      );
      currentItems.add(orderItem);
    }

    _orders[orderId] = existingOrder.copyWith(items: currentItems);
  }

  String get defaultOrderId => _defaultOrderId;
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final menuRepository = ref.watch(menuRepositoryProvider);
  return FakeOrderRepository(menuRepository);
});
