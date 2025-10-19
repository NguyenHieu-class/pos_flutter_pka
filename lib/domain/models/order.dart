import 'dart:math' as math;

import 'order_item.dart';

enum DiscountType { amount, percent }

extension DiscountTypeLabel on DiscountType {
  String get label => switch (this) {
        DiscountType.amount => 'Số tiền',
        DiscountType.percent => 'Phần trăm',
      };
}

enum OrderStatus { open, paid, cancelled }

extension OrderStatusLabel on OrderStatus {
  String get label => switch (this) {
        OrderStatus.open => 'Open',
        OrderStatus.paid => 'Paid',
        OrderStatus.cancelled => 'Cancelled',
      };
}

class Order {
  final String id;
  final String tableId;
  final List<OrderItem> items;
  final OrderStatus status;
  final double discountValue;
  final DiscountType discountType;
  final DateTime? createdAt;

  const Order({
    required this.id,
    required this.tableId,
    required this.items,
    this.status = OrderStatus.open,
    this.discountValue = 0,
    this.discountType = DiscountType.amount,
    this.createdAt,
  });

  double get subtotal => items.fold(0, (value, element) => value + element.total);

  double get discountAmount {
    if (items.isEmpty || discountValue <= 0) {
      return 0;
    }

    final subtotal = this.subtotal;
    if (subtotal <= 0) {
      return 0;
    }

    final amount = switch (discountType) {
      DiscountType.amount => discountValue,
      DiscountType.percent => subtotal * (discountValue / 100),
    };

    return math.min(amount, subtotal);
  }

  double get total => math.max(subtotal - discountAmount, 0);

  Order copyWith({
    String? id,
    String? tableId,
    List<OrderItem>? items,
    OrderStatus? status,
    double? discountValue,
    DiscountType? discountType,
    DateTime? createdAt,
  }) {
    return Order(
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      items: items ?? this.items,
      status: status ?? this.status,
      discountValue: discountValue ?? this.discountValue,
      discountType: discountType ?? this.discountType,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
