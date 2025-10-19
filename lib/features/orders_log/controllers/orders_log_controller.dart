import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/exceptions.dart';
import '../../../data/repositories/mysql_order_log_repository.dart';
import '../../../data/repositories/order_log_repository.dart';
import '../../../domain/models/order_log.dart';

enum OrdersLogDateFilter { today, last7Days, custom }

extension OrdersLogDateFilterLabel on OrdersLogDateFilter {
  String get label => switch (this) {
        OrdersLogDateFilter.today => 'Hôm nay',
        OrdersLogDateFilter.last7Days => '7 ngày',
        OrdersLogDateFilter.custom => 'Tuỳ chọn',
      };
}

class OrdersLogState {
  const OrdersLogState({
    this.orders = const <OrderLogEntry>[],
    this.isLoading = false,
    this.filter = OrdersLogDateFilter.today,
    this.customRange,
    this.query = '',
    this.errorMessage,
  });

  final List<OrderLogEntry> orders;
  final bool isLoading;
  final OrdersLogDateFilter filter;
  final DateTimeRange? customRange;
  final String query;
  final String? errorMessage;

  OrdersLogState copyWith({
    List<OrderLogEntry>? orders,
    bool? isLoading,
    OrdersLogDateFilter? filter,
    DateTimeRange? customRange,
    String? query,
    Object? errorMessage = _unset,
  }) {
    return OrdersLogState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      filter: filter ?? this.filter,
      customRange: customRange ?? this.customRange,
      query: query ?? this.query,
      errorMessage: errorMessage == _unset ? this.errorMessage : errorMessage as String?,
    );
  }

  static const _unset = Object();
}

class OrdersLogController extends StateNotifier<OrdersLogState> {
  OrdersLogController(this._repository) : super(const OrdersLogState()) {
    loadOrders();
  }

  final OrderLogRepository _repository;

  Future<void> loadOrders() async {
    final range = _resolveRange(state.filter, state.customRange);
    if (range == null) {
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final orders = await _repository.fetchLogs(
        from: range.start,
        to: range.end,
        query: state.query.trim().isEmpty ? null : state.query.trim(),
      );
      state = state.copyWith(
        orders: orders,
        isLoading: false,
        errorMessage: null,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _resolveErrorMessage(
          'Không thể tải lịch sử đơn. Vui lòng thử lại.',
          error,
        ),
      );
    }
  }

  Future<void> refresh() => loadOrders();

  void setFilter(OrdersLogDateFilter filter) {
    if (filter == OrdersLogDateFilter.custom) {
      state = state.copyWith(filter: filter);
      return;
    }

    if (state.filter == filter) {
      return;
    }

    state = state.copyWith(filter: filter, customRange: null);
    loadOrders();
  }

  void setCustomRange(DateTimeRange range) {
    state = state.copyWith(filter: OrdersLogDateFilter.custom, customRange: range);
    loadOrders();
  }

  void setQuery(String query) {
    if (state.query == query) {
      return;
    }
    state = state.copyWith(query: query);
    loadOrders();
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(errorMessage: null);
    }
  }

  DateTimeRange? _resolveRange(
    OrdersLogDateFilter filter,
    DateTimeRange? customRange,
  ) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    switch (filter) {
      case OrdersLogDateFilter.today:
        return DateTimeRange(start: todayStart, end: todayStart.add(const Duration(days: 1)));
      case OrdersLogDateFilter.last7Days:
        final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
        return DateTimeRange(start: start, end: todayStart.add(const Duration(days: 1)));
      case OrdersLogDateFilter.custom:
        if (customRange == null) {
          return null;
        }
        final start = DateTime(customRange.start.year, customRange.start.month, customRange.start.day);
        final endExclusive =
            DateTime(customRange.end.year, customRange.end.month, customRange.end.day).add(const Duration(days: 1));
        return DateTimeRange(start: start, end: endExclusive);
    }
  }
}

final ordersLogControllerProvider =
    StateNotifierProvider.autoDispose<OrdersLogController, OrdersLogState>((ref) {
  final repository = ref.watch(orderLogRepositoryProvider);
  return OrdersLogController(repository);
});

final orderLogDetailProvider = FutureProvider.autoDispose.family<OrderLogDetail, int>((ref, orderId) async {
  final repository = ref.watch(orderLogRepositoryProvider);
  try {
    final detail = await repository.fetchDetail(orderId);
    if (detail == null) {
      throw const DatabaseException('Hoá đơn không tồn tại hoặc đã bị xoá.');
    }
    return detail;
  } catch (error) {
    if (error is DatabaseException) {
      throw error;
    }
    throw DatabaseException(
      'Không thể tải chi tiết hoá đơn. Vui lòng thử lại.',
      cause: error,
    );
  }
});

String _resolveErrorMessage(String fallback, Object error) {
  if (error is AppException) {
    return error.message;
  }
  return fallback;
}
