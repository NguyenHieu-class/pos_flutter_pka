import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mysql1/mysql1.dart';

import '../../config/db_config.dart';

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

    _connection = await MySqlConnection.connect(settings);
    return _connection!;
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
}

final mysqlServiceProvider = Provider<MysqlService>((ref) {
  final service = MysqlService();
  ref.onDispose(service.close);
  return service;
});
