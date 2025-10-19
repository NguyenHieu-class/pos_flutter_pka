import 'menu_item.dart';

class OrderItem {
  final String id;
  final MenuItem item;
  final int quantity;

  const OrderItem({
    required this.id,
    required this.item,
    required this.quantity,
  });

  double get total => item.price * quantity;

  OrderItem copyWith({
    String? id,
    MenuItem? item,
    int? quantity,
  }) {
    return OrderItem(
      id: id ?? this.id,
      item: item ?? this.item,
      quantity: quantity ?? this.quantity,
    );
  }
}
