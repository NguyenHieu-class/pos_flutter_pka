import '../../domain/models/bill_item.dart';
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
  Future<List<BillItem>> getBill(String orderId);
  Future<void> updateQty(String orderItemId, int quantity);
  Future<void> removeItem(String orderItemId);
  Future<Order> applyDiscount(String orderId, double value, DiscountType type);
  Future<void> pay(String orderId);
}
