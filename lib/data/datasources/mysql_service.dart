import 'package:mysql1/mysql1.dart';

import '../../config/db_config.dart';

class MysqlService {
  MysqlService();

  MySqlConnection? _connection;

  Future<void> connect() async {
    // TODO: implement real connection logic when ready
    final settings = ConnectionSettings(
      host: DbConfig.host,
      port: DbConfig.port,
      user: DbConfig.user,
      password: DbConfig.password,
      db: DbConfig.database,
    );
    // ignore: avoid_print
    print('MysqlService.connect called with settings: '
        '${settings.host}:${settings.port}/${settings.db}');
  }

  MySqlConnection? get connection => _connection;

  Future<void> close() async {
    await _connection?.close();
    _connection = null;
  }
}
