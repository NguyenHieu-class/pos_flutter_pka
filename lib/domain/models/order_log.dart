import 'dart:math' as math;

import 'order.dart';

class OrderLogEntry {
  const OrderLogEntry({
    required this.id,
    required this.tableName,
    required this.status,
    required this.createdAt,
    required this.subtotal,
    required this.discountValue,
    required this.discountType,
  });

  final int id;
  final String tableName;
  final OrderStatus status;
  final DateTime createdAt;
  final double subtotal;
  final double discountValue;
  final DiscountType discountType;

  double get discountAmount {
    if (subtotal <= 0 || discountValue <= 0) {
      return 0;
    }

    final amount = switch (discountType) {
      DiscountType.amount => discountValue,
      DiscountType.percent => subtotal * (discountValue / 100),
    };

    return math.min(amount, subtotal);
  }

  double get total => math.max(subtotal - discountAmount, 0);
}

class OrderLogDetail {
  const OrderLogDetail({
    required this.order,
    required this.tableName,
  });

  final Order order;
  final String tableName;
}
