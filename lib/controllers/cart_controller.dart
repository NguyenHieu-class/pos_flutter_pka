import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../models/cart_item.dart';
import '../models/menu_item.dart';
import '../services/database_service.dart';

class CartController extends GetxController {
  final DatabaseService _databaseService = Get.find<DatabaseService>();

  final RxList<CartItem> cartItems = <CartItem>[].obs;
  final RxString tableNumber = ''.obs;
  final RxString orderType = 'dine-in'.obs;
  final RxnInt lastOrderId = RxnInt();
  final RxBool isSubmitting = false.obs;
  final RxBool isMarkingPaid = false.obs;

  double get totalAmount => cartItems.fold<double>(
        0,
        (previousValue, element) => previousValue + element.totalPrice,
      );

  void addToCart(MenuItem item) {
    final index = cartItems.indexWhere((cartItem) => cartItem.menuItem.id == item.id);
    if (index != -1) {
      cartItems[index].quantity += 1;
      cartItems.refresh();
    } else {
      cartItems.add(CartItem(menuItem: item));
    }
  }

  void incrementQuantity(CartItem item) {
    item.quantity += 1;
    cartItems.refresh();
  }

  void decrementQuantity(CartItem item) {
    if (item.quantity > 1) {
      item.quantity -= 1;
      cartItems.refresh();
    } else {
      cartItems.remove(item);
    }
  }

  void removeItem(CartItem item) {
    cartItems.remove(item);
  }

  void setNoteForItem(CartItem item, String note) {
    item.note = note;
    cartItems.refresh();
  }

  void setTableNumber(String value) {
    tableNumber.value = value.trim();
  }

  void setOrderType(String value) {
    orderType.value = value;
  }

  Future<int?> submitOrder() async {
    if (cartItems.isEmpty) {
      Get.snackbar('Giỏ hàng trống', 'Vui lòng chọn ít nhất một món.');
      return null;
    }

    if (tableNumber.value.isEmpty) {
      Get.snackbar('Thiếu số bàn', 'Vui lòng nhập số bàn trước khi gửi đơn.');
      return null;
    }

    try {
      isSubmitting.value = true;
      final orderId = await _databaseService.createOrder(
        tableNumber: tableNumber.value,
        orderType: orderType.value,
        items: cartItems.toList(),
      );
      lastOrderId.value = orderId;
      cartItems.clear();
      Get.snackbar('Thành công', 'Đã gửi đơn hàng #$orderId');
      return orderId;
    } catch (error, stackTrace) {
      debugPrint('Không thể gửi đơn: $error');
      debugPrint('$stackTrace');
      Get.snackbar('Lỗi', 'Không thể gửi đơn hàng: $error');
      return null;
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> markOrderPaid() async {
    final orderId = lastOrderId.value;
    if (orderId == null) {
      Get.snackbar('Chưa có đơn', 'Vui lòng gửi đơn trước khi thanh toán.');
      return;
    }

    try {
      isMarkingPaid.value = true;
      await _databaseService.markOrderPaid(orderId);
      Get.snackbar('Đã thanh toán', 'Đơn hàng #$orderId đã thanh toán.');
    } catch (error, stackTrace) {
      debugPrint('Không thể cập nhật thanh toán: $error');
      debugPrint('$stackTrace');
      Get.snackbar('Lỗi', 'Không thể cập nhật trạng thái thanh toán: $error');
    } finally {
      isMarkingPaid.value = false;
    }
  }

  void printTemporaryBill() {
    final buffer = StringBuffer()
      ..writeln('------------- TẠM TÍNH -------------')
      ..writeln('Bàn: ${tableNumber.value}')
      ..writeln('Loại đơn: ${orderType.value}')
      ..writeln('-----------------------------------');
    for (final item in cartItems) {
      buffer.writeln(
        '${item.menuItem.name} x${item.quantity} - ${(item.totalPrice).toStringAsFixed(0)}đ',
      );
      if (item.note.isNotEmpty) {
        buffer.writeln('  Ghi chú: ${item.note}');
      }
    }
    buffer.writeln('-----------------------------------');
    buffer.writeln('Tổng cộng: ${totalAmount.toStringAsFixed(0)}đ');
    debugPrint(buffer.toString());
  }
}
