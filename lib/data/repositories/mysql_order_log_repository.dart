import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mysql1/mysql1.dart';

import '../../domain/models/order.dart';
import '../../domain/models/order_item.dart';
import '../../domain/models/order_log.dart';
import '../datasources/mysql_service.dart';
import 'order_log_repository.dart';

class MysqlOrderLogRepository extends OrderLogRepository {
  MysqlOrderLogRepository(this._mysqlService);

  final MysqlService _mysqlService;

  @override
  Future<List<OrderLogEntry>> fetchLogs({
    required DateTime from,
    required DateTime to,
    String? query,
  }) async {
    final connection = await _mysqlService.getConnection();
    final buffer = StringBuffer(
      'SELECT o.id, t.name AS table_name, o.status, o.discount_value, o.discount_type, o.created_at, '
      'COALESCE(SUM(oi.qty * oi.price), 0) AS subtotal '
      'FROM orders o '
      'JOIN tables t ON t.id = o.table_id '
      'LEFT JOIN order_items oi ON oi.order_id = o.id '
      'WHERE o.created_at >= ? AND o.created_at < ?',
    );

    final parameters = <Object?>[from, to];

    final normalizedQuery = query?.trim();
    if (normalizedQuery != null && normalizedQuery.isNotEmpty) {
      buffer.write(' AND (CAST(o.id AS CHAR) LIKE ? OR t.name LIKE ?)');
      final keyword = '%$normalizedQuery%';
      parameters.addAll([keyword, keyword]);
    }

    buffer.write(
        ' GROUP BY o.id, t.name, o.status, o.discount_value, o.discount_type, o.created_at ORDER BY o.created_at DESC');

    final results = await connection.query(buffer.toString(), parameters);

    return results
        .map(
          (row) => OrderLogEntry(
            id: _toInt(row['id']),
            tableName: row['table_name']?.toString() ?? '',
            status: _mapStatus(row['status']?.toString()),
            createdAt: row['created_at'] as DateTime,
            subtotal: _toDouble(row['subtotal']),
            discountValue: _toDouble(row['discount_value']),
            discountType: _mapDiscountType(row['discount_type']?.toString()),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<OrderLogDetail?> fetchDetail(int orderId) async {
    final connection = await _mysqlService.getConnection();
    final orderResults = await connection.query(
      'SELECT o.id, o.table_id, t.name AS table_name, o.status, o.discount_value, o.discount_type, o.created_at '
      'FROM orders o '
      'JOIN tables t ON t.id = o.table_id '
      'WHERE o.id = ?'
      ' LIMIT 1',
      [orderId],
    );

    if (orderResults.isEmpty) {
      return null;
    }

    final orderRow = orderResults.first;

    final itemsResult = await connection.query(
      'SELECT oi.id, oi.item_id, mi.name, oi.price, oi.qty, oi.note '
      'FROM order_items oi '
      'JOIN menu_items mi ON mi.id = oi.item_id '
      'WHERE oi.order_id = ? '
      'ORDER BY oi.id',
      [orderId],
    );

    final items = itemsResult
        .map(
          (row) => OrderItem(
            id: row['id'].toString(),
            itemId: row['item_id'].toString(),
            name: row['name']?.toString() ?? '',
            unitPrice: _toDouble(row['price']),
            quantity: _toInt(row['qty']),
            note: row['note']?.toString(),
          ),
        )
        .toList(growable: false);

    final order = Order(
      id: orderRow['id'].toString(),
      tableId: orderRow['table_id'].toString(),
      items: items,
      status: _mapStatus(orderRow['status']?.toString()),
      discountValue: _toDouble(orderRow['discount_value']),
      discountType: _mapDiscountType(orderRow['discount_type']?.toString()),
      createdAt: orderRow['created_at'] as DateTime?,
    );

    return OrderLogDetail(
      order: order,
      tableName: orderRow['table_name']?.toString() ?? '',
    );
  }

  double _toDouble(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    if (value is BigInt) {
      return value.toDouble();
    }

    if (value is Decimal) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  int _toInt(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    if (value is BigInt) {
      return value.toInt();
    }

    if (value is Decimal) {
      return value.toDouble().toInt();
    }

    return int.tryParse(value.toString()) ?? 0;
  }

  OrderStatus _mapStatus(String? value) {
    return switch (value) {
      'paid' => OrderStatus.paid,
      'void' => OrderStatus.cancelled,
      _ => OrderStatus.open,
    };
  }

  DiscountType _mapDiscountType(String? value) {
    return value == 'percent' ? DiscountType.percent : DiscountType.amount;
  }
}

final orderLogRepositoryProvider = Provider<OrderLogRepository>((ref) {
  final mysqlService = ref.watch(mysqlServiceProvider);
  return MysqlOrderLogRepository(mysqlService);
});
