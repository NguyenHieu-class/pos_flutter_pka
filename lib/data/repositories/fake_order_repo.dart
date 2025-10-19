import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/bill_item.dart';
import '../../domain/models/menu_item.dart';
import '../../domain/models/order.dart';
import '../../domain/models/order_item.dart';
import '../../domain/models/table.dart';
import 'menu_repo.dart';
import 'order_repo.dart';
import 'table_repo.dart';

class FakeOrderRepository extends OrderRepository {
  FakeOrderRepository(this._menuRepository, this._tableRepository) {
    _orders[_defaultOrderId] = Order(
      id: _defaultOrderId,
      tableId: 'T1',
      items: const <OrderItem>[],
    );
  }

  final MenuRepository _menuRepository;
  final TableRepository _tableRepository;
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
    _orders[orderId] = order.copyWith(status: OrderStatus.paid);
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
      () => Order(id: orderId, tableId: '', items: const <OrderItem>[]),
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

  @override
  Future<List<BillItem>> getBill(String orderId) async {
    final order = _orders[orderId];
    if (order == null) {
      return const <BillItem>[];
    }
    return order.items.map(BillItem.fromOrderItem).toList(growable: false);
  }

  @override
  Future<void> updateQty(String orderItemId, int quantity) async {
    if (quantity < 0) {
      throw ArgumentError.value(quantity, 'quantity', 'Must be >= 0');
    }

    for (final entry in _orders.entries) {
      final order = entry.value;
      final index = order.items.indexWhere((item) => item.id == orderItemId);
      if (index == -1) {
        continue;
      }

      final currentItems = List<OrderItem>.from(order.items);
      if (quantity == 0) {
        currentItems.removeAt(index);
      } else {
        currentItems[index] = currentItems[index].copyWith(quantity: quantity);
      }
      _orders[entry.key] = order.copyWith(items: currentItems);
      return;
    }

    throw StateError('Order item $orderItemId could not be found');
  }

  @override
  Future<void> removeItem(String orderItemId) async {
    for (final entry in _orders.entries) {
      final order = entry.value;
      final currentItems = order.items
          .where((item) => item.id != orderItemId)
          .toList(growable: false);
      if (currentItems.length == order.items.length) {
        continue;
      }
      _orders[entry.key] = order.copyWith(items: currentItems);
      return;
    }

    throw StateError('Order item $orderItemId could not be found');
  }

  @override
  Future<Order> applyDiscount(
    String orderId,
    double value,
    DiscountType type,
  ) async {
    final order = _orders[orderId];
    if (order == null) {
      throw StateError('Order $orderId could not be found');
    }

    final sanitized = value.isNaN || value.isNegative ? 0.0 : value;
    final normalized = type == DiscountType.percent
        ? sanitized.clamp(0, 100)
        : sanitized;

    final updated = order.copyWith(
      discountType: type,
      discountValue: normalized,
    );
    _orders[orderId] = updated;
    return updated;
  }

  @override
  Future<void> pay(String orderId) async {
    final order = _orders[orderId];
    if (order == null) {
      throw StateError('Order $orderId could not be found');
    }

    _orders[orderId] = order.copyWith(status: OrderStatus.paid);

    if (order.tableId.isNotEmpty) {
      await _tableRepository.updateStatus(order.tableId, TableStatus.available);
    }
  }

  String get defaultOrderId => _defaultOrderId;
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final menuRepository = ref.watch(menuRepositoryProvider);
  final tableRepository = ref.watch(tableRepositoryProvider);
  return FakeOrderRepository(menuRepository, tableRepository);
});
