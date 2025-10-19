import 'order_item.dart';

class BillItem {
  const BillItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  final String id;
  final String name;
  final int quantity;
  final double unitPrice;

  double get amount => unitPrice * quantity;

  factory BillItem.fromOrderItem(OrderItem item) {
    return BillItem(
      id: item.id,
      name: item.name,
      quantity: item.quantity,
      unitPrice: item.unitPrice,
    );
  }
}
