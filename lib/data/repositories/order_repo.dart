import '../../domain/models/order.dart';

abstract class OrderRepository {
  const OrderRepository();

  Future<Order?> fetchActiveOrder(String tableId);
  Future<void> saveOrder(Order order);
  Future<void> closeOrder(String orderId);
}
