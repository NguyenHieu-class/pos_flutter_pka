import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mysql1/mysql1.dart';

import '../../config/db_config.dart';
import '../../core/exceptions.dart';

class MysqlService {
  MysqlService();

  MySqlConnection? _connection;

  Future<MySqlConnection> connect() async {
    if (_connection != null && !_connection!.isClosed) {
      return _connection!;
    }

    final settings = ConnectionSettings(
      host: DbConfig.host,
      port: DbConfig.port,
      user: DbConfig.user,
      password: DbConfig.password,
      db: DbConfig.database,
    );

    try {
      _connection = await MySqlConnection.connect(settings);
      return _connection!;
    } on TimeoutException catch (error, stackTrace) {
      debugPrint('MySQL connect timeout: $error');
      debugPrint('$stackTrace');
      throw const DatabaseException(
        'Không thể kết nối tới cơ sở dữ liệu. Vui lòng kiểm tra máy chủ và mạng.',
      );
    } on SocketException catch (error, stackTrace) {
      debugPrint('MySQL socket error: $error');
      debugPrint('$stackTrace');
      throw const DatabaseException(
        'Không thể kết nối tới cơ sở dữ liệu. Vui lòng kiểm tra mạng nội bộ.',
      );
    } on MySqlException catch (error, stackTrace) {
      debugPrint('MySQL connection error: ${error.message}');
      debugPrint('$stackTrace');
      throw DatabaseException(
        'Kết nối cơ sở dữ liệu thất bại (${error.errorNumber}). Vui lòng thử lại.',
        cause: error,
      );
    } catch (error, stackTrace) {
      debugPrint('Unexpected MySQL connection error: $error');
      debugPrint('$stackTrace');
      throw const DatabaseException(
        'Không thể kết nối tới cơ sở dữ liệu. Vui lòng thử lại sau.',
      );
    }
  }

  Future<MySqlConnection> getConnection() => connect();

  Future<void> close() async {
    final connection = _connection;
    _connection = null;
    if (connection == null) {
      return;
    }

    if (!connection.isClosed) {
      try {
        await connection.close();
      } catch (error, stackTrace) {
        debugPrint('Failed to close MySQL connection: $error');
        debugPrint('$stackTrace');
      }
    }
  }

  Future<void> resetConnection() => close();
}

final mysqlServiceProvider = Provider<MysqlService>((ref) {
  final service = MysqlService();
  ref.onDispose(service.close);
  return service;
});
