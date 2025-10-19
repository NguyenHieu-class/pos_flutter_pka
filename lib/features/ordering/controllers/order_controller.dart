import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/order.dart';
import '../../../domain/models/order_item.dart';

class OrderController {
  const OrderController();

  Order get activeOrder => const Order(
        id: '',
        tableId: '',
        items: <OrderItem>[],
      );
}

final orderControllerProvider = Provider<OrderController>((ref) {
  return const OrderController();
});
