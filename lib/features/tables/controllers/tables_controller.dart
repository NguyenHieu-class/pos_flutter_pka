import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/exceptions.dart';
import '../../../data/repositories/fake_table_repo.dart';
import '../../../data/repositories/table_repo.dart';
import '../../../domain/models/table.dart';

enum TableStatusFilter { all, available, occupied, reserved }

extension TableStatusFilterLabel on TableStatusFilter {
  String get label => switch (this) {
        TableStatusFilter.all => 'All',
        TableStatusFilter.available => 'Available',
        TableStatusFilter.occupied => 'Occupied',
        TableStatusFilter.reserved => 'Reserved',
      };

  TableStatus? get status => switch (this) {
        TableStatusFilter.all => null,
        TableStatusFilter.available => TableStatus.available,
        TableStatusFilter.occupied => TableStatus.occupied,
        TableStatusFilter.reserved => TableStatus.reserved,
      };
}

class TablesState {
  const TablesState({
    this.tables = const <PosTable>[],
    this.isLoading = false,
    this.filter = TableStatusFilter.all,
    this.query = '',
    this.errorMessage,
  });

  final List<PosTable> tables;
  final bool isLoading;
  final TableStatusFilter filter;
  final String query;
  final String? errorMessage;

  static const _unset = Object();

  TablesState copyWith({
    List<PosTable>? tables,
    bool? isLoading,
    TableStatusFilter? filter,
    String? query,
    Object? errorMessage = _unset,
  }) {
    return TablesState(
      tables: tables ?? this.tables,
      isLoading: isLoading ?? this.isLoading,
      filter: filter ?? this.filter,
      query: query ?? this.query,
      errorMessage:
          errorMessage == _unset ? this.errorMessage : errorMessage as String?,
    );
  }
}

class TablesController extends StateNotifier<TablesState> {
  TablesController(this._repository) : super(const TablesState()) {
    loadTables();
  }

  final TableRepository _repository;

  Future<void> loadTables() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final tables = await _repository.listTables(
        status: state.filter.status,
        query: state.query.isEmpty ? null : state.query,
      );
      state = state.copyWith(
        tables: tables,
        isLoading: false,
        errorMessage: null,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _friendlyMessage('Không thể tải danh sách bàn. Vui lòng thử lại.', error),
      );
    }
  }

  Future<void> refresh() => loadTables();

  void setFilter(TableStatusFilter filter) {
    if (state.filter == filter) {
      return;
    }
    state = state.copyWith(filter: filter);
    loadTables();
  }

  void setQuery(String query) {
    if (state.query == query) {
      return;
    }
    state = state.copyWith(query: query);
    loadTables();
  }

  Future<int?> openOrContinueOrder(PosTable table) async {
    if (table.status == TableStatus.reserved) {
      state = state.copyWith(
        errorMessage: 'Table ${table.name} is reserved.',
      );
      return null;
    }

    try {
      if (table.status == TableStatus.available) {
        final orderId = await _repository.openOrder(table.id);
        await loadTables();
        return orderId;
      }

      final existing = await _repository.getOpenOrderId(table.id);
      if (existing != null) {
        return existing;
      }

      final orderId = await _repository.openOrder(table.id);
      await loadTables();
      return orderId;
    } catch (error) {
      state = state.copyWith(
        errorMessage: _friendlyMessage('Không thể mở hoá đơn cho bàn này. Vui lòng thử lại.', error),
      );
      return null;
    }
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(errorMessage: null);
    }
  }
}

String _friendlyMessage(String fallback, Object error) {
  if (error is AppException) {
    return error.message;
  }
  return fallback;
}

final tablesControllerProvider =
    StateNotifierProvider<TablesController, TablesState>((ref) {
  final repository = ref.watch(tableRepositoryProvider);
  return TablesController(repository);
});
