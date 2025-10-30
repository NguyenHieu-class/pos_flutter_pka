import '../utils/json_utils.dart';
import 'item.dart';
import 'modifier.dart';

/// Order model representing a restaurant order with its line items.
class Order {
  Order({
    required this.id,
    required this.tableId,
    this.tableName,
    this.tableCode,
    this.tableStatus,
    this.areaName,
    this.areaCode,
    this.status,
    this.customerName,
    this.subtotal,
    this.discountTotal,
    this.taxTotal,
    this.serviceTotal,
    this.total,
    this.createdAt,
    this.closedAt,
    this.openedByName,
    this.items = const <OrderItem>[],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'];
    return Order(
      id: json['id'] as int? ?? 0,
      tableId: json['table_id'] as int? ?? 0,
      tableName: json['table_name'] as String?
          ?? json['table_code'] as String?
          ?? json['table'] as String?,
      tableCode: json['table_code'] as String?,
      tableStatus: json['table_status'] as String?,
      areaName: json['area_name'] as String?,
      areaCode: json['area_code'] as String?,
      status: json['status'] as String? ?? json['order_status'] as String?,
      customerName: json['customer_name'] as String?,
      subtotal: parseDouble(json['subtotal']) ??
          parseDouble(json['total_before_discount']) ??
          parseDouble(json['total_amount']),
      discountTotal: parseDouble(json['discount_total']),
      taxTotal: parseDouble(json['tax_total']),
      serviceTotal: parseDouble(json['service_total']),
      total: parseDouble(json['total']) ??
          parseDouble(json['grand_total']) ??
          parseDouble(json['total_amount']),
      createdAt: json['created_at'] as String?
          ?? json['opened_at'] as String?,
      closedAt: json['closed_at'] as String?,
      openedByName: json['opened_by_name'] as String?,
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
  final String? tableCode;
  final String? tableStatus;
  final String? areaName;
  final String? areaCode;
  final String? status;
  final String? customerName;
  final double? subtotal;
  final double? discountTotal;
  final double? taxTotal;
  final double? serviceTotal;
  final double? total;
  final String? createdAt;
  final String? closedAt;
  final String? openedByName;
  final List<OrderItem> items;
}

/// Individual order line item with optional modifiers and note.
class OrderItem {
  OrderItem({
    required this.id,
    required this.itemId,
    required this.name,
    required this.quantity,
    this.unitPrice,
    this.lineTotal,
    this.kitchenStatus,
    this.note,
    this.modifiers = const <Modifier>[],
    this.preparedAt,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final modifiersJson = json['modifiers'];
    return OrderItem(
      id: json['id'] as int? ?? 0,
      itemId: json['item_id'] as int? ?? 0,
      name: json['item_name'] as String?
          ?? json['name'] as String?
          ?? '',
      quantity: parseInt(json['qty']) ?? parseInt(json['quantity']) ?? 0,
      unitPrice: parseDouble(json['unit_price']) ?? parseDouble(json['price']),
      lineTotal: parseDouble(json['line_total']),
      kitchenStatus: json['kitchen_status'] as String?
          ?? json['status'] as String?,
      note: json['note'] as String?,
      modifiers: modifiersJson is List
          ? modifiersJson
              .map((m) => Modifier.fromJson(m as Map<String, dynamic>))
              .toList()
          : const <Modifier>[],
      preparedAt: json['prepared_at'] as String?
          ?? json['updated_at'] as String?,
    );
  }

  final int id;
  final int itemId;
  final String name;
  final int quantity;
  final double? unitPrice;
  final double? lineTotal;
  final String? kitchenStatus;
  final String? note;
  final List<Modifier> modifiers;
  final String? preparedAt;
}
