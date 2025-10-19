import 'order_item.dart';

class Order {
  final String id;
  final String tableId;
  final List<OrderItem> items;
  final bool isClosed;
  final DateTime? createdAt;

  const Order({
    required this.id,
    required this.tableId,
    required this.items,
    this.isClosed = false,
    this.createdAt,
  });

  double get total => items.fold(0, (value, element) => value + element.total);

  Order copyWith({
    String? id,
    String? tableId,
    List<OrderItem>? items,
    bool? isClosed,
    DateTime? createdAt,
  }) {
    return Order(
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      items: items ?? this.items,
      isClosed: isClosed ?? this.isClosed,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
