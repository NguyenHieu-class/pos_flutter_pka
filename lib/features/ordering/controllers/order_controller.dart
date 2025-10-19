import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/fake_order_repo.dart';
import '../../../data/repositories/order_repo.dart';
import '../../../domain/models/order.dart';

class OrderState {
  const OrderState({
    this.orderId,
    this.order,
    this.isLoading = false,
    this.errorMessage,
  });

  final String? orderId;
  final Order? order;
  final bool isLoading;
  final String? errorMessage;

  Order get activeOrder =>
      order ?? Order(id: orderId ?? '', tableId: '', items: const []);

  OrderState copyWith({
    String? orderId,
    Order? order,
    bool? isLoading,
    Object? errorMessage = _unset,
  }) {
    return OrderState(
      orderId: orderId ?? this.orderId,
      order: order ?? this.order,
      isLoading: isLoading ?? this.isLoading,
      errorMessage:
          errorMessage == _unset ? this.errorMessage : errorMessage as String?,
    );
  }

  static const _unset = Object();
}

class OrderController extends StateNotifier<OrderState> {
  OrderController(this._repository, this._defaultOrderId)
      : super(const OrderState()) {
    _initialize();
  }

  final OrderRepository _repository;
  final String _defaultOrderId;

  Future<void> _initialize() async {
    await setActiveOrder(_defaultOrderId);
  }

  Future<void> setActiveOrder(String orderId) async {
    state = state.copyWith(orderId: orderId, isLoading: true, errorMessage: null);
    try {
      final order = await _repository.fetchOrder(orderId);
      if (order != null) {
        state = state.copyWith(order: order, isLoading: false);
      } else {
        final fallback = Order(id: orderId, tableId: '', items: const []);
        await _repository.saveOrder(fallback);
        state = state.copyWith(order: fallback, isLoading: false);
      }
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể tải order: $error',
      );
    }
  }

  Future<bool> addItem(String itemId, int quantity, {String? note}) async {
    final orderId = state.orderId ?? _defaultOrderId;
    if (state.orderId == null) {
      state = state.copyWith(orderId: orderId);
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.addItem(orderId, itemId, quantity, note: note);
      final updated = await _repository.fetchOrder(orderId);
      if (updated != null) {
        state = state.copyWith(order: updated, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
      return true;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '$error',
      );
      return false;
    }
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(errorMessage: null);
    }
  }
}

final orderControllerProvider =
    StateNotifierProvider<OrderController, OrderState>((ref) {
  final repository = ref.watch(orderRepositoryProvider);
  String defaultOrderId = 'order-1';
  if (repository is FakeOrderRepository) {
    defaultOrderId = repository.defaultOrderId;
  }
  return OrderController(repository, defaultOrderId);
});
