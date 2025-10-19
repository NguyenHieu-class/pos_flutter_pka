import '../../domain/models/order.dart';

abstract class OrderRepository {
  const OrderRepository();

  Future<Order?> fetchOrder(String orderId);
  Future<void> saveOrder(Order order);
  Future<void> closeOrder(String orderId);
  Future<void> addItem(
    String orderId,
    String itemId,
    int quantity, {
    String? note,
  });
}
