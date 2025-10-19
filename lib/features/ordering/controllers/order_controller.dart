import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/order_repo.dart';
import '../../../domain/models/bill_item.dart';
import '../../../domain/models/order.dart';
import '../../../core/exceptions.dart';

class OrderControllerArgs {
  const OrderControllerArgs({
    required this.orderId,
    this.tableId,
  });

  final String orderId;
  final String? tableId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is OrderControllerArgs &&
        other.orderId == orderId &&
        other.tableId == tableId;
  }

  @override
  int get hashCode => Object.hash(orderId, tableId);
}

class OrderState {
  const OrderState({
    required this.orderId,
    required this.tableId,
    this.order,
    this.billItems = const <BillItem>[],
    this.isLoading = false,
    this.errorMessage,
  });

  final String orderId;
  final String tableId;
  final Order? order;
  final List<BillItem> billItems;
  final bool isLoading;
  final String? errorMessage;

  Order get activeOrder => order ?? Order(
        id: orderId,
        tableId: tableId,
        items: const [],
      );

  OrderState copyWith({
    String? orderId,
    String? tableId,
    Order? order,
    List<BillItem>? billItems,
    bool? isLoading,
    Object? errorMessage = _unset,
  }) {
    return OrderState(
      orderId: orderId ?? this.orderId,
      tableId: tableId ?? this.tableId,
      order: order ?? this.order,
      billItems: billItems ?? this.billItems,
      isLoading: isLoading ?? this.isLoading,
      errorMessage:
          errorMessage == _unset ? this.errorMessage : errorMessage as String?,
    );
  }

  bool get canPay =>
      (order ?? activeOrder).items.isNotEmpty &&
      (order ?? activeOrder).status == OrderStatus.open;

  static const _unset = Object();
}

class OrderController extends StateNotifier<OrderState> {
  OrderController(this._repository, this._args)
      : super(OrderState(orderId: _args.orderId, tableId: _args.tableId ?? '')) {
    _initialize();
  }

  final OrderRepository _repository;
  final OrderControllerArgs _args;

  Future<void> _initialize() async {
    await setActiveOrder(_args.orderId, tableId: _args.tableId);
  }

  Future<void> setActiveOrder(String orderId, {String? tableId}) async {
    final resolvedTableId = tableId ?? state.tableId;
    state = state.copyWith(
      orderId: orderId,
      tableId: resolvedTableId,
      isLoading: true,
      errorMessage: null,
    );
    try {
      final existing = await _repository.fetchOrder(orderId);
      if (existing != null) {
        var patched = existing;
        if (resolvedTableId.isNotEmpty && existing.tableId.isEmpty) {
          patched = existing.copyWith(tableId: resolvedTableId);
          await _repository.saveOrder(patched);
        }
        state = state.copyWith(order: patched, isLoading: false, tableId: patched.tableId);
      } else {
        final fallback = Order(
          id: orderId,
          tableId: resolvedTableId,
          items: const [],
        );
        await _repository.saveOrder(fallback);
        state = state.copyWith(order: fallback, isLoading: false);
      }
      await _loadBill();
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _errorMessage('Không thể tải hoá đơn. Vui lòng thử lại.', error),
      );
    }
  }

  Future<void> refresh() async {
    await _loadOrderAndBill();
  }

  Future<bool> addItem(String itemId, int quantity, {String? note}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.addItem(state.orderId, itemId, quantity, note: note);
      await _loadOrderAndBill();
      return true;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _errorMessage('Không thể thêm món. Vui lòng thử lại.', error),
      );
      return false;
    }
  }

  Future<void> updateQuantity(String orderItemId, int quantity) async {
    if (quantity < 0) {
      return;
    }

    if (quantity == 0) {
      await removeItem(orderItemId);
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.updateQty(orderItemId, quantity);
      await _loadOrderAndBill();
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _errorMessage('Không thể cập nhật số lượng. Vui lòng thử lại.', error),
      );
    }
  }

  Future<void> removeItem(String orderItemId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.removeItem(orderItemId);
      await _loadOrderAndBill();
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _errorMessage('Không thể xoá món. Vui lòng thử lại.', error),
      );
    }
  }

  Future<void> applyDiscount(double value, DiscountType type) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updated = await _repository.applyDiscount(state.orderId, value, type);
      state = state.copyWith(order: updated, isLoading: false);
      await _loadBill();
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _errorMessage('Không thể áp dụng giảm giá. Vui lòng thử lại.', error),
      );
    }
  }

  Future<bool> pay() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.pay(state.orderId);
      await _loadOrderAndBill();
      return true;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _errorMessage('Thanh toán thất bại. Vui lòng thử lại.', error),
      );
      return false;
    }
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(errorMessage: null);
    }
  }

  Future<void> _loadOrderAndBill() async {
    try {
      final order = await _repository.fetchOrder(state.orderId);
      if (order != null) {
        state = state.copyWith(order: order, tableId: order.tableId, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
      await _loadBill();
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _errorMessage('Không thể tải hoá đơn. Vui lòng thử lại.', error),
      );
    }
  }

  Future<void> _loadBill() async {
    try {
      final bill = await _repository.getBill(state.orderId);
      state = state.copyWith(billItems: bill, isLoading: false);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _errorMessage('Không thể cập nhật hoá đơn. Vui lòng thử lại.', error),
      );
    }
  }

  String _errorMessage(String fallback, Object error) {
    if (error is AppException) {
      return error.message;
    }
    return fallback;
  }
}

final orderControllerProvider =
    StateNotifierProvider.autoDispose.family<OrderController, OrderState, OrderControllerArgs>((ref, args) {
  final repository = ref.watch(orderRepositoryProvider);
  return OrderController(repository, args);
});
