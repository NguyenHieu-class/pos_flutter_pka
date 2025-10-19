import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/table.dart';
import 'table_repo.dart';

class FakeTableRepository extends TableRepository {
  FakeTableRepository() {
    for (final table in _tables.where((table) => table.status == TableStatus.occupied)) {
      _openOrders[table.id] = _nextOrderId++;
    }
  }

  final List<PosTable> _tables = List<PosTable>.generate(16, (index) {
    final id = '${index + 1}';
    final capacity = 2 + (index % 4) * 2;
    final statusIndex = index % 5;
    final status = statusIndex == 0
        ? TableStatus.reserved
        : statusIndex % 2 == 0
            ? TableStatus.occupied
            : TableStatus.available;
    return PosTable(
      id: id,
      name: 'Table ${id.padLeft(2, '0')}',
      capacity: capacity,
      status: status,
    );
  });

  final Map<String, int> _openOrders = <String, int>{};
  int _nextOrderId = 1000 + Random().nextInt(8999);

  @override
  Future<List<PosTable>> listTables({TableStatus? status, String? query}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    Iterable<PosTable> result = _tables;
    if (status != null) {
      result = result.where((table) => table.status == status);
    }

    if (query != null && query.trim().isNotEmpty) {
      final normalized = query.trim().toLowerCase();
      result = result.where(
        (table) => table.name.toLowerCase().contains(normalized),
      );
    }

    return List<PosTable>.unmodifiable(result);
  }

  @override
  Future<void> updateStatus(String tableId, TableStatus status) async {
    final index = _tables.indexWhere((table) => table.id == tableId);
    if (index == -1) {
      throw StateError('Table $tableId not found');
    }

    _tables[index] = _tables[index].copyWith(status: status);

    if (status != TableStatus.occupied) {
      _openOrders.remove(tableId);
    }
  }

  @override
  Future<int?> getOpenOrderId(String tableId) async {
    return _openOrders[tableId];
  }

  @override
  Future<int> openOrder(String tableId) async {
    final existing = _openOrders[tableId];
    if (existing != null) {
      return existing;
    }

    final index = _tables.indexWhere((table) => table.id == tableId);
    if (index == -1) {
      throw StateError('Table $tableId not found');
    }

    final newOrderId = _nextOrderId++;
    _openOrders[tableId] = newOrderId;
    _tables[index] = _tables[index].copyWith(status: TableStatus.occupied);
    return newOrderId;
  }
}

final tableRepositoryProvider = Provider<TableRepository>((ref) {
  return FakeTableRepository();
});
