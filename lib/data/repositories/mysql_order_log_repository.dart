import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mysql1/mysql1.dart';

import '../../domain/models/order.dart';
import '../../domain/models/order_item.dart';
import '../../domain/models/order_log.dart';
import '../../core/exceptions.dart';
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
    return _executeRead((connection) async {
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
    });
  }

  @override
  Future<OrderLogDetail?> fetchDetail(int orderId) async {
    return _executeRead((connection) async {
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
    });
  }

  Future<T> _executeRead<T>(Future<T> Function(MySqlConnection connection) action) async {
    const maxAttempts = 2;
    var attempt = 0;
    while (attempt < maxAttempts) {
      attempt++;
      try {
        final connection = await _mysqlService.getConnection();
        return await action(connection);
      } on TimeoutException catch (error) {
        if (attempt < maxAttempts) {
          await _mysqlService.resetConnection();
          await Future<void>.delayed(const Duration(milliseconds: 150));
          continue;
        }
        throw DatabaseException(
          'Truy vấn dữ liệu quá thời gian cho phép. Vui lòng thử lại.',
          cause: error,
        );
      } on SocketException catch (error) {
        if (attempt < maxAttempts) {
          await _mysqlService.resetConnection();
          await Future<void>.delayed(const Duration(milliseconds: 150));
          continue;
        }
        throw DatabaseException(
          'Mất kết nối tới cơ sở dữ liệu. Kiểm tra mạng nội bộ và thử lại.',
          cause: error,
        );
      } on MySqlException catch (error) {
        if (_isTransient(error) && attempt < maxAttempts) {
          await _mysqlService.resetConnection();
          await Future<void>.delayed(const Duration(milliseconds: 150));
          continue;
        }
        throw DatabaseException(
          'Không thể truy xuất dữ liệu từ cơ sở dữ liệu. Vui lòng thử lại sau.',
          cause: error,
        );
      } catch (error) {
        throw DatabaseException(
          'Đã xảy ra lỗi không mong muốn khi đọc dữ liệu.',
          cause: error,
        );
      }
    }

    throw const DatabaseException('Không thể hoàn tất truy vấn dữ liệu. Vui lòng thử lại.');
  }

  bool _isTransient(MySqlException exception) {
    const transientErrorCodes = <int>{
      2001, // CR_SOCKET_CREATE_ERROR
      2002, // CR_CONNECTION_ERROR
      2003, // CR_CONN_HOST_ERROR
      2006, // CR_SERVER_GONE_ERROR
      2013, // CR_SERVER_LOST
      2055, // CR_SERVER_LOST_EXTENDED
    };
    return transientErrorCodes.contains(exception.errorNumber ?? -1);
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
