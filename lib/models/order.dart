import 'item.dart';
import 'modifier.dart';

/// Order model representing a restaurant order with its line items.
class Order {
  Order({
    required this.id,
    required this.tableId,
    this.tableName,
    this.status,
    this.customerName,
    this.total,
    this.createdAt,
    this.items = const <OrderItem>[],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'];
    return Order(
      id: json['id'] as int? ?? 0,
      tableId: json['table_id'] as int? ?? 0,
      tableName: json['table_name'] as String?,
      status: json['status'] as String?,
      customerName: json['customer_name'] as String?,
      total: (json['total'] as num?)?.toDouble(),
      createdAt: json['created_at'] as String?,
      items: itemsJson is List
          ? itemsJson
              .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
              .toList()
          : const <OrderItem>[],
    );
  }

  final int id;
  final int tableId;
  final String? tableName;
  final String? status;
  final String? customerName;
  final double? total;
  final String? createdAt;
  final List<OrderItem> items;
}

/// Individual order line item with optional modifiers and note.
class OrderItem {
  OrderItem({
    required this.id,
    required this.itemId,
    required this.name,
    required this.quantity,
    this.price,
    this.status,
    this.note,
    this.modifiers = const <Modifier>[],
    this.preparedAt,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final modifiersJson = json['modifiers'];
    return OrderItem(
      id: json['id'] as int? ?? 0,
      itemId: json['item_id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      quantity: json['qty'] as int? ?? json['quantity'] as int? ?? 0,
      price: (json['price'] as num?)?.toDouble(),
      status: json['status'] as String?,
      note: json['note'] as String?,
      modifiers: modifiersJson is List
          ? modifiersJson
              .map((m) => Modifier.fromJson(m as Map<String, dynamic>))
              .toList()
          : const <Modifier>[],
      preparedAt: json['prepared_at'] as String?,
    );
  }

  final int id;
  final int itemId;
  final String name;
  final int quantity;
  final double? price;
  final String? status;
  final String? note;
  final List<Modifier> modifiers;
  final String? preparedAt;
}
